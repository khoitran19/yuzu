import AppKit
@testable import FileTree
import PRModels
import Testing

struct FileTreeViewControllerTests {
    private let files = entries(
        "apps/web/src/page.tsx",
        "apps/web/src/__tests__/page.spec.tsx",
        "apps/web/package.json",
        "packages/db/migrations/001.sql",
        "packages/db/schema.ts"
    )

    @Test func expandsEveryFolderOnFirstLoad() throws {
        let controller = makeController()
        controller.setFiles(files)
        #expect(controller.displayedTree.directories.allSatisfy { isExpanded(controller, $0.path) })
        #expect(visibleFiles(controller).count == files.count)
    }

    @Test func keepsUserExpansionWhenPathsAreUnchanged() throws {
        let controller = makeController()
        controller.setFiles(files)
        controller.outlineView.collapseItem(try directory(controller, "packages/db/migrations"))
        controller.outlineView.collapseItem(try directory(controller, "apps/web/src"))

        var updated = files
        updated[0].isViewed = true
        controller.setFiles(updated)

        #expect(!isExpanded(controller, "packages/db/migrations"))
        #expect(!isExpanded(controller, "apps/web/src"))
    }

    @Test func expandsEveryFolderWhenPathsChange() throws {
        let controller = makeController()
        controller.setFiles(files)
        controller.outlineView.collapseItem(try directory(controller, "packages/db/migrations"))

        controller.setFiles(files + entries("packages/db/seed.ts"))

        #expect(isExpanded(controller, "packages/db/migrations"))
    }

    @Test func expandingCollapsedParentRestoresSavedChildState() throws {
        let controller = makeController()
        controller.setFiles(files)
        controller.outlineView.collapseItem(try directory(controller, "apps/web"))
        controller.outlineView.expandItem(try directory(controller, "apps/web"))
        #expect(isExpanded(controller, "apps/web/src"))
        #expect(isExpanded(controller, "apps/web/src/__tests__"))
    }

    @Test func filterShowsMatchesExpandedAndClearingRestoresExpansion() throws {
        let controller = makeController()
        controller.setFiles(files)
        controller.outlineView.collapseItem(try directory(controller, "apps/web/src/__tests__"))
        controller.outlineView.collapseItem(try directory(controller, "packages/db"))

        controller.applyFilter("SPEC")
        #expect(visibleFiles(controller) == ["apps/web/src/__tests__/page.spec.tsx"])

        controller.applyFilter("")
        #expect(!isExpanded(controller, "packages/db"))
        #expect(!isExpanded(controller, "apps/web/src/__tests__"))
        #expect(isExpanded(controller, "apps/web/src"))
    }

    @Test func revealKeepsCollapsedFoldersAndSelectsClosestVisibleFolder() throws {
        let controller = makeController()
        controller.setFiles(files)
        controller.outlineView.collapseItem(try directory(controller, "packages/db/migrations"))
        var selected: [String] = []
        controller.onSelectFile = { selected.append($0) }

        controller.reveal(path: "packages/db/migrations/001.sql")

        #expect(!isExpanded(controller, "packages/db/migrations"))
        let item = controller.outlineView.item(atRow: controller.outlineView.selectedRow) as? FileTreeNode
        #expect(item?.path == "packages/db/migrations")
        #expect(selected.isEmpty)
    }

    @Test func revealSelectsVisibleFileWithoutCallingOnSelectFile() throws {
        let controller = makeController()
        controller.setFiles(files)
        var selected: [String] = []
        controller.onSelectFile = { selected.append($0) }

        controller.reveal(path: "packages/db/migrations/001.sql")

        let item = controller.outlineView.item(atRow: controller.outlineView.selectedRow) as? FileTreeNode
        #expect(item?.path == "packages/db/migrations/001.sql")
        #expect(selected.isEmpty)
    }

    @Test func returnKeyCallsOnSelectFileForSelectedFile() throws {
        let controller = makeController()
        controller.setFiles(files)
        var selected: [String] = []
        controller.onSelectFile = { selected.append($0) }
        controller.reveal(path: "packages/db/schema.ts")

        let event = try #require(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0,
            context: nil, characters: "\r", charactersIgnoringModifiers: "\r", isARepeat: false, keyCode: 36
        ))
        controller.outlineView.keyDown(with: event)

        #expect(selected == ["packages/db/schema.ts"])
    }

    @Test func setViewedUpdatesNodeWithoutChangingOrder() throws {
        let controller = makeController()
        controller.setFiles(files)
        let before = controller.orderedFilePaths
        controller.setViewed(path: "apps/web/package.json", viewed: true)
        #expect(controller.displayedTree.filesByPath["apps/web/package.json"]?.isViewed == true)
        #expect(controller.orderedFilePaths == before)
    }

    @Test func buildsAndDisplaysThreeThousandFilesQuickly() {
        let controller = makeController()
        let large = largeEntries(count: 3_000)
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            controller.setFiles(large)
            controller.view.layoutSubtreeIfNeeded()
            controller.view.displayIfNeeded()
        }
        let path = controller.orderedFilePaths[2_000]
        controller.reveal(path: path)
        let revealTime = clock.measure { controller.reveal(path: controller.orderedFilePaths[2_010]) }
        print("FileTree 3000 files: setFiles+display \(elapsed), reveal \(revealTime)")
        #expect(elapsed < .milliseconds(100))
        #expect(revealTime < .milliseconds(1))
    }

    // MARK: Helpers

    private func makeController() -> FileTreeViewController {
        let controller = FileTreeViewController()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 800),
            styleMask: [.titled], backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.contentViewController = controller
        window.setContentSize(NSSize(width: 320, height: 800))
        return controller
    }

    private func directory(_ controller: FileTreeViewController, _ path: String) throws -> FileTreeNode {
        try #require(controller.displayedTree.directories.first { $0.path == path })
    }

    private func isExpanded(_ controller: FileTreeViewController, _ path: String) -> Bool {
        guard let node = controller.displayedTree.directories.first(where: { $0.path == path }) else { return false }
        return controller.outlineView.isItemExpanded(node)
    }

    private func visibleFiles(_ controller: FileTreeViewController) -> [String] {
        (0 ..< controller.outlineView.numberOfRows).compactMap {
            guard let node = controller.outlineView.item(atRow: $0) as? FileTreeNode, !node.isDirectory else { return nil }
            return node.path
        }
    }

    private func largeEntries(count: Int) -> [FileTreeEntry] {
        (0 ..< count).map { index in
            let app = "apps/app\(index % 12)"
            let folder = ["src", "src/components", "src/__tests__", "src/lib/utils", "docs"][index % 5]
            let status: ChangedFile.Status = [.added, .modified, .removed, .renamed][index % 4]
            return FileTreeEntry(path: "\(app)/\(folder)/module\(index / 5 % 40)/file\(index).ts", status: status, isViewed: index % 3 == 0)
        }
    }
}
