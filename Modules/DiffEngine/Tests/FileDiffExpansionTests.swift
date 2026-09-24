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

    @Test func emptiedFileOffersNoTail() {
        let emptied = FileDiffBuilder.build(patch: "@@ -1,3 +0,0 @@\n-a\n-b\n-c\n")
        #expect(emptied.trailingLineCount(newFileLineCount: 0) == 0)
        #expect(emptied.expandingTail(newFileLines: []) == emptied)
        #expect(emptied.expandingGap(before: 0, newFileLines: []) == emptied)
    }

    @Test func rejectsGapsOfDifferentLengthPerSide() {
        let inconsistent = FileDiffBuilder.build(patch: "@@ -1,1 +1,1 @@\n-a\n+b\n@@ -10,1 +5,1 @@\n-c\n+d\n")
        #expect(inconsistent.expandingGap(before: 1, newFileLines: newFile) == inconsistent)
    }
}

struct ZeroCountHunkExpansionTests {
    /// Old lines 1...20 with "a", "b" inserted after old line 5 and "c" after old line 12.
    let insertions = FileDiffBuilder.build(patch: "@@ -5,0 +6,2 @@\n+a\n+b\n@@ -12,0 +15,1 @@\n+c\n")
    var insertedFile: [String] {
        var lines = (1...20).map { "line \($0)" }
        lines.insert("c", at: 12)
        lines.insert(contentsOf: ["a", "b"], at: 5)
        return lines
    }

    /// Old lines 1...20 with old lines 6, 7, and 14 deleted.
    let deletions = FileDiffBuilder.build(patch: "@@ -6,2 +5,0 @@\n-line 6\n-line 7\n@@ -14,1 +11,0 @@\n-line 14\n")
    var deletedFile: [String] {
        (1...20).filter { ![6, 7, 14].contains($0) }.map { "line \($0)" }
    }

    @Test func mergesGapBetweenInsertions() throws {
        let hunk = try #require(insertions.expandingGap(before: 1, newFileLines: insertedFile).hunks.first)
        #expect((hunk.oldStart, hunk.oldCount, hunk.newStart, hunk.newCount) == (6, 7, 6, 10))
        let context = hunk.rows.filter { $0.left?.kind == .context }
        #expect(context.compactMap(\.left?.number) == Array(6...12))
        #expect(context.compactMap(\.right?.number) == Array(8...14))
        #expect(context.compactMap(\.right?.text) == (6...12).map { "line \($0)" })
    }

    @Test func expandsFileStartBeforeInsertion() throws {
        let hunk = try #require(insertions.expandingGap(before: 0, newFileLines: insertedFile).hunks.first)
        #expect((hunk.oldStart, hunk.oldCount, hunk.newStart, hunk.newCount) == (1, 5, 1, 7))
        #expect(hunk.rows.filter { $0.left?.kind == .context }.compactMap(\.left?.number) == Array(1...5))
    }

    @Test func expandsTailAfterInsertion() throws {
        #expect(insertions.trailingLineCount(newFileLineCount: insertedFile.count) == 8)
        let hunk = try #require(insertions.expandingTail(newFileLines: insertedFile).hunks.last)
        #expect((hunk.oldStart, hunk.oldCount, hunk.newStart, hunk.newCount) == (13, 8, 15, 9))
        let context = hunk.rows.filter { $0.left?.kind == .context }
        #expect(context.compactMap(\.left?.number) == Array(13...20))
        #expect(context.compactMap(\.right?.number) == Array(16...23))
    }

    @Test func mergesGapBetweenDeletions() throws {
        let hunk = try #require(deletions.expandingGap(before: 1, newFileLines: deletedFile).hunks.first)
        #expect((hunk.oldStart, hunk.oldCount, hunk.newStart, hunk.newCount) == (6, 9, 6, 6))
        let context = hunk.rows.filter { $0.left?.kind == .context }
        #expect(context.compactMap(\.left?.number) == Array(8...13))
        #expect(context.compactMap(\.right?.number) == Array(6...11))
        #expect(context.compactMap(\.right?.text) == (8...13).map { "line \($0)" })
    }

    @Test func expandsTailAfterDeletion() throws {
        #expect(deletions.trailingLineCount(newFileLineCount: deletedFile.count) == 6)
        let hunk = try #require(deletions.expandingTail(newFileLines: deletedFile).hunks.last)
        #expect((hunk.oldStart, hunk.oldCount, hunk.newStart, hunk.newCount) == (14, 7, 12, 6))
        let context = hunk.rows.filter { $0.left?.kind == .context }
        #expect(context.compactMap(\.left?.number) == Array(15...20))
        #expect(context.compactMap(\.right?.number) == Array(12...17))
    }
}
