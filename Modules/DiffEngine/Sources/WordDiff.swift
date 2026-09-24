import Foundation

public enum WordDiff {
    static let maxLineLength = 1_000
    /// Above this share of changed characters, GitHub-style output marks nothing inside the line.
    static let maxChangedShare = 0.7

    public static func changedRanges(old: String, new: String) -> (old: [NSRange], new: [NSRange])? {
        guard old != new,
              old.utf16.count <= maxLineLength, new.utf16.count <= maxLineLength
        else { return nil }
        let oldTokens = tokens(old)
        let newTokens = tokens(new)
        let difference = newTokens.map(\.text).difference(from: oldTokens.map(\.text))

        var oldRanges: [NSRange] = []
        var newRanges: [NSRange] = []
        for change in difference {
            switch change {
            case let .remove(offset, _, _): append(oldTokens[offset].range, to: &oldRanges)
            case let .insert(offset, _, _): append(newTokens[offset].range, to: &newRanges)
            }
        }
        let changed = oldRanges.reduce(0) { $0 + $1.length } + newRanges.reduce(0) { $0 + $1.length }
        let total = old.utf16.count + new.utf16.count
        guard total > 0, Double(changed) / Double(total) <= maxChangedShare else { return nil }
        return (oldRanges, newRanges)
    }

    private struct Token {
        let text: Substring
        let range: NSRange
    }

    private static func tokens(_ line: String) -> [Token] {
        var result: [Token] = []
        var index = line.startIndex
        var offset = 0
        while index < line.endIndex {
            let kind = TokenClass(line[index])
            var end = line.index(after: index)
            if kind != .symbol {
                while end < line.endIndex, TokenClass(line[end]) == kind { end = line.index(after: end) }
            }
            let text = line[index..<end]
            let length = text.utf16.count
            result.append(Token(text: text, range: NSRange(location: offset, length: length)))
            offset += length
            index = end
        }
        return result
    }

    /// Adjacent ranges merge so a changed run highlights as one block.
    private static func append(_ range: NSRange, to ranges: inout [NSRange]) {
        if let last = ranges.last, NSMaxRange(last) == range.location {
            ranges[ranges.count - 1].length += range.length
        } else {
            ranges.append(range)
        }
    }

    private enum TokenClass {
        case word, space, symbol

        init(_ character: Character) {
            if character.isLetter || character.isNumber || character == "_" {
                self = .word
            } else if character.isWhitespace {
                self = .space
            } else {
                self = .symbol
            }
        }
    }
}
