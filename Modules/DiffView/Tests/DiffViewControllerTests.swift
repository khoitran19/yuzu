import AppKit
import DiffEngine
@testable import DiffView
import PRModels
import Testing

@MainActor
struct DiffViewControllerTests {
    @Test func perFileUpdatesMatchAFullRebuild() throws {
        let controller = makeController(files: 6)
        controller.setViewed(true, path: "src/file1.ts")
        controller.setViewed(true, paths: ["src/file3.ts", "src/file4.ts"])
        controller.setViewed(false, path: "src/file3.ts")
        controller.updateFile(item(index: 5, lines: 40))
        controller.setViewed(true, path: "src/file0.ts")

        let rows = controller.rows
        let heights = controller.heights
        let headers = controller.headerRows
        controller.rebuildAll()
        #expect(controller.rows == rows)
        #expect(controller.heights == heights)
        #expect(controller.headerRows == headers)
    }

    @Test func viewedFilesCollapseToHeaderAndFooter() throws {
        let controller = makeController(files: 3)
        controller.setViewed(true, path: "src/file1.ts")
        let range = controller.headerRows[1]..<controller.headerRows[2]
        #expect(controller.rows[range].map(\.kind) == [.header, .footer])
    }

    @Test func tallRowsSplitIntoSlicesOfBoundedHeight() throws {
        let long = String(repeating: "word ", count: 4_000)
        let patch = "@@ -1,1 +1,1 @@\n-\(long)\n+\(long)x\n"
        let file = ChangedFile(path: "big.ts", previousPath: nil, status: .modified, additions: 1, deletions: 1, patch: patch, viewedState: .unviewed)
        let controller = makeController(items: [DiffFileItem(file: file, content: .diff(FileDiffBuilder.build(patch: patch)))])
        let lineRows = controller.rows.enumerated().filter { if case .line = $0.element.kind { true } else { false } }
        #expect(lineRows.count > 1)
        #expect(lineRows.allSatisfy { controller.heights[$0.offset] <= Metrics.sliceHeight })
        #expect(lineRows.map(\.element.slice) == Array(0..<lineRows.count))
    }

    @Test func commentBoxOpensAfterItsLineAndKeepsItsTextThroughReloadAndCollapse() throws {
        let items = (0..<3).map { item(index: $0, lines: 10) }
        let controller = makeController(items: items)
        let key = CommentComposer.newThread(CommentTarget(path: "src/file1.ts", side: .right, line: 3, startLine: 2))
        controller.openComposer(key)
        controller.setComposerText("Why?", for: key)
        #expect(kinds(controller, file: 1).contains([.line(hunk: 0, row: 2), .composer(0), .line(hunk: 0, row: 3)]))

        controller.setFiles(items)
        controller.setViewed(true, path: "src/file1.ts")
        #expect(!kinds(controller, file: 1).contains(.composer(0)))
        controller.setViewed(false, path: "src/file1.ts")
        #expect(kinds(controller, file: 1).contains(.composer(0)))
        #expect(composer(controller, file: 1)?.view.text == "Why?")

        controller.composerDidFinish(key, error: nil)
        #expect(controller.openComposers.isEmpty)
        #expect(!kinds(controller, file: 1).contains(.composer(0)))
    }

    @Test func aRefusedCommentKeepsTheBoxAndShowsTheError() throws {
        let controller = makeController(files: 2)
        let key = CommentComposer.newThread(CommentTarget(path: "src/file0.ts", side: .left, line: 11))
        controller.openComposer(key)
        let row = try #require(controller.rows.firstIndex { $0.kind == .composer(0) })
        let height = controller.heights[row]
        controller.submitComposer(key, .single)
        controller.composerDidFinish(key, error: "GitHub refused it.")
        #expect(controller.openComposers == [key])
        #expect(composer(controller, file: 0)?.busy == false)
        #expect(controller.heights[row] == height + Composer.errorHeight)
    }

    @Test func replyBoxFollowsItsThreadAndATargetOutsideTheDiffIsRefused() throws {
        let thread = ReviewThread(
            id: "T1", path: "src/file0.ts", line: 2, startLine: nil, side: .right, isResolved: false, isOutdated: false,
            comments: [ReviewComment(id: "C1", author: nil, bodyText: "Hi", createdAt: .now)]
        )
        var withThread = item(index: 0, lines: 10)
        withThread.threads = [thread]
        let controller = makeController(items: [withThread])
        controller.openComposer(.reply(thread: "T1"))
        #expect(kinds(controller, file: 0).contains([.line(hunk: 0, row: 1), .thread(0), .composer(0)]))

        controller.openComposer(.newThread(CommentTarget(path: "src/file0.ts", side: .right, line: 400)))
        controller.openComposer(.edit(comment: "missing"))
        #expect(controller.openComposers == [.reply(thread: "T1")])
    }

    @Test func anEmptyBoxClosesAtOnceAndABusyBoxIgnoresCancel() throws {
        let controller = makeController(files: 1)
        let key = CommentComposer.newThread(CommentTarget(path: "src/file0.ts", side: .right, line: 2))
        controller.openComposer(key)
        composer(controller, file: 0)?.view.onCancel?()
        #expect(controller.openComposers.isEmpty)

        controller.openComposer(key)
        controller.setComposerText("Posting", for: key)
        controller.submitComposer(key, .single)
        composer(controller, file: 0)?.view.onCancel?()
        #expect(controller.openComposers == [key])
    }

    @Test func aReplyBoxClosesWhenItsThreadIsGone() throws {
        let thread = ReviewThread(
            id: "T1", path: "src/file0.ts", line: 2, startLine: nil, side: .right, isResolved: false, isOutdated: false,
            comments: [ReviewComment(id: "C1", author: nil, bodyText: "Hi", createdAt: .now)]
        )
        var withThread = item(index: 0, lines: 10)
        withThread.threads = [thread]
        let controller = makeController(items: [withThread])
        controller.openComposer(.reply(thread: "T1"))
        controller.updateFile(item(index: 0, lines: 10))
        #expect(controller.openComposers.isEmpty)
        #expect(!kinds(controller, file: 0).contains(.composer(0)))
    }

    @Test func onlyLinesInsideGitHubsHunksTakeComments() throws {
        let patch = "@@ -1,3 +1,3 @@\n a\n-b\n+B\n c\n@@ -20,2 +20,3 @@\n x\n+y\n z\n"
        let file = ChangedFile(path: "h.ts", previousPath: nil, status: .modified, additions: 2, deletions: 1, patch: patch, viewedState: .unviewed)
        let state = FileState(item: DiffFileItem(file: file, content: .diff(FileDiffBuilder.build(patch: patch))), collapsed: false)
        #expect(state.canComment(side: .right, from: 1, to: 3))
        #expect(state.canComment(side: .right, from: 20, to: 22))
        #expect(!state.canComment(side: .right, from: 3, to: 20))
        #expect(state.canComment(side: .left, from: 20, to: 21))
        #expect(!state.canComment(side: .left, from: 22, to: 22))
    }

    private func kinds(_ controller: DiffViewController, file: Int) -> [RowRef.Kind] {
        let end = file + 1 < controller.headerRows.count ? controller.headerRows[file + 1] : controller.rows.count
        return controller.rows[controller.headerRows[file]..<end].map(\.kind)
    }

    private func composer(_ controller: DiffViewController, file: Int) -> Composer? {
        controller.fileStates[file].composers.first
    }

    private func makeController(files: Int) -> DiffViewController {
        makeController(items: (0..<files).map { item(index: $0, lines: 10 + $0) })
    }

    private func makeController(items: [DiffFileItem]) -> DiffViewController {
        let controller = DiffViewController()
        controller.view.frame = NSRect(x: 0, y: 0, width: 1_200, height: 800)
        controller.view.layoutSubtreeIfNeeded()
        controller.setFiles(items)
        return controller
    }

    private func item(index: Int, lines: Int) -> DiffFileItem {
        let body = (1...lines).map { " context \($0)" } + ["-old", "+new"]
        let patch = "@@ -1,\(lines + 1) +1,\(lines + 1) @@\n" + body.joined(separator: "\n") + "\n"
        let file = ChangedFile(
            path: "src/file\(index).ts", previousPath: nil, status: .modified, additions: 1, deletions: 1,
            patch: patch, viewedState: .unviewed
        )
        return DiffFileItem(file: file, content: .diff(FileDiffBuilder.build(patch: patch)))
    }
}
