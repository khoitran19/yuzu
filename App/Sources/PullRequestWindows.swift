import AppKit
import PRModels

/// The pull request each window shows, so an open request can switch to the tab that has it.
@MainActor
final class PullRequestWindows {
    private struct Entry {
        weak var window: NSWindow?
        let ref: PRRef
    }

    private struct WeakWindow {
        weak var window: NSWindow?
    }

    private var entries: [ObjectIdentifier: Entry] = [:]
    /// The window that asked for each new tab.
    private var tabHosts: [PRRef: WeakWindow] = [:]

    func openingTab(_ ref: PRRef, from host: NSWindow?) {
        tabHosts[ref] = WeakWindow(window: host)
    }

    /// SwiftUI shows a new window before AppKit can tab it automatically, so the new window joins its host's group here.
    func attach(_ window: NSWindow, showing ref: PRRef?) {
        guard let ref, let host = tabHosts.removeValue(forKey: ref)?.window, host !== window else { return }
        if host.tabbedWindows?.contains(window) != true { host.addTabbedWindow(window, ordered: .above) }
        host.tabGroup?.selectedWindow = window
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
