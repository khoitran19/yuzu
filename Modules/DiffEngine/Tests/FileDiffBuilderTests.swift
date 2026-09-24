@testable import DiffEngine
import Foundation
import Testing

struct FileDiffBuilderTests {
    let patch = """
    @@ -94,6 +94,9 @@ async function selectCard(
         const card = find()
         return card
       }
    +  if (event.sentAt === 'unreadable') {
    +    return { outcome: 'none' }
    +  }
       const before = event.sentAt ?? receivedAt
    -  const sent = old()
    +  const sent = fresh()
       done()
    \\ No newline at end of file
    @@ -200 +203,2 @@
    -x
    +y
    +z
    """

    @Test func parsesHunkHeaders() throws {
        let diff = FileDiffBuilder.build(patch: patch)
        #expect(diff.hunks.count == 2)
        let first = try #require(diff.hunks.first)
        #expect((first.oldStart, first.oldCount, first.newStart, first.newCount) == (94, 6, 94, 9))
        #expect(first.section == "async function selectCard(")
        let second = diff.hunks[1]
        #expect((second.oldStart, second.oldCount, second.newStart, second.newCount) == (200, 1, 203, 2))
    }

    @Test func numbersLinesPerSide() throws {
        let rows = FileDiffBuilder.build(patch: patch).hunks[0].rows
        #expect(rows[3].left == nil)
        #expect(rows[3].right?.number == 97)
        #expect(rows[6].left?.number == 97)
        #expect(rows[6].right?.number == 100)
    }

    @Test func pairsDeletionsWithAdditions() throws {
        let rows = FileDiffBuilder.build(patch: patch).hunks[0].rows
        let changed = rows[7]
        #expect(changed.left?.text == "  const sent = old()")
        #expect(changed.right?.text == "  const sent = fresh()")
        #expect(rows.count == 9)
    }

    @Test func leavesBlankCellsForUnpairedLines() throws {
        let rows = FileDiffBuilder.build(patch: patch).hunks[1].rows
        #expect(rows.count == 2)
        #expect(rows[1].left == nil)
        #expect(rows[1].right?.text == "z")
    }

    @Test func mapsCellsToSideLines() throws {
        let diff = FileDiffBuilder.build(patch: patch)
        for row in diff.hunks.flatMap(\.rows) {
            if let left = row.left { #expect(diff.leftLines[left.lineIndex] == left.text) }
            if let right = row.right { #expect(diff.rightLines[right.lineIndex] == right.text) }
        }
    }

    @Test func expandsTabsToColumns() {
        #expect(FileDiffBuilder.expandTabs("\tx") == "    x")
        #expect(FileDiffBuilder.expandTabs("ab\tx") == "ab  x")
    }

    @Test func diffsFullContents() throws {
        let old = (1...20).map { "line \($0)" }.joined(separator: "\n") + "\n"
        var newLines = (1...20).map { "line \($0)" }
        newLines[1] = "changed 2"
        newLines.insert("inserted", at: 15)
        let diff = FileDiffBuilder.build(old: old, new: newLines.joined(separator: "\n") + "\n")

        #expect(diff.hunks.count == 2)
        let first = diff.hunks[0]
        #expect((first.oldStart, first.oldCount, first.newStart, first.newCount) == (1, 5, 1, 5))
        #expect(first.rows[1].left?.text == "line 2")
        #expect(first.rows[1].right?.text == "changed 2")
        let second = diff.hunks[1]
        #expect(second.rows.contains { $0.left == nil && $0.right?.text == "inserted" && $0.right?.number == 16 })
    }

    @Test func identicalContentsHaveNoHunks() {
        #expect(FileDiffBuilder.build(old: "a\nb\n", new: "a\nb\n").hunks.isEmpty)
    }

    @Test func newFileStartsAtZero() throws {
        let hunk = try #require(FileDiffBuilder.build(old: "", new: "a\nb\n").hunks.first)
        #expect((hunk.oldStart, hunk.oldCount, hunk.newStart, hunk.newCount) == (0, 0, 1, 2))
    }
}

struct WordDiffTests {
    @Test func marksChangedWords() throws {
        let ranges = try #require(WordDiff.changedRanges(old: "const sent = old()", new: "const sent = fresh()"))
        #expect(ranges.old == [NSRange(location: 13, length: 3)])
        #expect(ranges.new == [NSRange(location: 13, length: 5)])
    }

    @Test func skipsMostlyRewrittenLines() {
        #expect(WordDiff.changedRanges(old: "alpha beta", new: "gamma delta") == nil)
    }

    @Test func mergesAdjacentTokens() throws {
        let ranges = try #require(WordDiff.changedRanges(old: "x = foo", new: "x = bar baz"))
        #expect(ranges.new == [NSRange(location: 4, length: 7)])
    }

    @Test func countsUTF16Offsets() throws {
        let ranges = try #require(WordDiff.changedRanges(old: "let 👋 = one + two", new: "let 👋 = uno + two"))
        #expect(ranges.new == [NSRange(location: 9, length: 3)])
    }
}
