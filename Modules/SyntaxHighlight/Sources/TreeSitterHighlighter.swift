import DiffEngine
import Foundation

public struct TreeSitterHighlighter: SyntaxHighlighting {
    public init() {}

    public func highlight(lines: [String], path: String) -> [[HighlightSpan]] {
        guard !lines.isEmpty, let configuration = HighlightLanguage(path: path)?.configuration else {
            return Array(repeating: [], count: lines.count)
        }
        return configuration.highlight(lines: lines)
    }
}
