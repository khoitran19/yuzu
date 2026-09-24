/// Writes a GitHub-style patch: unified hunks with no file headers and no trailing newline.
enum PatchWriter {
    struct Line: Hashable {
        let text: Substring
        let hasNewline: Bool
    }

    struct Hunk: Equatable {
        let oldStart: Int
        let oldCount: Int
        let newStart: Int
        let newCount: Int
    }

    struct Result {
        let patch: String
        let additions: Int
        let deletions: Int
        let hunks: [Hunk]
    }

    private enum Operation {
        case context(old: Int, new: Int)
        case deletion(old: Int, new: Int)
        case addition(old: Int, new: Int)

        var isChange: Bool {
            if case .context = self { return false }
            return true
        }

        /// Lines consumed on each side before this operation.
        var cursor: (old: Int, new: Int) {
            switch self {
            case let .context(old, new), let .deletion(old, new), let .addition(old, new): (old, new)
            }
        }
    }

    static func lines(of text: String?) -> [Line] {
        guard let text, !text.isEmpty else { return [] }
        var parts = text.split(separator: "\n", omittingEmptySubsequences: false)
        let endsWithNewline = parts.last == ""
        if endsWithNewline { parts.removeLast() }
        return parts.enumerated().map { index, part in
            Line(text: part, hasNewline: endsWithNewline || index < parts.count - 1)
        }
    }

    static func make(old: String?, new: String?, context: Int = 3) -> Result {
        let oldLines = lines(of: old)
        let newLines = lines(of: new)
        let operations = operations(old: oldLines, new: newLines)
        let changes = operations.indices.filter { operations[$0].isChange }
        guard let first = changes.first else { return Result(patch: "", additions: 0, deletions: 0, hunks: []) }

        var groups: [ClosedRange<Int>] = []
        var start = first
        var end = first
        for index in changes.dropFirst() {
            if index - end - 1 > context * 2 {
                groups.append(start...end)
                start = index
            }
            end = index
        }
        groups.append(start...end)

        var output: [String] = []
        var hunks: [Hunk] = []
        var additions = 0
        var deletions = 0
        for group in groups {
            let slice = operations[max(0, group.lowerBound - context)...min(operations.count - 1, group.upperBound + context)]
            let cursor = slice.first!.cursor
            var body: [String] = []
            var oldCount = 0
            var newCount = 0
            func emit(_ marker: Character, _ line: Line) {
                body.append("\(marker)\(line.text)")
                if !line.hasNewline { body.append("\\ No newline at end of file") }
            }
            for operation in slice {
                switch operation {
                case let .context(oldIndex, _):
                    emit(" ", oldLines[oldIndex])
                    oldCount += 1
                    newCount += 1
                case let .deletion(oldIndex, _):
                    emit("-", oldLines[oldIndex])
                    oldCount += 1
                case let .addition(_, newIndex):
                    emit("+", newLines[newIndex])
                    newCount += 1
                }
            }
            let hunk = Hunk(
                oldStart: oldCount == 0 ? cursor.old : cursor.old + 1, oldCount: oldCount,
                newStart: newCount == 0 ? cursor.new : cursor.new + 1, newCount: newCount
            )
            hunks.append(hunk)
            additions += slice.count { if case .addition = $0 { true } else { false } }
            deletions += slice.count { if case .deletion = $0 { true } else { false } }
            let section = section(before: cursor.old, in: oldLines)
            output.append("@@ -\(range(hunk.oldStart, hunk.oldCount)) +\(range(hunk.newStart, hunk.newCount)) @@"
                + (section.isEmpty ? "" : " \(section)"))
            output += body
        }
        return Result(patch: output.joined(separator: "\n"), additions: additions, deletions: deletions, hunks: hunks)
    }

    private static func range(_ start: Int, _ count: Int) -> String {
        count == 1 ? "\(start)" : "\(start),\(count)"
    }

    /// Git's default function-name rule: the closest earlier line that starts with a letter, `_`, or `$`.
    private static func section(before index: Int, in lines: [Line]) -> String {
        var index = index - 1
        while index >= 0 {
            if let first = lines[index].text.first, first.isLetter || first == "_" || first == "$" {
                return String(lines[index].text.prefix(80)).trimmingCharacters(in: .whitespaces)
            }
            index -= 1
        }
        return ""
    }

    private static func operations(old: [Line], new: [Line]) -> [Operation] {
        var removed = Set<Int>()
        var inserted = Set<Int>()
        for change in new.difference(from: old) {
            switch change {
            case let .remove(offset, _, _): removed.insert(offset)
            case let .insert(offset, _, _): inserted.insert(offset)
            }
        }
        var result: [Operation] = []
        result.reserveCapacity(max(old.count, new.count))
        var oldIndex = 0
        var newIndex = 0
        while oldIndex < old.count || newIndex < new.count {
            if oldIndex < old.count, removed.contains(oldIndex) {
                result.append(.deletion(old: oldIndex, new: newIndex))
                oldIndex += 1
            } else if newIndex < new.count, inserted.contains(newIndex) {
                result.append(.addition(old: oldIndex, new: newIndex))
                newIndex += 1
            } else {
                result.append(.context(old: oldIndex, new: newIndex))
                oldIndex += 1
                newIndex += 1
            }
        }
        return result
    }
}
