import Foundation

public enum TokenKind: UInt8, Sendable, CaseIterable {
    case keyword, string, number, comment, function, type, variable, property, constant, tag, attribute, `operator`, punctuation
}

public struct HighlightSpan: Sendable, Equatable {
    /// UTF-16 range inside one line.
    public let range: NSRange
    public let kind: TokenKind

    public init(range: NSRange, kind: TokenKind) {
        self.range = range
        self.kind = kind
    }
}

public protocol SyntaxHighlighting: Sendable {
    /// Returns spans for each input line; the result has `lines.count` elements.
    func highlight(lines: [String], path: String) -> [[HighlightSpan]]
}
