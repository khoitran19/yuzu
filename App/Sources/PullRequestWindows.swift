import AppKit
import PRModels

/// A window's scene value. The ID keeps SwiftUI from reusing a window that shows, or just showed, the same pull request;
/// `PullRequestWindows` finds open tabs instead.
struct WindowTab: Codable, Hashable {
    let ref: PRRef
    var id = UUID()
}

/// The pull request each window shows, so an open request can switch to the tab that has it.
@MainActor
final class PullRequestWindows {
    private struct Entry {
        weak var window: NSWindow?
        let ref: PRRef
    }

    private struct PendingTab {
        weak var host: NSWindow?
        /// The batch and place of a background tab. `nil` for a tab that opens after the host and takes the selection.
        let batch: (id: UUID, position: Int)?
    }

    /// The latest background batch of one host, and the place of each of its windows.
    private struct Batch {
        let id: UUID
        var positions: [ObjectIdentifier: Int]
    }

    private var entries: [ObjectIdentifier: Entry] = [:]
    /// New tabs by `WindowTab.id`, until their windows attach.
    private var pending: [UUID: PendingTab] = [:]
    /// SwiftUI can create the windows of one batch in any order, so each background tab keeps its place here.
    private var batches: [ObjectIdentifier: Batch] = [:]
    /// Titles for tabs that have not loaded yet.
    private var titles: [PRRef: String] = [:]

    func openingTab(_ tab: WindowTab, from host: NSWindow?) {
        pending[tab.id] = PendingTab(host: host, batch: nil)
    }

    /// Tabs that go after the host in this order and do not take the selection. They replace an earlier batch of the host.
    func openingBackgroundTabs(_ tabs: [(tab: WindowTab, title: String)], from host: NSWindow) {
        let id = UUID()
        batches[ObjectIdentifier(host)] = Batch(id: id, positions: [ObjectIdentifier(host): 0])
        for (index, item) in tabs.enumerated() {
            pending[item.tab.id] = PendingTab(host: host, batch: (id, index + 1))
            titles[item.tab.ref] = item.title
        }
    }

    /// SwiftUI shows a new window before AppKit can tab it automatically, so the new window joins its host's group here.
    func attach(_ window: NSWindow, tab: UUID?) {
        guard let tab, let entry = pending.removeValue(forKey: tab), let host = entry.host, host !== window else { return }
        guard let (batchID, position) = entry.batch else {
            if host.tabbedWindows?.contains(window) != true { host.addTabbedWindow(window, ordered: .above) }
            host.tabGroup?.selectedWindow = window
            return
        }
        guard var batch = batches[ObjectIdentifier(host)], batch.id == batchID, let group = host.tabGroup else {
            // The window is still joining its view, so it closes on the next turn.
            Task { @MainActor in window.close() }
            return
        }
        batch.positions[ObjectIdentifier(window)] = position
        batches[ObjectIdentifier(host)] = batch
        let before = group.windows.lastIndex { batch.positions[ObjectIdentifier($0)].map { $0 < position } ?? false }
        group.insertWindow(window, at: (before ?? 0) + 1)
        group.selectedWindow = host
    }

    func title(for ref: PRRef) -> String? {
        titles[ref]
    }

    func set(_ ref: PRRef?, for window: NSWindow) {
        entries[ObjectIdentifier(window)] = ref.map { Entry(window: window, ref: $0) }
    }

    func window(showing ref: PRRef) -> NSWindow? {
        entries = entries.filter { $0.value.window != nil }
        return entries.values.first { $0.ref == ref }?.window
    }
}

extension NSWindow {
    /// Selects the tab `offset` places away in this window's tab group, and wraps at the ends.
    func selectTab(offset: Int) {
        guard let group = tabGroup, group.windows.count > 1,
              let index = group.windows.firstIndex(of: group.selectedWindow ?? self)
        else { return }
        let count = group.windows.count
        group.windows[((index + offset) % count + count) % count].makeKeyAndOrderFront(nil)
    }
}
