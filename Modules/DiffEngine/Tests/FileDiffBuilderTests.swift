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

    @Test func keepsCarriageReturnAtEndOfFile() {
        #expect(FileDiffBuilder.lines(of: "a\r\nb\r") == ["a", "b\r"])
        #expect(!FileDiffBuilder.build(old: "x\r", new: "x").hunks.isEmpty)
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

struct LineEndingTests {
    @Test func parsesCRLFPatch() throws {
        let diff = FileDiffBuilder.build(patch: "@@ -1,2 +1,2 @@\r\n same\r\n-old\r\n+new\r\n")
        let rows = try #require(diff.hunks.first).rows
        #expect(rows.count == 2)
        #expect(rows[0].left?.text == "same")
        #expect(rows[1].left?.text == "old")
        #expect(rows[1].right?.text == "new")
    }

    @Test func diffsCRLFContents() throws {
        let diff = FileDiffBuilder.build(old: "a\r\nb\r\nc\r\n", new: "a\r\nB\r\nc\r\n")
        let rows = try #require(diff.hunks.first).rows
        #expect(rows.count == 3)
        #expect(rows.map { $0.left?.text } == ["a", "b", "c"])
        #expect(rows.map { $0.right?.text } == ["a", "B", "c"])
    }

    @Test func splitsOnlyOnLineFeed() {
        #expect(FileDiffBuilder.lines(of: "a\u{2028}b\u{85}c\nd\re\r\n\n") == ["a\u{2028}b\u{85}c", "d\re", ""])
        #expect(FileDiffBuilder.lines(of: "x\ny") == ["x", "y"])
        #expect(FileDiffBuilder.lines(of: "").isEmpty)
    }

    @Test func keepsLineSeparatorInsidePatchLine() throws {
        let rows = try #require(FileDiffBuilder.build(patch: "@@ -1 +1 @@\n-s = \"a\u{2028}b\"\n+s = \"c\"\n").hunks.first).rows
        #expect(rows.count == 1)
        #expect(rows[0].left?.text == "s = \"a\u{2028}b\"")
    }

    @Test func detectsAddedFinalNewline() throws {
        let rows = try #require(FileDiffBuilder.build(old: "x\na", new: "x\na\n").hunks.first).rows
        let changed = try #require(rows.last)
        #expect((changed.left?.kind, changed.left?.text) == (.deletion, "a"))
        #expect((changed.right?.kind, changed.right?.text) == (.addition, "a"))
    }

    @Test func detectsRemovedFinalNewline() throws {
        let rows = try #require(FileDiffBuilder.build(old: "a\n", new: "a").hunks.first).rows
        #expect(rows.count == 1)
        #expect((rows[0].left?.kind, rows[0].right?.kind) == (.deletion, .addition))
    }

    @Test func ignoresMatchingMissingFinalNewline() {
        #expect(FileDiffBuilder.build(old: "a\nb", new: "a\nb").hunks.isEmpty)
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
