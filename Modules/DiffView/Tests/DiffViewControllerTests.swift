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
