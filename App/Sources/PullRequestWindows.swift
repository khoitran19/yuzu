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

    private struct TabHost {
        weak var window: NSWindow?
        /// The place of a background tab after the host. `nil` for a tab that opens after the host and takes the selection.
        let position: Int?
    }

    private var entries: [ObjectIdentifier: Entry] = [:]
    /// The window that asked for each new tab.
    private var tabHosts: [PRRef: TabHost] = [:]
    /// Titles for tabs that have not loaded yet.
    private var titles: [PRRef: String] = [:]
    /// SwiftUI can create the windows of one batch in any order, so each background tab keeps its place here.
    private var positions: [ObjectIdentifier: Int] = [:]

    func openingTab(_ ref: PRRef, from host: NSWindow?) {
        tabHosts[ref] = TabHost(window: host, position: nil)
    }

    /// Tabs that go after the host in this order and do not take the selection.
    func openingBackgroundTabs(_ tabs: [(ref: PRRef, title: String)], from host: NSWindow?) {
        positions = host.map { [ObjectIdentifier($0): 0] } ?? [:]
        for (index, tab) in tabs.enumerated() {
            tabHosts[tab.ref] = TabHost(window: host, position: index + 1)
            titles[tab.ref] = tab.title
        }
    }

    /// SwiftUI shows a new window before AppKit can tab it automatically, so the new window joins its host's group here.
    func attach(_ window: NSWindow, showing ref: PRRef?) {
        guard let ref, let entry = tabHosts.removeValue(forKey: ref), let host = entry.window, host !== window else { return }
        guard let position = entry.position, let group = host.tabGroup else {
            if host.tabbedWindows?.contains(window) != true { host.addTabbedWindow(window, ordered: .above) }
            host.tabGroup?.selectedWindow = window
            return
        }
        positions[ObjectIdentifier(window)] = position
        let before = group.windows.lastIndex { positions[ObjectIdentifier($0)].map { $0 < position } ?? false }
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
