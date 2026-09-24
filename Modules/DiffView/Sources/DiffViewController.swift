import AppKit
import DiffEngine
import PRModels

public final class DiffViewController: NSViewController {
    public var onToggleViewed: ((_ path: String, _ viewed: Bool) -> Void)?
    public var onVisibleFileChange: ((_ path: String) -> Void)?
    public var onLoadFullDiff: ((_ path: String) -> Void)?
    /// `hunk` is `nil` for the lines after the last hunk.
    public var onExpand: ((_ path: String, _ hunk: Int?) -> Void)?

    public let scrollView = NSScrollView()
    private let tableView = DiffTableView()
    private let renderer = DiffRenderer()
    private var rows: [RowRef] = []
    private var heights: [CGFloat] = []
    private var headerRows: [Int] = []
    private var fileIndex: [String: Int] = [:]
    private var layoutWidth: CGFloat = 0
    private var visibleFile: Int?
    private var selectionAnchor: (row: Int, side: DiffSide)?

    public override func loadView() {
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("diff"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)
        tableView.headerView = nil
        tableView.style = .plain
        tableView.intercellSpacing = .zero
        tableView.gridStyleMask = []
        tableView.selectionHighlightStyle = .none
        tableView.floatsGroupRows = true
        tableView.usesAutomaticRowHeights = false
        tableView.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        tableView.allowsColumnReordering = false
        tableView.allowsColumnResizing = false
        tableView.backgroundColor = NSColor(name: nil) { appearance in
            NSColor(cgColor: DiffTheme.resolve(for: appearance).background) ?? .textBackgroundColor
        }
        tableView.setAccessibilityIdentifier("diff.table")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyHandler = { [weak self] event in self?.handleKey(event) ?? false }
        tableView.copyHandler = { [weak self] in self?.copySelection() ?? false }

        scrollView.documentView = tableView
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.drawsBackground = true
        scrollView.backgroundColor = tableView.backgroundColor
        scrollView.contentView.postsBoundsChangedNotifications = true
        scrollView.contentView.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(self, selector: #selector(clipBoundsChanged), name: NSView.boundsDidChangeNotification, object: scrollView.contentView)
        NotificationCenter.default.addObserver(self, selector: #selector(clipFrameChanged), name: NSView.frameDidChangeNotification, object: scrollView.contentView)
        view = scrollView
    }

    public override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(tableView)
    }

    public override func viewWillLayout() {
        super.viewWillLayout()
        renderer.cache.setTheme(DiffTheme.resolve(for: view.effectiveAppearance))
    }

    public override func viewDidLayout() {
        super.viewDidLayout()
        let theme = DiffTheme.resolve(for: view.effectiveAppearance)
        if theme.isDark != renderer.theme.isDark {
            renderer.cache.setTheme(theme)
            tableView.enumerateAvailableRowViews { rowView, _ in rowView.needsDisplay = true }
        }
    }

    // MARK: Public API

    public var currentFilePath: String? {
        visibleFile.map { renderer.files[$0].item.file.path }
    }

    public var fileCount: Int { renderer.files.count }

    /// Visible row kinds and heights, for the QA harness.
    public var visibleRowSummary: String {
        let range = tableView.rows(in: scrollView.contentView.bounds)
        return (range.location..<NSMaxRange(range)).map { row in
            let kind = switch rows[row].kind {
            case .header: "H"
            case .hunk: "@"
            case .line: "L"
            case .thread: "T"
            case .notice: "N"
            case .expandTail: "E"
            case .footer: "F"
            }
            return heights[row] > Metrics.lineHeight * 2 ? "\(kind)\(Int(heights[row]))" : kind
        }.joined()
    }
    public var rowCount: Int { rows.count }

    public func focus() {
        view.window?.makeFirstResponder(tableView)
    }

    /// Replaces all files. Files already shown keep their collapse state.
    public func setFiles(_ items: [DiffFileItem]) {
        _ = view
        let previous = Dictionary(renderer.files.map { ($0.item.file.path, $0.collapsed) }, uniquingKeysWith: { first, _ in first })
        renderer.files = items.map { item in
            FileState(item: item, collapsed: previous[item.file.path] ?? (item.file.viewedState == .viewed))
        }
        fileIndex = Dictionary(items.enumerated().map { ($1.file.path, $0) }, uniquingKeysWith: { first, _ in first })
        renderer.cache.invalidateAll()
        rebuild(anchor: nil)
    }

    /// Replaces one file's content, highlights, and threads.
    public func updateFile(_ item: DiffFileItem) {
        guard let index = fileIndex[item.file.path] else { return }
        renderer.files[index].update(item)
        renderer.cache.invalidate(file: index)
        rebuild(anchor: .keepTopRow)
    }

    /// Adds highlights without a row rebuild; only visible rows redraw.
    public func updateHighlights(_ highlights: [String: SideHighlights]) {
        var changed = Set<Int>()
        for (path, sides) in highlights {
            guard let index = fileIndex[path] else { continue }
            renderer.files[index].item.highlights = sides
            renderer.cache.invalidate(file: index)
            changed.insert(index)
        }
        tableView.enumerateAvailableRowViews { rowView, _ in
            if let rowView = rowView as? DiffRowView, let ref = rowView.ref, changed.contains(ref.file) {
                rowView.needsDisplay = true
            }
        }
    }

    public func setViewed(_ viewed: Bool, path: String) {
        guard let index = fileIndex[path] else { return }
        let state = renderer.files[index]
        state.item.file.viewedState = viewed ? .viewed : .unviewed
        setCollapsed(viewed, file: index)
    }

    public func setAllCollapsed(_ collapsed: Bool) {
        for state in renderer.files { state.collapsed = collapsed }
        rebuild(anchor: visibleFile.map(Anchor.fileHeader) ?? .keepTopRow)
    }

    public func scrollToFile(_ path: String) {
        guard let index = fileIndex[path] else { return }
        scrollToRow(headerRows[index])
        updateVisibleFile(notify: false)
    }

    // MARK: Rows

    private enum Anchor {
        case keepTopRow
        case fileHeader(Int)
    }

    private func rebuild(anchor: Anchor?) {
        let saved = anchor.flatMap(captureAnchor)
        renderer.selection = nil
        selectionAnchor = nil
        layoutWidth = tableView.bounds.width
        var logical: [RowRef] = []
        for (index, state) in renderer.files.enumerated() {
            state.appendRows(file: index, to: &logical)
        }
        rows.removeAll(keepingCapacity: true)
        heights.removeAll(keepingCapacity: true)
        headerRows.removeAll(keepingCapacity: true)
        for ref in logical {
            if ref.kind == .header { headerRows.append(rows.count) }
            let height = renderer.height(of: ref, width: layoutWidth)
            guard height > Metrics.sliceHeight else {
                rows.append(ref)
                heights.append(height)
                continue
            }
            let slices = Int((height / Metrics.sliceHeight).rounded(.up))
            for slice in 0..<slices {
                rows.append(RowRef(file: ref.file, kind: ref.kind, slice: slice))
                heights.append(min(Metrics.sliceHeight, height - CGFloat(slice) * Metrics.sliceHeight))
            }
        }
        tableView.reloadData()
        if let saved { restoreAnchor(saved) }
        updateVisibleFile(notify: true)
    }

    private struct SavedAnchor {
        let ref: RowRef
        let offset: CGFloat
        let fallbackFile: Int
    }

    private func captureAnchor(_ anchor: Anchor) -> SavedAnchor? {
        let visibleTop = scrollView.contentView.bounds.minY
        switch anchor {
        case .keepTopRow:
            let row = tableView.row(at: CGPoint(x: 1, y: visibleTop + 1))
            guard row >= 0, row < rows.count else { return nil }
            return SavedAnchor(ref: rows[row], offset: tableView.rect(ofRow: row).minY - visibleTop, fallbackFile: rows[row].file)
        case let .fileHeader(file):
            let headerY = tableView.rect(ofRow: headerRows[file]).minY
            return SavedAnchor(ref: RowRef(file: file, kind: .header), offset: max(0, headerY - visibleTop), fallbackFile: file)
        }
    }

    private func restoreAnchor(_ anchor: SavedAnchor) {
        let start = headerRows[anchor.fallbackFile]
        let end = anchor.fallbackFile + 1 < headerRows.count ? headerRows[anchor.fallbackFile + 1] : rows.count
        if let row = rows[start..<end].firstIndex(of: anchor.ref) {
            scrollTo(y: tableView.rect(ofRow: row).minY - anchor.offset)
        } else {
            scrollToRow(start)
        }
    }

    private func scrollToRow(_ row: Int) {
        guard row >= 0, row < rows.count else { return }
        scrollTo(y: tableView.rect(ofRow: row).minY)
    }

    private func scrollTo(y: CGFloat) {
        let maxY = max(0, tableView.bounds.height - scrollView.contentView.bounds.height)
        scrollView.contentView.scroll(to: CGPoint(x: 0, y: min(max(0, y), maxY)))
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    private func setCollapsed(_ collapsed: Bool, file: Int) {
        let state = renderer.files[file]
        guard state.collapsed != collapsed else {
            redrawRows(ofFile: file)
            return
        }
        let headerY = tableView.rect(ofRow: headerRows[file]).minY
        let headerAboveViewport = headerY < scrollView.contentView.bounds.minY
        state.collapsed = collapsed
        rebuild(anchor: headerAboveViewport ? .fileHeader(file) : .keepTopRow)
    }

    private func redrawRows(ofFile file: Int) {
        tableView.enumerateAvailableRowViews { rowView, _ in
            if let rowView = rowView as? DiffRowView, rowView.ref?.file == file { rowView.needsDisplay = true }
        }
    }

    // MARK: Events

    private func handle(_ target: HitTarget, ref: RowRef) {
        let state = renderer.files[ref.file]
        let path = state.item.file.path
        switch target {
        case .toggleCollapse:
            setCollapsed(!state.collapsed, file: ref.file)
        case .toggleViewed:
            let viewed = state.item.file.viewedState != .viewed
            setViewed(viewed, path: path)
            onToggleViewed?(path, viewed)
        case .copyPath:
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(path, forType: .string)
        case .loadFullDiff:
            onLoadFullDiff?(path)
        case let .toggleThread(index):
            let id = state.item.threads[index].id
            if state.expandedResolvedThreads.contains(id) {
                state.expandedResolvedThreads.remove(id)
            } else {
                state.expandedResolvedThreads.insert(id)
            }
            rebuild(anchor: .keepTopRow)
        case let .expandHunk(hunk):
            onExpand?(path, hunk)
        case .expandTail:
            onExpand?(path, nil)
        }
    }

    // MARK: Line selection

    private func select(_ event: NSEvent, phase: DiffRowView.SelectPhase) {
        let point = tableView.convert(event.locationInWindow, from: nil)
        switch phase {
        case .begin:
            view.window?.makeFirstResponder(tableView)
            let row = tableView.row(at: point)
            guard row >= 0, row < rows.count, case .line = rows[row].kind else { return setSelection(nil) }
            let side = renderer.side(at: point.x, width: tableView.bounds.width, file: rows[row].file)
            selectionAnchor = (row, side)
            extendSelection(to: row)
        case .drag:
            guard selectionAnchor != nil else { return }
            tableView.autoscroll(with: event)
            let row = tableView.row(at: point)
            extendSelection(to: row >= 0 ? row : (point.y < 0 ? 0 : rows.count - 1))
        case .end:
            break
        }
    }

    private func extendSelection(to row: Int) {
        guard let anchor = selectionAnchor else { return }
        let range = min(anchor.row, row)...max(anchor.row, row)
        var refs = Set<RowRef>()
        for index in range {
            guard case let .line(hunk, lineRow) = rows[index].kind,
                  let line = renderer.files[rows[index].file].diff?.hunks[hunk].rows[lineRow],
                  (anchor.side == .left ? line.left : line.right) != nil
            else { continue }
            refs.insert(rows[index])
        }
        setSelection(LineSelection(side: anchor.side, refs: refs))
    }

    private func setSelection(_ selection: LineSelection?) {
        guard selection != renderer.selection else { return }
        let changed = (renderer.selection?.refs ?? []).symmetricDifference(selection?.refs ?? [])
        let sideChanged = renderer.selection?.side != selection?.side
        renderer.selection = selection
        if selection == nil { selectionAnchor = nil }
        tableView.enumerateAvailableRowViews { rowView, _ in
            if let rowView = rowView as? DiffRowView, let ref = rowView.ref,
               sideChanged ? (selection?.refs.contains(ref) ?? false) || changed.contains(ref) : changed.contains(ref) {
                rowView.needsDisplay = true
            }
        }
    }

    private func copySelection() -> Bool {
        guard let selection = renderer.selection, !selection.refs.isEmpty else { return false }
        let text = rows.filter { $0.slice == 0 && selection.refs.contains($0) }.compactMap { ref -> String? in
            guard case let .line(hunk, row) = ref.kind, let line = renderer.files[ref.file].diff?.hunks[hunk].rows[row] else { return nil }
            return (selection.side == .left ? line.left : line.right)?.text
        }.joined(separator: "\n")
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        return true
    }

    private func handleKey(_ event: NSEvent) -> Bool {
        if event.keyCode == 53, renderer.selection != nil {
            setSelection(nil)
            return true
        }
        guard event.modifierFlags.intersection([.command, .control, .option]).isEmpty else { return false }
        switch event.charactersIgnoringModifiers {
        case "j", "n": jumpFile(by: 1)
        case "k", "p": jumpFile(by: -1)
        case "v":
            guard let file = visibleFile else { return true }
            handle(.toggleViewed, ref: RowRef(file: file, kind: .header))
        case "x", "o":
            guard let file = visibleFile else { return true }
            setCollapsed(!renderer.files[file].collapsed, file: file)
        default:
            return false
        }
        return true
    }

    private func jumpFile(by delta: Int) {
        guard !renderer.files.isEmpty else { return }
        let current = visibleFile ?? 0
        let headerTop = tableView.rect(ofRow: headerRows[current]).minY
        let atHeader = abs(headerTop - scrollView.contentView.bounds.minY) < 1
        let target = delta < 0 && !atHeader ? current : current + delta
        scrollToRow(headerRows[min(max(0, target), renderer.files.count - 1)])
    }

    @objc private func clipBoundsChanged() {
        updateVisibleFile(notify: true)
    }

    @objc private func clipFrameChanged() {
        let width = tableView.bounds.width
        guard abs(width - layoutWidth) >= 1, !rows.isEmpty else { return }
        rebuild(anchor: .keepTopRow)
    }

    private func updateVisibleFile(notify: Bool) {
        guard !rows.isEmpty else { return }
        let probe = scrollView.contentView.bounds.minY + Metrics.headerHeight + 1
        let row = tableView.row(at: CGPoint(x: 1, y: probe))
        let file = row >= 0 && row < rows.count ? rows[row].file : renderer.files.count - 1
        guard file != visibleFile else { return }
        visibleFile = file
        if notify { onVisibleFileChange?(renderer.files[file].item.file.path) }
    }
}

extension DiffViewController: NSTableViewDataSource, NSTableViewDelegate {
    public func numberOfRows(in tableView: NSTableView) -> Int { rows.count }

    public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        row < heights.count ? heights[row] : Metrics.lineHeight
    }

    public func tableView(_ tableView: NSTableView, isGroupRow row: Int) -> Bool {
        rows[row].kind == .header
    }

    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? { nil }

    public func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let rowView = tableView.makeView(withIdentifier: DiffRowView.identifier, owner: self) as? DiffRowView ?? {
            let view = DiffRowView()
            view.identifier = DiffRowView.identifier
            return view
        }()
        rowView.renderer = renderer
        rowView.onHit = { [weak self] target, ref in self?.handle(target, ref: ref) }
        rowView.onSelect = { [weak self] event, phase in self?.select(event, phase: phase) }
        rowView.ref = rows[row]
        rowView.needsDisplay = true
        return rowView
    }

    public func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool { false }
}
