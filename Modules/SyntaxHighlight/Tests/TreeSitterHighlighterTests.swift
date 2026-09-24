import DiffEngine
import Foundation
@testable import SyntaxHighlight
import Testing

struct TreeSitterHighlighterTests {
    let highlighter = TreeSitterHighlighter()

    @Test func typeScriptSpansUseUTF16OffsetsAfterEmoji() {
        let spans = highlighter.highlight(lines: [#"let e = "😀"; const x = 1; // done"#], path: "src/a.ts")[0]
        #expect(spans.contains(span(8, 4, .string)))
        #expect(spans.contains(span(14, 5, .keyword)))
        #expect(spans.contains(span(27, 7, .comment)))
    }

    @Test func blockCommentColorsEveryLine() {
        let lines = ["/* start", "   middle", "   end */", "const a = 1;"]
        let spans = highlighter.highlight(lines: lines, path: "a.ts")
        #expect(spans[0] == [span(0, 8, .comment)])
        #expect(spans[1] == [span(0, 9, .comment)])
        #expect(spans[2] == [span(0, 9, .comment)])
        #expect(spans[3].first == span(0, 5, .keyword))
    }

    @Test func innermostCaptureWins() {
        let spans = highlighter.highlight(lines: ["const s = `a${name}b`;"], path: "a.ts")[0]
        #expect(spans.contains(span(10, 2, .string)))
        #expect(!spans.contains { NSIntersectionRange($0.range, NSRange(location: 14, length: 4)).length > 0 })
    }

    @Test func tsxTagsAndAttributes() {
        let spans = highlighter.highlight(lines: [#"const view = <div className="x">hi</div>;"#], path: "View.tsx")[0]
        #expect(spans.contains(span(14, 3, .tag)))
        #expect(spans.contains(span(36, 3, .tag)))
        #expect(spans.contains(span(18, 9, .attribute)))
    }

    @Test func regexPredicatesSelectTheCapture() {
        let spans = highlighter.highlight(lines: ["const MAX_SIZE = make(new Parser());"], path: "a.ts")[0]
        #expect(spans.contains(span(6, 8, .constant)))
        #expect(spans.contains(span(17, 4, .function)))
        #expect(spans.contains(span(26, 6, .type)))
    }

    @Test(arguments: ["a.ts", "notes.txt"])
    func returnsOneArrayPerLine(path: String) {
        let lines = ["", "const a = 1;", "", "  "]
        #expect(highlighter.highlight(lines: lines, path: path).count == lines.count)
        #expect(highlighter.highlight(lines: [], path: path).isEmpty)
    }

    @Test(arguments: ["notes.txt", "Makefile", "a.TS.orig", ""])
    func unknownExtensionReturnsEmptyArrays(path: String) {
        let spans = highlighter.highlight(lines: ["const a = 1;", "// b"], path: path)
        #expect(spans == [[], []])
    }

    @Test func spansAreSortedAndInsideTheirLine() {
        let lines = typeScriptSample(lineCount: 50)
        let result = highlighter.highlight(lines: lines, path: "a.ts")
        #expect(result.reduce(0) { $0 + $1.count } > 200)
        for (line, spans) in zip(lines, result) {
            var previousEnd = 0
            for span in spans {
                #expect(span.range.length > 0, "\(line)")
                #expect(span.range.location >= previousEnd, "\(line)")
                previousEnd = NSMaxRange(span.range)
            }
            #expect(previousEnd <= line.utf16.count, "\(line)")
        }
    }

    @Test func concurrentCallsReturnIdenticalResults() async {
        let lines = typeScriptSample(lineCount: 200)
        let results = await withTaskGroup(of: [[HighlightSpan]].self) { group in
            for index in 0..<8 {
                group.addTask { [highlighter] in
                    highlighter.highlight(lines: lines, path: index.isMultiple(of: 2) ? "a.ts" : "b.mts")
                }
            }
            return await group.reduce(into: []) { $0.append($1) }
        }
        #expect(results.count == 8)
        #expect(results[0].contains { !$0.isEmpty })
        #expect(results.allSatisfy { $0 == results[0] })
    }

    @Test(arguments: [
        ("a.js", "const a = 1;", "const", TokenKind.keyword),
        ("a.jsx", "<div />;", "div", .tag),
        ("a.json", #"{"a": 12}"#, "12", .number),
        ("a.sql", "SELECT id FROM users;", "SELECT", .keyword),
        ("a.swift", "let x = \"s\"", "\"s\"", .string),
        ("a.yaml", "key: value # note", "# note", .comment),
        ("a.css", ".a { color: red; }", "color", .property),
        ("a.py", "def f(): pass", "def", .keyword),
        ("a.go", "package main", "package", .keyword),
        ("a.rs", "fn main() {}", "main", .function),
        ("a.sh", "echo hi # note", "# note", .comment),
        ("README.md", "# Title", "Title", .constant),
    ])
    func everyLanguageHighlights(path: String, line: String, token: String, kind: TokenKind) throws {
        let language = try #require(HighlightLanguage(path: path))
        _ = try HighlightConfiguration(language)
        let spans = highlighter.highlight(lines: [line], path: path)[0]
        #expect(spans.contains(span((line as NSString).range(of: token), kind)), "\(spans)")
    }

    @Test func highlightsTwoThousandTypeScriptLinesFast() {
        let lines = typeScriptSample(lineCount: 2_000)
        _ = highlighter.highlight(lines: lines, path: "warm.ts")
        var spans: [[HighlightSpan]] = []
        let fastest = (0..<5).map { _ in
            ContinuousClock().measure { spans = highlighter.highlight(lines: lines, path: "a.ts") }
        }.min() ?? .zero
        let milliseconds = Double(fastest.components.attoseconds) / 1e15 + Double(fastest.components.seconds) * 1_000
        print("Highlighted 2,000 TypeScript lines in \(milliseconds) ms (fastest of 5)")
        #expect(spans.count == 2_000)
        #expect(milliseconds < 100)
    }

    private func span(_ location: Int, _ length: Int, _ kind: TokenKind) -> HighlightSpan {
        HighlightSpan(range: NSRange(location: location, length: length), kind: kind)
    }

    private func span(_ range: NSRange, _ kind: TokenKind) -> HighlightSpan {
        HighlightSpan(range: range, kind: kind)
    }
}

struct PatternMatcherTests {
    @Test(arguments: [
        "^[A-Z]", "^[A-Z_][A-Z\\d_]+$", "^(arguments|module|console)$", "^--", "^-", "^[a-z][^.]*$",
        "^[A-Z]*x", "^foo|bar", "^(?i)foo", "^[-+]?\\d+$", "^///[^/]", "^\\d",
    ])
    func agreesWithTheRegex(pattern: String) throws {
        let matcher = try PatternMatcher(pattern)
        let regex = try NSRegularExpression(pattern: pattern)
        let words = ["Foo", "foo", "MAX_SIZE", "A", "console", "consoles", "--var", "-x", "x", "bar", "FOO", "+12", "12",
                     "///doc", "a.b", "é", "", "_X1"]
        for word in words {
            let units = Array(word.utf16)
            let result = units.withUnsafeBufferPointer { buffer in
                var text = PredicateText(units: buffer)
                return matcher.matches(NSRange(location: 0, length: units.count), in: &text)
            }
            let expected = regex.firstMatch(in: word, range: NSRange(location: 0, length: units.count)) != nil
            #expect(result == expected, "\(pattern) on \(word)")
        }
    }
}
