import AppKit
import DiffView
import FileTree
import PRModels

public final class FilesChangedViewController: NSSplitViewController {
    public let tree = FileTreeViewController()
    public let diff = DiffViewController()
    let preview = MarkdownPreviewViewController()

    var onToggleViewed: ((String, Bool) -> Void)?
    var onLoadFullDiff: ((String) -> Void)?
    var onExpand: ((String, Int?) -> Void)?
    /// Asks for the preview content of a Markdown file.
    var onPreview: ((String) -> Void)?
    /// The Markdown file in the preview; `nil` when the preview is closed.
    public private(set) var previewPath: String?
    private var previewItem: NSSplitViewItem!
    /// Markdown files in diff order.
    private var markdownPaths: [String] = []
    private var diffPaths: Set<String> = []

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
        previewItem = NSSplitViewItem(inspectorWithViewController: preview)
        previewItem.minimumThickness = 320
        previewItem.maximumThickness = 1_200
        previewItem.canCollapse = true
        previewItem.isCollapsed = true
        addSplitViewItem(sidebar)
        addSplitViewItem(content)
        addSplitViewItem(previewItem)

        tree.onSelectFile = { [weak self] path in
            self?.diff.scrollToFile(path)
            self?.diff.focus()
        }
        diff.onVisibleFileChange = { [weak self] path in
            self?.tree.reveal(path: path)
            self?.followPreview(to: path)
        }
        diff.onToggleViewed = { [weak self] path, viewed in
            self?.tree.setViewed(path: path, viewed: viewed)
            self?.onToggleViewed?(path, viewed)
        }
        diff.onLoadFullDiff = { [weak self] path in self?.onLoadFullDiff?(path) }
        diff.onExpand = { [weak self] path, hunk in self?.onExpand?(path, hunk) }
        diff.onPreview = { [weak self] path in self?.togglePreview(path) }
        preview.onClose = { [weak self] in self?.closePreview() }
        preview.onReveal = { [weak self] lines in
            guard let self, let path = previewPath else { return }
            diff.revealLines(lines, path: path)
        }
        preview.onOpenPath = { [weak self] path in self?.openLinkedFile(path) ?? false }
    }

    public override func viewWillAppear() {
        super.viewWillAppear()
        if previewPath == nil { previewItem.isCollapsed = true }
    }

    /// Returns file paths in tree display order; the diff uses the same order.
    func setTreeFiles(_ files: [ChangedFile]) -> [String] {
        loadViewIfNeeded()
        tree.setFiles(files.map(FileTreeEntry.init))
        return tree.orderedFilePaths
    }

    func setDiffFiles(_ items: [DiffFileItem]) {
        loadViewIfNeeded()
        markdownPaths = items.filter(\.file.isMarkdown).map(\.file.path)
        diffPaths = Set(items.map(\.file.path))
        diff.setFiles(items)
        if let previewPath, !markdownPaths.contains(previewPath) { closePreview() }
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

    // MARK: Markdown preview

    public var hasMarkdownFiles: Bool { !markdownPaths.isEmpty }

    /// Opens the preview of `path`, or closes the preview when it already shows `path` or `path` is not Markdown.
    public func togglePreview(_ path: String) {
        if path != previewPath, markdownPaths.contains(path) {
            openPreview(path)
        } else {
            closePreview()
        }
    }

    /// Previews the current file, or the first Markdown file when the current file is not Markdown.
    public func toggleMarkdownPreview() {
        guard previewPath == nil else { return closePreview() }
        if let current = diff.currentFilePath, markdownPaths.contains(current) { return openPreview(current) }
        guard let first = markdownPaths.first else { return }
        diff.scrollToFile(first)
        openPreview(first)
    }

    func openPreview(_ path: String) {
        guard path != previewPath else { return }
        previewPath = path
        diff.setPreviewPath(path)
        preview.showLoading(path: path)
        if previewItem.isCollapsed { previewItem.animator().isCollapsed = false }
        onPreview?(path)
    }

    func closePreview() {
        guard previewPath != nil else { return }
        previewPath = nil
        diff.setPreviewPath(nil)
        previewItem.animator().isCollapsed = true
        preview.clear()
        diff.focus()
    }

    func showPreview(_ page: MarkdownPreviewPage) {
        guard page.path == previewPath else { return }
        preview.show(page)
    }

    func showPreviewError(path: String, message: String) {
        guard path == previewPath else { return }
        preview.showError(path: path, message: message)
    }

    /// Runs JavaScript in the preview next to the gutter script, for the QA harness.
    public func evaluatePreviewScript(_ source: String) async -> Any? {
        await preview.evaluate(source)
    }

    /// While the preview is open, it shows the Markdown file at the top of the diff.
    private func followPreview(to path: String) {
        guard previewPath != nil, path != previewPath, markdownPaths.contains(path) else { return }
        openPreview(path)
    }

    private func openLinkedFile(_ path: String) -> Bool {
        guard diffPaths.contains(path) else { return false }
        diff.scrollToFile(path)
        if markdownPaths.contains(path) { openPreview(path) }
        return true
    }

    public func toggleFileTree() {
        splitViewItems.first?.animator().isCollapsed.toggle()
    }
}
