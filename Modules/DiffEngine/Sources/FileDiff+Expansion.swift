extension FileDiff {
    /// Shows every unchanged line between hunk `index - 1` (or the file start) and hunk `index`, merging the two hunks.
    public func expandingGap(before index: Int, newFileLines: [String]) -> FileDiff {
        guard hunks.indices.contains(index) else { return self }
        let hunk = hunks[index]
        let previous = index > 0 ? hunks[index - 1] : nil
        let gapStart = previous?.nextNewLine ?? 1
        let gapEnd = hunk.firstNewLine - 1
        let oldGapStart = previous?.nextOldLine ?? 1
        let oldGapEnd = hunk.firstOldLine - 1
        guard gapStart >= 1, gapStart <= gapEnd, gapEnd <= newFileLines.count,
              oldGapStart >= 1, oldGapEnd - oldGapStart == gapEnd - gapStart
        else { return self }
        let gap = newFileLines[(gapStart - 1)..<gapEnd].map { " \($0)" }

        var patch = ""
        for (current, candidate) in hunks.enumerated() where current != index - 1 {
            if current == index {
                let oldStart = previous?.firstOldLine ?? oldGapStart
                let newStart = previous?.firstNewLine ?? gapStart
                let oldCount = (previous?.oldCount ?? 0) + gap.count + hunk.oldCount
                let newCount = (previous?.newCount ?? 0) + gap.count + hunk.newCount
                patch += "@@ -\(oldStart),\(oldCount) +\(newStart),\(newCount) @@ \(previous?.section ?? hunk.section)\n"
                if let previous { patch += previous.bodyLines.joined(separator: "\n") + "\n" }
                patch += (gap + hunk.bodyLines).joined(separator: "\n") + "\n"
            } else {
                patch += candidate.patchText
            }
        }
        return FileDiffBuilder.build(patch: patch)
    }

    /// Shows every unchanged line after the last hunk.
    public func expandingTail(newFileLines: [String]) -> FileDiff {
        guard let last = hunks.last else { return self }
        let tailStart = last.nextNewLine
        guard tailStart >= 1, tailStart <= newFileLines.count else { return self }
        let tail = newFileLines[(tailStart - 1)...].map { " \($0)" }
        var patch = hunks.dropLast().map(\.patchText).joined()
        patch += "@@ -\(last.firstOldLine),\(last.oldCount + tail.count) +\(last.firstNewLine),\(last.newCount + tail.count) @@ \(last.section)\n"
        patch += (last.bodyLines + tail).joined(separator: "\n") + "\n"
        return FileDiffBuilder.build(patch: patch)
    }

    /// Unchanged lines after the last hunk, given the new file's line count.
    public func trailingLineCount(newFileLineCount: Int) -> Int {
        guard let last = hunks.last else { return 0 }
        return max(0, newFileLineCount - (last.nextNewLine - 1))
    }
}

extension DiffHunk {
    /// A zero-count range starts at the line before the insertion point, as in `+5,0`.
    var firstOldLine: Int { oldCount == 0 ? oldStart + 1 : oldStart }
    public var firstNewLine: Int { newCount == 0 ? newStart + 1 : newStart }
    var nextOldLine: Int { firstOldLine + oldCount }
    var nextNewLine: Int { firstNewLine + newCount }

    var patchText: String {
        "@@ -\(oldStart),\(oldCount) +\(newStart),\(newCount) @@ \(section)\n" + bodyLines.joined(separator: "\n") + "\n"
    }

    /// Unified body lines; paired change rows emit all deletions, then all additions, as in the source patch.
    var bodyLines: [String] {
        var lines: [String] = []
        var deletions: [String] = []
        var additions: [String] = []
        func flush() {
            lines += deletions + additions
            deletions.removeAll()
            additions.removeAll()
        }
        for row in rows {
            if let left = row.left, left.kind == .context {
                flush()
                lines.append(" \(left.text)")
                continue
            }
            if let left = row.left { deletions.append("-\(left.text)") }
            if let right = row.right { additions.append("+\(right.text)") }
        }
        flush()
        return lines
    }
}
