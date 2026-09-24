@testable import DiffEngine
import Testing

struct FileDiffExpansionTests {
    let newFile = (1...30).map { "line \($0)" }
    var oldFile: [String] {
        var lines = newFile
        lines[4] = "old 5"
        lines[19] = "old 20"
        return lines
    }

    var diff: FileDiff {
        FileDiffBuilder.build(old: oldFile.joined(separator: "\n") + "\n", new: newFile.joined(separator: "\n") + "\n")
    }

    @Test func mergesHunksAcrossTheGap() throws {
        #expect(diff.hunks.count == 2)
        let expanded = diff.expandingGap(before: 1, newFileLines: newFile)
        #expect(expanded.hunks.count == 1)
        let hunk = try #require(expanded.hunks.first)
        #expect((hunk.oldStart, hunk.oldCount, hunk.newStart, hunk.newCount) == (2, 22, 2, 22))
        let numbers = hunk.rows.compactMap(\.right?.number)
        #expect(numbers == Array(2...23))
    }

    @Test func keepsOldNumbersAlignedInTheGap() throws {
        let hunk = try #require(diff.expandingGap(before: 1, newFileLines: newFile).hunks.first)
        for row in hunk.rows where row.left?.kind == .context {
            #expect(row.left?.number == row.right?.number)
            #expect(row.left?.text == row.right?.text)
        }
    }

    @Test func expandsFromFileStart() throws {
        let expanded = diff.expandingGap(before: 0, newFileLines: newFile)
        let hunk = try #require(expanded.hunks.first)
        #expect(hunk.newStart == 1)
        #expect(hunk.oldStart == 1)
        #expect(hunk.rows.first?.right?.text == "line 1")
        #expect(expanded.hunks.count == 2)
    }

    @Test func expandsTail() throws {
        let expanded = diff.expandingTail(newFileLines: newFile)
        let last = try #require(expanded.hunks.last)
        #expect(last.rows.last?.right?.number == 30)
        #expect(last.newStart + last.newCount - 1 == 30)
        #expect(expanded.trailingLineCount(newFileLineCount: 30) == 0)
        #expect(diff.trailingLineCount(newFileLineCount: 30) == 7)
    }

    @Test func preservesChangePairs() throws {
        let hunk = try #require(diff.expandingGap(before: 1, newFileLines: newFile).hunks.first)
        let changed = hunk.rows.filter { $0.left?.kind == .deletion }
        #expect(changed.map { $0.left?.text } == ["old 5", "old 20"])
        #expect(changed.map { $0.right?.text } == ["line 5", "line 20"])
    }
}
