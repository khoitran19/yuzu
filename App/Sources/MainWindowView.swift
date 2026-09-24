import AppKit
import AppShortcuts
import GitHubKit
import PRDetail
import PRList
import PRModels
import SwiftUI

struct MainWindowView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.openWindow) private var openWindow
    /// The window's scene value, kept for state restoration.
    @Binding var ref: PRRef?
    @State private var detail: PRDetailModel?
    @State private var address = ""
    @State private var addressInvalid = false
    @State private var window: NSWindow?
    @State private var harness: HarnessRunner?
    @State private var pullRequestList: PRListModel
    @FocusState private var addressFocused: Bool

    init(ref: Binding<PRRef?>, lists: PRListStore) {
        _ref = ref
        _pullRequestList = State(initialValue: PRListModel(store: lists))
    }

    var body: some View {
        screen
        .pullRequestListPanel(pullRequestList) { open($0, in: .newTab) }
        .toolbar { toolbar }
        .navigationTitle(detail.map { $0.pullRequest?.title ?? $0.ref.displayName } ?? "Yuzu")
        .navigationSubtitle(detail?.ref.displayName ?? "")
        .background(WindowAccessor(onAttach: { [ref] in services.windows.attach($0, showing: ref) }) { window = $0 })
        .environment(\.openURL, OpenURLAction(handler: openLink))
        .focusedSceneValue(\.windowActions, windowActions)
        .onChange(of: activeRepository, initial: true) { _, repo in pullRequestList.setRepository(repo) }
        .onChange(of: detail?.ref, initial: true) { _, ref in
            pullRequestList.current = ref
            if let window { services.windows.set(ref, for: window) }
        }
        .task {
            if let ref {
                show(ref)
            } else if let ref = await services.takeLaunchRef() {
                show(ref, runsHarness: true)
            }
        }
        .onChange(of: window) { _, window in
            guard let window else { return }
            services.windows.set(detail?.ref, for: window)
            if let size = services.options.windowSize {
                window.setContentSize(size)
                window.center()
            }
        }
        .onDisappear {
            if let window { services.windows.set(nil, for: window) }
        }
    }

    @ViewBuilder private var screen: some View {
        if let detail {
            PRDetailView(model: detail)
                .id(detail.ref)
        } else {
            HomeView(address: $address, open: submit(_:))
        }
    }

    @ToolbarContentBuilder private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button(action: goHome) { Image(systemName: "house") }
                .help("Home")
                .disabled(detail == nil)
        }
        ToolbarItem(placement: .principal) { addressField }
        ToolbarItem(placement: .primaryAction) {
            Button(action: pullRequestList.toggle) { Image(nsImage: Octicon.gitPullRequest.image) }
                .help("Open pull requests (\(Shortcut.myPullRequests.symbols))")
                .disabled(activeRepository == nil)
                .accessibilityIdentifier("prList.toggle")
        }
    }

    private var windowActions: WindowActions {
        let list = pullRequestList
        let detail = detail
        return WindowActions(
            focusAddress: focusAddress,
            openFromClipboard: openFromClipboard,
            showPullRequests: activeRepository == nil ? nil : { list.request($0) },
            showTab: detail.map { detail in
                { tab in
                    list.close()
                    detail.show(tab)
                }
            },
            review: detail.flatMap { detail in
                detail.canReview
                    ? { event in
                        list.close()
                        detail.show(.summary)
                        detail.startReview(event)
                    } : nil
            },
            merge: detail.flatMap { detail in
                detail.canMerge
                    ? {
                        list.close()
                        detail.show(.summary)
                        detail.runPrimaryMergeAction()
                    } : nil
            },
            draftToggle: detail.flatMap { detail in
                detail.draftToggleTitle.map { title in (title, detail.toggleDraft) }
            }
        )
    }

    private var activeRepository: RepoRef? {
        PRListModel.activeRepository(openPullRequest: detail?.ref, recent: services.recents.entries.map(\.ref))
    }

    private var addressField: some View {
        TextField("Paste a pull request link or number", text: $address)
            .textFieldStyle(.roundedBorder)
            .font(.system(.body, design: .monospaced))
            .frame(minWidth: 360, idealWidth: 560, maxWidth: 640)
            .focused($addressFocused)
            .onSubmit { submit(address) }
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.red, lineWidth: addressInvalid ? 1 : 0))
            .accessibilityIdentifier("address.field")
    }

    private func submit(_ text: String) {
        guard let ref = PRRef(string: text, in: activeRepository) else {
            addressInvalid = true
            return
        }
        open(ref, in: .currentTab)
    }

    private enum Placement {
        case currentTab
        /// A window that shows Home is reused.
        case newTab
    }

    /// Switches to the tab that shows `ref` when one exists.
    private func open(_ ref: PRRef, in placement: Placement) {
        if ref != detail?.ref, let other = services.windows.window(showing: ref) {
            addressInvalid = false
            addressFocused = false
            address = detail?.ref.webURL.absoluteString ?? ""
            other.makeKeyAndOrderFront(nil)
        } else if placement == .newTab, let detail, detail.ref != ref {
            services.windows.openingTab(ref, from: window)
            openWindow(id: "main", value: ref)
        } else {
            show(ref)
        }
    }

    private func show(_ ref: PRRef, runsHarness: Bool = false) {
        guard let service = services.service(for: ref) else { return }
        self.ref = ref
        addressInvalid = false
        address = ref.webURL.absoluteString
        addressFocused = false
        let model = PRDetailModel(ref: ref, service: service, highlighter: services.highlighter, rules: services.rulesStore.rules)
        model.onDetail = { [recents = services.recents, options = services.options] pullRequest in
            if !options.isHarness { recents.record(ref, title: pullRequest.title) }
        }
        model.onLoaded = { [weak model, options = services.options] in
            guard runsHarness, options.isHarness, !options.settings, let model else { return }
            let runner = HarnessRunner(
                options: options, model: model, pullRequestList: pullRequestList, window: window,
                openTab: { open($0, in: .newTab) }
            )
            harness = runner
            runner.run()
        }
        if let tab = services.options.tab { model.tab = tab }
        detail = model
    }

    private func openLink(_ url: URL) -> OpenURLAction.Result {
        guard let link = PRLink(url: url) else { return .systemAction }
        if let detail, detail.ref == link.ref {
            if link.showsFiles { detail.tab = .files }
        } else {
            open(link.ref, in: .newTab)
        }
        return .handled
    }

    private func goHome() {
        detail = nil
        ref = nil
        address = ""
    }

    /// Setting `addressFocused` does not take first responder from an AppKit view such as the diff table.
    private func focusAddress() {
        pullRequestList.close()
        guard let window = NSApp.keyWindow, let frame = window.contentView?.superview,
              let field = Self.toolbarTextField(in: frame, excluding: window.contentView)
        else { return }
        window.makeFirstResponder(field)
        field.currentEditor()?.selectAll(nil)
    }

    /// The address field is the only editable text field outside the window content.
    private static func toolbarTextField(in view: NSView, excluding content: NSView?) -> NSTextField? {
        if view === content { return nil }
        if let field = view as? NSTextField, field.isEditable { return field }
        return view.subviews.lazy.compactMap { toolbarTextField(in: $0, excluding: content) }.first
    }

    private func openFromClipboard() {
        if let text = NSPasteboard.general.string(forType: .string), let ref = PRRef(string: text) { open(ref, in: .newTab) }
    }
}

struct WindowActions {
    let focusAddress: () -> Void
    let openFromClipboard: () -> Void
    /// `nil` when the window has no active repository.
    let showPullRequests: ((PullRequestListScope) -> Void)?
    /// `nil` when no pull request is open.
    let showTab: ((PRDetailModel.Tab) -> Void)?
    /// `nil` when the viewer cannot review now: no pull request, the viewer is the author, or an action runs.
    let review: ((PullRequestAction.ReviewEvent) -> Void)?
    /// `nil` when the merge box has no primary action.
    let merge: (() -> Void)?
    /// "Mark as Ready for Review" or "Convert to Draft"; `nil` when the viewer cannot change it.
    let draftToggle: (title: String, run: () -> Void)?
}

extension FocusedValues {
    @Entry var windowActions: WindowActions?
}

struct PullRequestCommands: Commands {
    @FocusedValue(\.windowActions) private var actions

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button(Shortcut.openPullRequest.title) { actions?.focusAddress() }
                .keyboardShortcut(Shortcut.openPullRequest.keyboardShortcut)
                .disabled(actions == nil)
            Button(Shortcut.openFromClipboard.title) { actions?.openFromClipboard() }
                .keyboardShortcut(Shortcut.openFromClipboard.keyboardShortcut)
                .disabled(actions == nil)
        }
        CommandGroup(before: .toolbar) {
            Button(Shortcut.myPullRequests.title) { actions?.showPullRequests?(.mine) }
                .keyboardShortcut(Shortcut.myPullRequests.keyboardShortcut)
                .disabled(actions?.showPullRequests == nil)
            Button(Shortcut.otherPullRequests.title) { actions?.showPullRequests?(.others) }
                .keyboardShortcut(Shortcut.otherPullRequests.keyboardShortcut)
                .disabled(actions?.showPullRequests == nil)
            Divider()
            Button(Shortcut.previousTab.title) { Self.frontWindow?.selectTab(offset: -1) }
                .keyboardShortcut(Shortcut.previousTab.keyboardShortcut)
            Button(Shortcut.nextTab.title) { Self.frontWindow?.selectTab(offset: 1) }
                .keyboardShortcut(Shortcut.nextTab.keyboardShortcut)
            Divider()
            Button(Shortcut.showSummary.title) { actions?.showTab?(.summary) }
                .keyboardShortcut(Shortcut.showSummary.keyboardShortcut)
                .disabled(actions?.showTab == nil)
            Button(Shortcut.showFiles.title) { actions?.showTab?(.files) }
                .keyboardShortcut(Shortcut.showFiles.keyboardShortcut)
                .disabled(actions?.showTab == nil)
            Divider()
        }
        CommandGroup(replacing: .printItem) {}
        CommandMenu("Pull Request") {
            Button(Shortcut.approve.title) { actions?.review?(.approve) }
                .keyboardShortcut(Shortcut.approve.keyboardShortcut)
                .disabled(actions?.review == nil)
            Button(Shortcut.requestChanges.title) { actions?.review?(.requestChanges) }
                .keyboardShortcut(Shortcut.requestChanges.keyboardShortcut)
                .disabled(actions?.review == nil)
            Button(Shortcut.merge.title) { actions?.merge?() }
                .keyboardShortcut(Shortcut.merge.keyboardShortcut)
                .disabled(actions?.merge == nil)
            Divider()
            Button(actions?.draftToggle?.title ?? "Convert to Draft") { actions?.draftToggle?.run() }
                .disabled(actions?.draftToggle == nil)
        }
    }

    private static var frontWindow: NSWindow? {
        NSApp.keyWindow ?? NSApp.mainWindow ?? NSApp.orderedWindows.first { $0.tabbedWindows != nil }
    }
}

struct WindowAccessor: NSViewRepresentable {
    /// Runs at once, in the call that moves the view into the window.
    var onAttach: (NSWindow) -> Void = { _ in }
    let onWindow: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = AccessorView()
        view.onAttach = onAttach
        view.onWindow = onWindow
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class AccessorView: NSView {
        var onAttach: ((NSWindow) -> Void)?
        var onWindow: ((NSWindow) -> Void)?

        // A replaced accessor view leaves its window after the new one arrives, so a `nil` window is not reported.
        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            guard let window else { return }
            onAttach?(window)
            Task { @MainActor in onWindow?(window) }
        }
    }
}
