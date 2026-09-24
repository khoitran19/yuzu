import AppKit
import DiffView
import FileTree
import PRModels

public final class FilesChangedViewController: NSSplitViewController {
    public let tree = FileTreeViewController()
    public let diff = DiffViewController()

    var onToggleViewed: ((String, Bool) -> Void)?
    var onLoadFullDiff: ((String) -> Void)?
    var onExpand: ((String, Int?) -> Void)?

    public override func viewDidLoad() {
        super.viewDidLoad()
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        splitView.autosaveName = "FilesChangedSplit"

        let sidebar = NSSplitViewItem(viewController: tree)
        sidebar.minimumThickness = 200
        sidebar.maximumThickness = 560
        sidebar.canCollapse = true
        sidebar.holdingPriority = .init(260)
        let content = NSSplitViewItem(viewController: diff)
        content.minimumThickness = 480
        addSplitViewItem(sidebar)
        addSplitViewItem(content)

        tree.onSelectFile = { [weak self] path in
            self?.diff.scrollToFile(path)
            self?.diff.focus()
        }
        diff.onVisibleFileChange = { [weak self] path in self?.tree.reveal(path: path) }
        diff.onToggleViewed = { [weak self] path, viewed in
            self?.tree.setViewed(path: path, viewed: viewed)
            self?.onToggleViewed?(path, viewed)
        }
        diff.onLoadFullDiff = { [weak self] path in self?.onLoadFullDiff?(path) }
        diff.onExpand = { [weak self] path, hunk in self?.onExpand?(path, hunk) }
    }

    /// Returns file paths in tree display order; the diff uses the same order.
    func setTreeFiles(_ files: [ChangedFile]) -> [String] {
        loadViewIfNeeded()
        tree.setFiles(files.map(FileTreeEntry.init))
        return tree.orderedFilePaths
    }

    func setDiffFiles(_ items: [DiffFileItem]) {
        loadViewIfNeeded()
        diff.setFiles(items)
    }

    func updateDiffFile(_ item: DiffFileItem) {
        diff.updateFile(item)
    }

    func updateDiffFiles(_ items: [DiffFileItem]) {
        diff.updateFiles(items)
    }

    func updateHighlights(_ highlights: [String: SideHighlights]) {
        diff.updateHighlights(highlights)
    }

    func setViewed(_ viewed: Bool, paths: [String]) {
        for path in paths { tree.setViewed(path: path, viewed: viewed) }
        diff.setViewed(viewed, paths: paths)
    }

    func setAllCollapsed(_ collapsed: Bool) {
        diff.setAllCollapsed(collapsed)
    }

    public func toggleFileTree() {
        splitViewItems.first?.animator().isCollapsed.toggle()
    }
}
