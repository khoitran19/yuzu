import AppKit
import ReviewRules

public final class FileTreeViewController: NSViewController {
    public var onSelectFile: ((String) -> Void)?
    public var orderedFilePaths: [String] { fullTree.orderedFilePaths }

    let searchField = NSSearchField()
    let outlineView = FileTreeOutlineView()
    private let scrollView = NSScrollView()

    private var entries: [FileTreeEntry] = []
    private var entryIndexByPath: [String: Int] = [:]
    private var fullTree = FileTree.empty
    private(set) var displayedTree = FileTree.empty
    private var expansion: [String: Bool] = [:]
    private var filterQuery = ""
    private var selectedPath: String?
    private var isApplyingExpansion = false

    var isFiltering: Bool { !filterQuery.isEmpty }

    public init() {
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not available") }

    override public func loadView() {
        let container = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 600))

        searchField.placeholderString = "Filter files…"
        searchField.sendsSearchStringImmediately = true
        searchField.sendsWholeSearchString = false
        searchField.delegate = self
        searchField.target = self
        searchField.action = #selector(filterChanged)
        searchField.setAccessibilityIdentifier("fileTree.filter")
        searchField.translatesAutoresizingMaskIntoConstraints = false

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("name"))
        column.resizingMask = .autoresizingMask
        outlineView.addTableColumn(column)
        outlineView.outlineTableColumn = column
        outlineView.headerView = nil
        outlineView.style = .sourceList
        outlineView.rowSizeStyle = .custom
        outlineView.rowHeight = 26
        outlineView.indentationPerLevel = 14
        outlineView.autoresizesOutlineColumn = false
        outlineView.columnAutoresizingStyle = .firstColumnOnlyAutoresizingStyle
        outlineView.allowsMultipleSelection = false
        outlineView.allowsEmptySelection = true
        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.target = self
        outlineView.action = #selector(rowClicked)
        outlineView.onActivate = { [weak self] in self?.activateSelectedRow() }
        outlineView.setAccessibilityIdentifier("fileTree.outline")

        scrollView.documentView = outlineView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(searchField)
        container.addSubview(scrollView)
        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: container.topAnchor, constant: 8),
            searchField.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 8),
            searchField.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            scrollView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 6),
            scrollView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
        view = container
    }

    // MARK: Public API

    /// Resets folders to the matcher defaults when the set of paths changes. Keeps the user's state otherwise.
    public func setFiles(_ entries: [FileTreeEntry], matcher: ReviewRuleMatcher) {
        loadViewIfNeeded()
        let samePaths = entries.count == self.entries.count
            && entries.allSatisfy { entryIndexByPath[$0.path] != nil }
        self.entries = entries
        entryIndexByPath = Dictionary(entries.enumerated().map { ($1.path, $0) }, uniquingKeysWith: { first, _ in first })
        fullTree = FileTreeBuilder.build(entries)
        if !samePaths {
            expansion = Dictionary(uniqueKeysWithValues: fullTree.directories.map {
                ($0.path, !matcher.isCollapsedInTree(directory: $0.path))
            })
        }
        showCurrentTree()
    }

    public func setViewed(path: String, viewed: Bool) {
        guard let index = entryIndexByPath[path], entries[index].isViewed != viewed else { return }
        entries[index].isViewed = viewed
        if let node = fullTree.filesByPath[path] { node.isViewed = viewed }
        guard let node = displayedTree.filesByPath[path] else { return }
        node.isViewed = viewed
        let row = outlineView.row(forItem: node)
        guard row >= 0 else { return }
        (outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as? FileTreeCellView)?.configure(node)
    }

    /// Selects and scrolls to the file. Does not call `onSelectFile` and does not change the first responder.
    public func reveal(path: String) {
        guard let node = displayedTree.filesByPath[path] else { return }
        selectedPath = path
        var row = outlineView.row(forItem: node)
        if row < 0 {
            var ancestors: [FileTreeNode] = []
            var parent = node.parent
            while let directory = parent {
                ancestors.append(directory)
                parent = directory.parent
            }
            for directory in ancestors.reversed() where !outlineView.isItemExpanded(directory) {
                outlineView.expandItem(directory)
            }
            row = outlineView.row(forItem: node)
            guard row >= 0 else { return }
        }
        if outlineView.selectedRow != row {
            outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        }
        outlineView.scrollRowToVisible(row)
    }

    public func expandAll() {
        applyToAll(expanded: true) { $0.expandItem(nil, expandChildren: true) }
    }

    public func collapseAll() {
        applyToAll(expanded: false) { $0.collapseItem(nil, collapseChildren: true) }
    }

    public func focusFilter() {
        view.window?.makeFirstResponder(searchField)
    }

    // MARK: Display

    func applyFilter(_ query: String) {
        let query = query.trimmingCharacters(in: .whitespaces)
        guard query != filterQuery else { return }
        filterQuery = query
        showCurrentTree()
    }

    private func showCurrentTree() {
        displayedTree = isFiltering ? FileTreeBuilder.build(FileTreeBuilder.filter(entries, query: filterQuery)) : fullTree
        isApplyingExpansion = true
        defer { isApplyingExpansion = false }
        outlineView.reloadData()
        if isFiltering {
            outlineView.expandItem(nil, expandChildren: true)
        } else {
            applySavedExpansion()
        }
        restoreSelection()
    }

    private func applySavedExpansion() {
        outlineView.beginUpdates()
        expandSaved(displayedTree.roots)
        outlineView.endUpdates()
    }

    private func expandSaved(_ nodes: [FileTreeNode]) {
        for node in nodes where node.isDirectory && expansion[node.path] == true {
            outlineView.expandItem(node)
            expandSaved(node.children)
        }
    }

    private func restoreSelection() {
        guard let selectedPath, let node = displayedTree.filesByPath[selectedPath] else {
            outlineView.deselectAll(nil)
            return
        }
        let row = outlineView.row(forItem: node)
        if row >= 0 {
            outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        } else {
            outlineView.deselectAll(nil)
        }
    }

    private func applyToAll(expanded: Bool, _ change: (NSOutlineView) -> Void) {
        isApplyingExpansion = true
        change(outlineView)
        isApplyingExpansion = false
        guard !isFiltering else { return }
        for directory in fullTree.directories { expansion[directory.path] = expanded }
    }

    // MARK: Actions

    @objc private func filterChanged() {
        applyFilter(searchField.stringValue)
    }

    @objc private func rowClicked() {
        let row = outlineView.clickedRow
        guard row >= 0, let node = outlineView.item(atRow: row) as? FileTreeNode else { return }
        activate(node, recursively: NSEvent.modifierFlags.contains(.option))
    }

    private func activateSelectedRow() {
        guard let node = outlineView.item(atRow: outlineView.selectedRow) as? FileTreeNode else { return }
        activate(node, recursively: false)
    }

    private func activate(_ node: FileTreeNode, recursively: Bool) {
        if node.isDirectory {
            if outlineView.isItemExpanded(node) {
                outlineView.animator().collapseItem(node, collapseChildren: recursively)
            } else {
                outlineView.animator().expandItem(node, expandChildren: recursively)
            }
        } else {
            selectedPath = node.path
            onSelectFile?(node.path)
        }
    }

    private func firstFileRow() -> Int? {
        (0 ..< outlineView.numberOfRows).first { (outlineView.item(atRow: $0) as? FileTreeNode)?.isDirectory == false }
    }
}

extension FileTreeViewController: NSOutlineViewDataSource, NSOutlineViewDelegate {
    public func outlineView(_: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        (item as? FileTreeNode)?.children.count ?? displayedTree.roots.count
    }

    public func outlineView(_: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        (item as? FileTreeNode)?.children[index] ?? displayedTree.roots[index]
    }

    public func outlineView(_: NSOutlineView, isItemExpandable item: Any) -> Bool {
        (item as? FileTreeNode)?.isDirectory ?? false
    }

    public func outlineView(_ outlineView: NSOutlineView, viewFor _: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? FileTreeNode else { return nil }
        let cell = outlineView.makeView(withIdentifier: FileTreeCellView.reuseIdentifier, owner: nil) as? FileTreeCellView
            ?? FileTreeCellView()
        cell.configure(node)
        return cell
    }

    public func outlineView(_: NSOutlineView, typeSelectStringFor _: NSTableColumn?, item: Any) -> String? {
        (item as? FileTreeNode)?.name
    }

    public func outlineViewSelectionDidChange(_: Notification) {
        guard !isApplyingExpansion, let node = outlineView.item(atRow: outlineView.selectedRow) as? FileTreeNode,
              !node.isDirectory
        else { return }
        selectedPath = node.path
    }

    public func outlineViewItemDidExpand(_ notification: Notification) {
        guard !isApplyingExpansion, !isFiltering, let node = notification.userInfo?["NSObject"] as? FileTreeNode else { return }
        expansion[node.path] = true
        isApplyingExpansion = true
        defer { isApplyingExpansion = false }
        for child in node.children where child.isDirectory && expansion[child.path] == true && !outlineView.isItemExpanded(child) {
            expandSaved([child])
        }
    }

    public func outlineViewItemDidCollapse(_ notification: Notification) {
        guard !isApplyingExpansion, !isFiltering, let node = notification.userInfo?["NSObject"] as? FileTreeNode else { return }
        expansion[node.path] = false
    }
}

extension FileTreeViewController: NSSearchFieldDelegate {
    public func controlTextDidChange(_: Notification) {
        applyFilter(searchField.stringValue)
    }

    public func control(_: NSControl, textView _: NSTextView, doCommandBy selector: Selector) -> Bool {
        switch selector {
        case #selector(NSResponder.moveDown(_:)):
            guard let row = firstFileRow() else { return false }
            outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            outlineView.scrollRowToVisible(row)
            view.window?.makeFirstResponder(outlineView)
            return true
        case #selector(NSResponder.insertNewline(_:)):
            guard let row = firstFileRow(), let node = outlineView.item(atRow: row) as? FileTreeNode else { return false }
            outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            outlineView.scrollRowToVisible(row)
            activate(node, recursively: false)
            return true
        default:
            return false
        }
    }
}

final class FileTreeOutlineView: NSOutlineView {
    var onActivate: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        switch event.specialKey {
        case .carriageReturn?, .enter?: onActivate?()
        default: super.keyDown(with: event)
        }
    }
}
