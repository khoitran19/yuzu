import DiffEngine
import DiffView
import Foundation
import PRModels

nonisolated enum DiffItemFactory {
    static func items(files: [ChangedFile], threads: [ReviewThread], order: [String]) -> [DiffFileItem] {
        let threadsByPath = placeableThreads(threads)
        let rank = Dictionary(order.enumerated().map { ($1, $0) }, uniquingKeysWith: { first, _ in first })
        return files
            .sorted { (rank[$0.path] ?? .max, $0.path) < (rank[$1.path] ?? .max, $1.path) }
            .map { file in
                DiffFileItem(file: file, content: content(for: file), threads: threadsByPath[file.path] ?? [])
            }
    }

    /// Threads GitHub can place on the current diff, by path.
    static func placeableThreads(_ threads: [ReviewThread]) -> [String: [ReviewThread]] {
        Dictionary(grouping: threads.filter { $0.line != nil && !$0.isOutdated }, by: \.path)
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
