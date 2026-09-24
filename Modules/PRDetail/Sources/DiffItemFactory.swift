import DiffEngine
import DiffView
import Foundation
import PRModels

enum DiffItemFactory {
    static func items(for snapshot: PullRequestSnapshot, order: [String]) -> [DiffFileItem] {
        let threadsByPath = Dictionary(grouping: snapshot.threads.filter { $0.line != nil && !$0.isOutdated }, by: \.path)
        let rank = Dictionary(order.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        return snapshot.files
            .sorted { (rank[$0.path] ?? .max, $0.path) < (rank[$1.path] ?? .max, $1.path) }
            .map { file in
                DiffFileItem(file: file, content: content(for: file), threads: threadsByPath[file.path] ?? [])
            }
    }

    static func content(for file: ChangedFile) -> DiffFileItem.Content {
        if let patch = file.patch, !patch.isEmpty { return .diff(FileDiffBuilder.build(patch: patch)) }
        if file.additions == 0, file.deletions == 0 {
            return file.status == .renamed || file.status == .copied ? .unchanged : .binary
        }
        return .tooLarge
    }

    static func highlights(for item: DiffFileItem, using highlighter: any SyntaxHighlighting) -> SideHighlights? {
        guard case let .diff(diff) = item.content else { return nil }
        let leftPath = item.file.previousPath ?? item.file.path
        return SideHighlights(
            left: highlighter.highlight(lines: diff.leftLines, path: leftPath),
            right: highlighter.highlight(lines: diff.rightLines, path: item.file.path)
        )
    }
}
