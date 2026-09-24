import AppKit
import CoreText
import DiffEngine
import PRModels

struct CellLayout {
    let lines: [CTLine]
    let ranges: [NSRange]
}

struct CommentLayout {
    let header: CTLine
    let body: CTFrame
    let bodyHeight: CGFloat
}

struct ThreadLayout {
    static let outerPadding: CGFloat = 8
    static let innerPadding: CGFloat = 12
    static let headerHeight: CGFloat = 20
    static let collapsedHeight: CGFloat = 36

    let comments: [CommentLayout]
    let summary: CTLine
    let boxHeight: CGFloat
    let collapsed: Bool

    var rowHeight: CGFloat { boxHeight + Self.outerPadding * 2 }
}

/// Caches Core Text layouts per cell and width. Only visible rows create layouts.
final class TextLayoutCache {
    private(set) var theme: DiffTheme = .dark
    private var cells: [CellKey: CellLayout] = [:]
    private var lineCounts: [CellKey: Int] = [:]
    private var threads: [ThreadKey: ThreadLayout] = [:]
    private static let maxCachedCells = 6_000
    private static let foregroundKey = NSAttributedString.Key(kCTForegroundColorAttributeName as String)
    private let relativeFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()

    private struct CellKey: Hashable {
        let file: Int
        let side: DiffSide
        let line: Int
        let width: Int
    }

    private struct ThreadKey: Hashable {
        let file: Int
        let thread: Int
        let width: Int
        let collapsed: Bool
    }

    func setTheme(_ theme: DiffTheme) {
        guard theme.isDark != self.theme.isDark else { return }
        self.theme = theme
        cells.removeAll()
        threads.removeAll()
    }

    func invalidate(file: Int) {
        cells = cells.filter { $0.key.file != file }
        lineCounts = lineCounts.filter { $0.key.file != file }
        threads = threads.filter { $0.key.file != file }
    }

    func invalidateAll() {
        cells.removeAll()
        lineCounts.removeAll()
        threads.removeAll()
    }

    // MARK: Code cells

    func lineCount(_ cell: DiffCell, side: DiffSide, file: Int, width: CGFloat) -> Int {
        let length = cell.text.utf16.count
        let columns = Int(width / Metrics.charWidth)
        if length * 2 <= columns { return 1 }
        if length <= columns, cell.text.utf8.count == length { return 1 }
        let key = CellKey(file: file, side: side, line: cell.lineIndex, width: Int(width))
        if let count = lineCounts[key] { return count }
        let attributed = NSAttributedString(string: cell.text, attributes: [.font: Metrics.codeFont])
        let count = max(1, Self.lineRanges(attributed, width: width).count)
        lineCounts[key] = count
        return count
    }

    func layout(_ cell: DiffCell, side: DiffSide, file: Int, spans: [HighlightSpan]?, width: CGFloat) -> CellLayout {
        let key = CellKey(file: file, side: side, line: cell.lineIndex, width: Int(width))
        if let layout = cells[key] { return layout }
        if cells.count > Self.maxCachedCells { cells.removeAll(keepingCapacity: true) }

        let text = NSMutableAttributedString(
            string: cell.text,
            attributes: [.font: Metrics.codeFont, Self.foregroundKey: theme.text]
        )
        let length = text.length
        for span in spans ?? [] where NSMaxRange(span.range) <= length {
            if let color = theme.tokens[span.kind] { text.addAttribute(Self.foregroundKey, value: color, range: span.range) }
        }
        let ranges = length == 0 ? [NSRange(location: 0, length: 0)] : Self.lineRanges(text, width: width)
        let lines = ranges.map { CTLineCreateWithAttributedString(text.attributedSubstring(from: $0)) }
        let layout = CellLayout(lines: lines, ranges: ranges)
        cells[key] = layout
        return layout
    }

    private static func lineRanges(_ text: NSAttributedString, width: CGFloat) -> [NSRange] {
        let typesetter = CTTypesetterCreateWithAttributedString(text)
        var ranges: [NSRange] = []
        var start = 0
        while start < text.length {
            let count = max(1, CTTypesetterSuggestLineBreak(typesetter, start, Double(width)))
            ranges.append(NSRange(location: start, length: count))
            start += count
        }
        return ranges
    }

    // MARK: Review threads

    func threadLayout(_ thread: ReviewThread, file: Int, index: Int, width: CGFloat, collapsed: Bool) -> ThreadLayout {
        let key = ThreadKey(file: file, thread: index, width: Int(width), collapsed: collapsed)
        if let layout = threads[key] { return layout }

        let textWidth = max(80, width - ThreadLayout.innerPadding * 2)
        let authors = Array(Set(thread.comments.compactMap(\.author?.login))).sorted()
        let summaryText = "Resolved · \(thread.comments.count) comment\(thread.comments.count == 1 ? "" : "s")"
            + (authors.isEmpty ? "" : " by \(authors.joined(separator: ", "))")
        let summary = CTLineCreateWithAttributedString(NSAttributedString(
            string: summaryText,
            attributes: [.font: Metrics.uiBoldFont, Self.foregroundKey: theme.mutedText]
        ))

        var comments: [CommentLayout] = []
        var boxHeight = ThreadLayout.collapsedHeight
        if !collapsed {
            boxHeight = 0
            for comment in thread.comments {
                let header = NSMutableAttributedString(
                    string: comment.author?.login ?? "ghost",
                    attributes: [.font: Metrics.uiBoldFont, Self.foregroundKey: theme.text]
                )
                header.append(NSAttributedString(
                    string: "  \(relativeFormatter.localizedString(for: comment.createdAt, relativeTo: .now))",
                    attributes: [.font: Metrics.uiFont, Self.foregroundKey: theme.mutedText]
                ))
                let body = NSAttributedString(
                    string: comment.bodyText.trimmingCharacters(in: .whitespacesAndNewlines),
                    attributes: [.font: Metrics.bodyFont, Self.foregroundKey: theme.text]
                )
                let framesetter = CTFramesetterCreateWithAttributedString(body)
                let size = CTFramesetterSuggestFrameSizeWithConstraints(
                    framesetter, CFRange(), nil, CGSize(width: textWidth, height: .greatestFiniteMagnitude), nil
                )
                let bodyHeight = ceil(size.height)
                let frame = CTFramesetterCreateFrame(
                    framesetter, CFRange(),
                    CGPath(rect: CGRect(x: 0, y: 0, width: textWidth, height: bodyHeight + 1), transform: nil), nil
                )
                comments.append(CommentLayout(header: CTLineCreateWithAttributedString(header), body: frame, bodyHeight: bodyHeight))
                boxHeight += ThreadLayout.innerPadding * 2 + ThreadLayout.headerHeight + 4 + bodyHeight
            }
        }
        let layout = ThreadLayout(comments: comments, summary: summary, boxHeight: max(boxHeight, ThreadLayout.collapsedHeight), collapsed: collapsed)
        threads[key] = layout
        return layout
    }
}
