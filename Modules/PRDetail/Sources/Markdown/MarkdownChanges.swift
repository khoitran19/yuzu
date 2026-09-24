import DiffEngine
import Foundation

/// New-side lines that the pull request changed; the preview marks the blocks that contain them.
nonisolated struct MarkdownChanges: Sendable, Equatable {
    var added = IndexSet()
    /// New-side lines that come directly after removed lines.
    var removedBefore = IndexSet()

    init(added: IndexSet = [], removedBefore: IndexSet = []) {
        self.added = added
        self.removedBefore = removedBefore
    }

    init(diff: FileDiff) {
        for hunk in diff.hunks {
            var next = hunk.newStart
            for row in hunk.rows {
                if let right = row.right {
                    if right.kind == .addition { added.insert(right.number) }
                    next = right.number + 1
                } else if row.left?.kind == .deletion {
                    removedBefore.insert(next)
                }
            }
        }
    }
}
