import DiffEngine
import Foundation
import Markdown
import PRModels

/// Renders a Markdown file like GitHub. Each block has `data-start` and `data-end` source lines;
/// `data-add` marks blocks with added lines and `data-del` marks blocks after removed lines.
nonisolated enum MarkdownHTML {
    struct Context: Sendable, Equatable {
        let blobRoot: URL
        let rawRoot: URL
        /// The file's directory, percent-encoded, with a trailing slash; empty at the root.
        let directory: String

        init(owner: String, repo: String, oid: String, path: String) {
            let root = "\(owner)/\(repo)/"
            blobRoot = URL(string: "https://github.com/\(root)blob/\(oid)/")!
            rawRoot = URL(string: "https://raw.githubusercontent.com/\(root)\(oid)/")!
            let folder = (path as NSString).deletingLastPathComponent
            directory = folder.isEmpty ? "" : (folder.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? folder) + "/"
        }

        /// The web view's base URL, so relative images in raw HTML load.
        var baseURL: URL { URL(string: directory, relativeTo: rawRoot)!.absoluteURL }
        var linkBase: URL { URL(string: directory, relativeTo: blobRoot)!.absoluteURL }

        /// The repository path of a link to a file at this commit, or `nil` for other links.
        func repositoryPath(of url: URL) -> String? {
            let text = url.absoluteString
            for root in [blobRoot.absoluteString, rawRoot.absoluteString] where text.hasPrefix(root) {
                let rest = text.dropFirst(root.count).split(separator: "#", maxSplits: 1).first.map(String.init) ?? ""
                let path = rest.split(separator: "?", maxSplits: 1).first.map(String.init) ?? ""
                return path.isEmpty ? nil : path.removingPercentEncoding ?? path
            }
            return nil
        }
    }

    struct Rendered: Sendable, Equatable {
        let body: String
        let changedBlocks: Int
    }

    static func render(
        source: String, changes: MarkdownChanges?, context: Context, highlighter: (any SyntaxHighlighting)?
    ) -> Rendered {
        let (frontMatter, body, offset) = splitFrontMatter(source)
        var renderer = Renderer(changes: changes, context: context, highlighter: highlighter, lineOffset: offset)
        if let frontMatter { renderer.frontMatter(frontMatter, lines: 1...offset) }
        let document = Document(parsing: body, options: [.disableSmartOpts])
        for child in document.children { renderer.block(child) }
        renderer.finish()
        let html = renderer.html.isEmpty ? "<p class=\"empty\">This file is empty.</p>" : renderer.html
        return Rendered(body: html, changedBlocks: renderer.changedBlocks)
    }

    /// Only the nonce stylesheet applies, so styles in the file cannot hide changes or markers.
    static func document(_ rendered: Rendered) -> String {
        let nonce = UUID().uuidString
        return """
        <!doctype html>
        <html><head><meta charset="utf-8">
        <meta http-equiv="Content-Security-Policy" content="default-src 'none'; img-src https: data:; media-src https:; style-src 'nonce-\(nonce)'">
        <style nonce="\(nonce)">\(SummaryStyle.css)\(MarkdownStyle.css)</style></head>
        <body><article class="markdown-body">\(rendered.body)</article></body></html>
        """
    }

    /// GitHub renders YAML front matter as a table; `offset` is the number of lines it takes.
    static func splitFrontMatter(_ source: String) -> (frontMatter: [String]?, body: String, offset: Int) {
        let lines = source.split(separator: "\n", omittingEmptySubsequences: false)
        func isFence(_ line: Substring, _ fences: [String]) -> Bool {
            fences.contains(line.trimmingCharacters(in: .whitespacesAndNewlines))
        }
        guard let first = lines.first, isFence(first, ["---"]),
              let close = lines.indices.dropFirst().first(where: { isFence(lines[$0], ["---", "..."]) })
        else { return (nil, source, 0) }
        return (lines[1..<close].map(String.init), lines[(close + 1)...].joined(separator: "\n"), close + 1)
    }

    /// GitHub heading anchors: lowercase, punctuation removed, spaces as hyphens.
    static func slug(_ text: String) -> String {
        let kept = text.lowercased().unicodeScalars.filter { scalar in
            CharacterSet.alphanumerics.contains(scalar) || scalar == " " || scalar == "-" || scalar == "_"
        }
        return String(String.UnicodeScalarView(kept)).replacingOccurrences(of: " ", with: "-")
    }

    static let languageExtensions = [
        "typescript": "ts", "javascript": "js", "python": "py", "rust": "rs", "golang": "go", "shell": "sh", "zsh": "sh",
        "jsonc": "json", "json5": "json", "markdown": "md",
    ]
}

private nonisolated struct Renderer {
    let changes: MarkdownChanges?
    let context: MarkdownHTML.Context
    let highlighter: (any SyntaxHighlighting)?
    let lineOffset: Int
    private let removed: [Int]
    private var removedIndex = 0
    private var slugs: [String: Int] = [:]
    var html = ""
    var changedBlocks = 0

    init(changes: MarkdownChanges?, context: MarkdownHTML.Context, highlighter: (any SyntaxHighlighting)?, lineOffset: Int) {
        self.changes = changes
        self.context = context
        self.highlighter = highlighter
        self.lineOffset = lineOffset
        removed = changes.map { Array($0.removedBefore) } ?? []
    }

    // MARK: Blocks

    mutating func block(_ markup: Markup) {
        switch markup {
        case let paragraph as Paragraph:
            html += "<p\(attributes(paragraph))>"
            inlines(paragraph.children)
            html += "</p>\n"
        case let heading as Heading:
            let id = uniqueSlug(MarkdownHTML.slug(plainText(heading)))
            html += "<h\(heading.level) id=\"\(escape(id))\"\(attributes(heading))>"
            html += "<a class=\"anchor\" href=\"#\(escape(id))\" aria-hidden=\"true\">#</a>"
            inlines(heading.children)
            html += "</h\(heading.level)>\n"
        case let quote as BlockQuote:
            blockQuote(quote)
        case let list as UnorderedList:
            let tasks = list.listItems.contains { $0.checkbox != nil }
            html += "<ul class=\"\(isLoose(list) ? "" : "tight")\(tasks ? " contains-task-list" : "")\">\n"
            for item in list.listItems { listItem(item) }
            html += "</ul>\n"
        case let list as OrderedList:
            let start = list.startIndex == 1 ? "" : " start=\"\(list.startIndex)\""
            html += "<ol\(start) class=\"\(isLoose(list) ? "" : "tight")\">\n"
            for item in list.listItems { listItem(item) }
            html += "</ol>\n"
        case let code as CodeBlock:
            let language = code.language?.split(separator: " ").first.map { $0.lowercased() }
            let className = language.map { " class=\"language-\(escape($0))\"" } ?? ""
            var text = code.code
            if text.hasSuffix("\n") { text.removeLast() }
            html += "<pre\(attributes(code))><code\(className)>\(highlighted(text, language: language))</code></pre>\n"
        case let raw as HTMLBlock:
            html += "<div class=\"html-marker\"\(attributes(raw))></div>"
            html += raw.rawHTML
        case let rule as ThematicBreak:
            html += "<hr\(attributes(rule))>\n"
        case let table as Table:
            self.table(table)
        default:
            for child in markup.children { block(child) }
        }
    }

    private mutating func listItem(_ item: ListItem) {
        if let checkbox = item.checkbox {
            html += "<li class=\"task-list-item\"><input type=\"checkbox\" disabled\(checkbox == .checked ? " checked" : "")> "
        } else {
            html += "<li>"
        }
        for child in item.children { block(child) }
        html += "</li>\n"
    }

    private mutating func blockQuote(_ quote: BlockQuote) {
        guard let (kind, markerCount) = alert(quote), let first = quote.child(at: 0) as? Paragraph else {
            html += "<blockquote>\n"
            for child in quote.children { block(child) }
            html += "</blockquote>\n"
            return
        }
        html += "<div class=\"markdown-alert markdown-alert-\(kind)\"><p class=\"markdown-alert-title\">\(kind.capitalized)</p>\n"
        let rest = Array(first.children.dropFirst(markerCount))
        if !rest.isEmpty {
            html += "<p\(attributes(first))>"
            inlines(rest)
            html += "</p>\n"
        }
        for child in quote.children.dropFirst() { block(child) }
        html += "</div>\n"
    }

    /// `> [!NOTE]` on the first line. Returns the kind and the number of inline nodes the marker takes.
    private func alert(_ quote: BlockQuote) -> (String, Int)? {
        guard let first = quote.child(at: 0) as? Paragraph else { return nil }
        var text = ""
        var count = 0
        for child in first.children {
            count += 1
            if child is SoftBreak || child is LineBreak { break }
            guard let part = child as? Text else { return nil }
            text += part.string
        }
        let marker = text.trimmingCharacters(in: .whitespaces).uppercased()
        guard marker.hasPrefix("[!"), marker.hasSuffix("]") else { return nil }
        let kind = marker.dropFirst(2).dropLast().lowercased()
        return ["note", "tip", "important", "warning", "caution"].contains(kind) ? (kind, count) : nil
    }

    private mutating func table(_ table: Table) {
        let alignments = table.columnAlignments
        html += "<table>\n<thead>\n"
        tableRow(table.head, cells: Array(table.head.cells), tag: "th", alignments: alignments)
        html += "</thead>\n"
        let rows = Array(table.body.rows)
        if !rows.isEmpty {
            html += "<tbody>\n"
            for row in rows { tableRow(row, cells: Array(row.cells), tag: "td", alignments: alignments) }
            html += "</tbody>\n"
        }
        html += "</table>\n"
    }

    private mutating func tableRow(_ row: Markup, cells: [Table.Cell], tag: String, alignments: [Table.ColumnAlignment?]) {
        html += "<tr\(attributes(row))>"
        for (column, cell) in cells.enumerated() where cell.colspan > 0 && cell.rowspan > 0 {
            var open = "<\(tag)"
            switch alignments.indices.contains(column) ? alignments[column] : nil {
            case .left: open += " align=\"left\""
            case .center: open += " align=\"center\""
            case .right: open += " align=\"right\""
            case nil: break
            }
            if cell.colspan > 1 { open += " colspan=\"\(cell.colspan)\"" }
            if cell.rowspan > 1 { open += " rowspan=\"\(cell.rowspan)\"" }
            html += open + ">"
            inlines(cell.children)
            html += "</\(tag)>"
        }
        html += "</tr>\n"
    }

    mutating func frontMatter(_ lines: [String], lines range: ClosedRange<Int>) {
        let pairs = lines.compactMap { line -> (String, String)? in
            guard let first = line.first, !first.isWhitespace, first != "#", let colon = line.firstIndex(of: ":") else { return nil }
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            return (String(line[..<colon]), value.trimmingCharacters(in: CharacterSet(charactersIn: "\"'")))
        }
        let attributes = attributes(lines: range)
        guard !pairs.isEmpty, pairs.count == lines.filter({ !$0.trimmingCharacters(in: .whitespaces).isEmpty }).count else {
            html += "<pre\(attributes)><code>\(highlighted(lines.joined(separator: "\n"), language: "yaml"))</code></pre>\n"
            return
        }
        html += "<table class=\"front-matter\"\(attributes)><thead><tr>"
        html += pairs.map { "<th>\(escape($0.0))</th>" }.joined()
        html += "</tr></thead><tbody><tr>"
        html += pairs.map { "<td>\(escape($0.1))</td>" }.joined()
        html += "</tr></tbody></table>\n"
    }

    /// Removed lines after the last block get a marker at the end of the page.
    mutating func finish() {
        guard removedIndex < removed.count, let last = removed.last else { return }
        html += "<div class=\"end-marker\"\(attributes(lines: last...last))></div>\n"
    }

    /// A list is loose when a blank line separates its items or the blocks in an item.
    private func isLoose(_ list: Markup) -> Bool {
        func gap(_ nodes: [Markup]) -> Bool {
            zip(nodes, nodes.dropFirst()).contains { previous, next in
                guard let end = previous.range?.upperBound.line, let start = next.range?.lowerBound.line else { return false }
                return start > end + 1
            }
        }
        let items = Array(list.children)
        return gap(items) || items.contains { gap(Array($0.children)) }
    }

    // MARK: Change markers

    private mutating func attributes(_ markup: Markup) -> String {
        guard let range = markup.range else { return "" }
        return attributes(lines: (range.lowerBound.line + lineOffset)...max(range.lowerBound.line, range.upperBound.line) + lineOffset)
    }

    private mutating func attributes(lines: ClosedRange<Int>) -> String {
        var result = " data-start=\"\(lines.lowerBound)\" data-end=\"\(lines.upperBound)\""
        guard let changes else { return result }
        var removedHere = false
        while removedIndex < removed.count, removed[removedIndex] <= lines.upperBound {
            removedIndex += 1
            removedHere = true
        }
        let added = changes.added.intersects(integersIn: lines)
        if added { result += " data-add" }
        if removedHere { result += " data-del" }
        if added || removedHere { changedBlocks += 1 }
        return result
    }

    // MARK: Inlines

    private mutating func inlines(_ children: some Sequence<Markup>) {
        for child in children { inline(child) }
    }

    private mutating func inline(_ markup: Markup) {
        switch markup {
        case let text as Text: html += escape(text.string)
        case is SoftBreak: html += "\n"
        case is LineBreak: html += "<br>\n"
        case let code as InlineCode: html += "<code>\(escape(code.code))</code>"
        case let emphasis as Emphasis: wrap("em", emphasis)
        case let strong as Strong: wrap("strong", strong)
        case let strikethrough as Strikethrough: wrap("del", strikethrough)
        case let link as Link:
            let title = link.title.map { " title=\"\(escape($0))\"" } ?? ""
            html += "<a href=\"\(escape(resolve(link.destination, root: context.blobRoot, base: context.linkBase)))\"\(title)>"
            inlines(link.children)
            html += "</a>"
        case let image as Image:
            let title = image.title.map { " title=\"\(escape($0))\"" } ?? ""
            let source = escape(resolve(image.source, root: context.rawRoot, base: context.baseURL))
            html += "<img src=\"\(source)\" alt=\"\(escape(plainText(image)))\"\(title) loading=\"lazy\">"
        case let raw as InlineHTML: html += raw.rawHTML
        case let symbol as SymbolLink: html += "<code>\(escape(symbol.destination ?? ""))</code>"
        default: inlines(markup.children)
        }
    }

    private mutating func wrap(_ tag: String, _ markup: Markup) {
        html += "<\(tag)>"
        inlines(markup.children)
        html += "</\(tag)>"
    }

    /// Relative links resolve against the file's directory; a leading slash means the repository root.
    private func resolve(_ destination: String?, root: URL, base: URL) -> String {
        guard let destination, !destination.isEmpty else { return "" }
        if destination.hasPrefix("#") { return destination }
        if let url = URL(string: destination), url.scheme != nil { return destination }
        if destination.hasPrefix("/") { return URL(string: String(destination.dropFirst()), relativeTo: root)?.absoluteString ?? destination }
        return URL(string: destination, relativeTo: base)?.absoluteString ?? destination
    }

    private func plainText(_ markup: Markup) -> String {
        switch markup {
        case let text as Text: text.string
        case let code as InlineCode: code.code
        case is SoftBreak, is LineBreak: " "
        default: markup.children.map(plainText).joined()
        }
    }

    private mutating func uniqueSlug(_ base: String) -> String {
        let count = slugs[base, default: 0]
        slugs[base] = count + 1
        return count == 0 ? base : "\(base)-\(count)"
    }

    // MARK: Code

    private func highlighted(_ code: String, language: String?) -> String {
        guard let highlighter, let language else { return escape(code) }
        let lines = code.components(separatedBy: "\n")
        let spans = highlighter.highlight(lines: lines, path: "code.\(MarkdownHTML.languageExtensions[language] ?? language)")
        guard spans.count == lines.count else { return escape(code) }
        return zip(lines, spans).map(highlightedLine).joined(separator: "\n")
    }

    private func highlightedLine(_ line: String, spans: [HighlightSpan]) -> String {
        let text = line as NSString
        var result = ""
        var cursor = 0
        for span in spans.sorted(by: { $0.range.location < $1.range.location }) {
            let start = max(span.range.location, cursor)
            let end = min(NSMaxRange(span.range), text.length)
            guard start < end else { continue }
            if start > cursor { result += escape(text.substring(with: NSRange(location: cursor, length: start - cursor))) }
            result += "<span class=\"tk-\(span.kind)\">\(escape(text.substring(with: NSRange(location: start, length: end - start))))</span>"
            cursor = end
        }
        if cursor < text.length { result += escape(text.substring(from: cursor)) }
        return result
    }

    private func escape(_ text: String) -> String {
        SummaryHTML.escape(text)
    }
}
