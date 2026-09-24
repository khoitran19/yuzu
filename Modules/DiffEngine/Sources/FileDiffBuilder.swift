import Foundation

public enum FileDiffBuilder {
    public static let tabWidth = 4

    /// Builds split rows from a GitHub `patch` (unified hunks without file headers).
    public static func build(patch: String) -> FileDiff {
        var hunks: [DiffHunk] = []
        var leftLines: [String] = []
        var rightLines: [String] = []
        var header: HunkHeader?
        var pending = PendingBlock()
        var rows: [DiffRow] = []
        var oldNumber = 0
        var newNumber = 0

        func finishHunk() {
            rows += pending.flush()
            if let header {
                hunks.append(DiffHunk(
                    oldStart: header.oldStart, oldCount: header.oldCount,
                    newStart: header.newStart, newCount: header.newCount,
                    section: header.section, rows: rows
                ))
            }
            rows = []
        }

        for rawLine in lines(of: patch) {
            if rawLine.hasPrefix("@@") {
                finishHunk()
                header = HunkHeader(rawLine)
                oldNumber = header?.oldStart ?? 0
                newNumber = header?.newStart ?? 0
                continue
            }
            guard header != nil, let marker = rawLine.unicodeScalars.first else { continue }
            let text = expandTabs(Substring(rawLine.unicodeScalars.dropFirst()))
            switch marker {
            case "-":
                pending.deletions.append(DiffCell(
                    number: oldNumber, kind: .deletion, text: text, lineIndex: leftLines.count, changedRanges: []
                ))
                leftLines.append(text)
                oldNumber += 1
            case "+":
                pending.additions.append(DiffCell(
                    number: newNumber, kind: .addition, text: text, lineIndex: rightLines.count, changedRanges: []
                ))
                rightLines.append(text)
                newNumber += 1
            case " ":
                rows += pending.flush()
                rows.append(DiffRow(
                    left: DiffCell(number: oldNumber, kind: .context, text: text, lineIndex: leftLines.count, changedRanges: []),
                    right: DiffCell(number: newNumber, kind: .context, text: text, lineIndex: rightLines.count, changedRanges: [])
                ))
                leftLines.append(text)
                rightLines.append(text)
                oldNumber += 1
                newNumber += 1
            default:
                continue // "\ No newline at end of file"
            }
        }
        finishHunk()
        return FileDiff(hunks: hunks, leftLines: leftLines, rightLines: rightLines)
    }

    /// Diffs two full file versions, for files where GitHub omits the patch.
    public static func build(old: String, new: String, context: Int = 3) -> FileDiff {
        build(patch: UnifiedPatch.make(
            old: lines(of: old), new: lines(of: new),
            oldLacksFinalNewline: lacksFinalNewline(old), newLacksFinalNewline: lacksFinalNewline(new),
            context: context
        ))
    }

    /// Splits on LF only and drops a CR that precedes an LF. A trailing LF does not start another line.
    public static func lines(of text: String) -> [String] {
        guard !text.isEmpty else { return [] }
        let carriageReturn = UInt8(ascii: "\r")
        let segments = text.utf8.split(separator: UInt8(ascii: "\n"), omittingEmptySubsequences: false)
        var lines = segments.enumerated().map { index, line in
            let endsBeforeLF = index < segments.count - 1
            return String(decoding: endsBeforeLF && line.last == carriageReturn ? line.dropLast() : line, as: UTF8.self)
        }
        if text.utf8.last == UInt8(ascii: "\n") { lines.removeLast() }
        return lines
    }

    static func expandTabs<S: StringProtocol>(_ text: S) -> String {
        guard text.contains("\t") else { return String(text) }
        var output = ""
        var column = 0
        for character in text {
            if character == "\t" {
                let spaces = tabWidth - column % tabWidth
                output += String(repeating: " ", count: spaces)
                column += spaces
            } else {
                output.append(character)
                column += 1
            }
        }
        return output
    }

    private static func lacksFinalNewline(_ text: String) -> Bool {
        !text.isEmpty && text.utf8.last != UInt8(ascii: "\n")
    }
}

private struct HunkHeader {
    let oldStart: Int
    let oldCount: Int
    let newStart: Int
    let newCount: Int
    let section: String

    init?(_ line: String) {
        let parts = line.split(separator: "@@", maxSplits: 2, omittingEmptySubsequences: false)
        guard parts.count >= 2 else { return nil }
        let ranges = parts[1].split(separator: " ")
        guard ranges.count == 2,
              let old = Self.range(ranges[0], sign: "-"),
              let new = Self.range(ranges[1], sign: "+")
        else { return nil }
        (oldStart, oldCount) = old
        (newStart, newCount) = new
        section = parts.count > 2 ? parts[2].trimmingCharacters(in: .whitespaces) : ""
    }

    private static func range(_ text: Substring, sign: Character) -> (Int, Int)? {
        guard text.first == sign else { return nil }
        let numbers = text.dropFirst().split(separator: ",")
        guard let start = numbers.first.flatMap({ Int($0) }) else { return nil }
        let count = numbers.count > 1 ? Int(numbers[1]) ?? 1 : 1
        return (start, count)
    }
}

/// Deletions followed by additions; rows pair them in order, as GitHub's split view does.
private struct PendingBlock {
    var deletions: [DiffCell] = []
    var additions: [DiffCell] = []

    mutating func flush() -> [DiffRow] {
        defer {
            deletions = []
            additions = []
        }
        return (0..<max(deletions.count, additions.count)).map { index in
            var left = index < deletions.count ? deletions[index] : nil
            var right = index < additions.count ? additions[index] : nil
            if let old = left, let new = right, let ranges = WordDiff.changedRanges(old: old.text, new: new.text) {
                left?.changedRanges = ranges.old
                right?.changedRanges = ranges.new
            }
            return DiffRow(left: left, right: right)
        }
    }
}
