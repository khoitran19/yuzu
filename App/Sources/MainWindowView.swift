import AppKit
import AppShortcuts
import GitHubKit
import PRDetail
import PRList
import PRModels
import SwiftUI

struct MainWindowView: View {
    @Environment(AppServices.self) private var services
    @State private var detail: PRDetailModel?
    @State private var address = ""
    @State private var addressInvalid = false
    @State private var window: NSWindow?
    @State private var harness: HarnessRunner?
    @State private var pullRequestList: PRListModel
    @FocusState private var addressFocused: Bool

    init(service: any PullRequestService) {
        _pullRequestList = State(initialValue: PRListModel(service: service))
    }

    var body: some View {
        screen
        .pullRequestListPanel(pullRequestList, open: open(_:))
        .toolbar { toolbar }
        .navigationTitle(detail?.pullRequest?.title ?? "PR Viewer")
        .navigationSubtitle(detail?.ref.displayName ?? "")
        .background(WindowAccessor { window = $0 })
        .environment(\.openURL, OpenURLAction(handler: openLink))
        .focusedSceneValue(\.windowActions, windowActions)
        .onChange(of: activeRepository, initial: true) { _, repo in pullRequestList.setRepository(repo) }
        .onChange(of: detail?.ref, initial: true) { _, ref in pullRequestList.current = ref }
        .task {
            if let ref = services.options.open {
                open(ref)
            } else if let ref = await services.fixtureRef() {
                open(ref)
            }
        }
        .onChange(of: window) { _, window in
            if let window, let size = services.options.windowSize {
                window.setContentSize(size)
                window.center()
            }
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
            }
        )
    }

    private var activeRepository: RepoRef? {
        PRListModel.activeRepository(openPullRequest: detail?.ref, recent: services.recents.entries.map(\.ref))
    }

    private var addressField: some View {
        TextField("Paste a pull request link", text: $address)
            .textFieldStyle(.roundedBorder)
            .font(.system(.body, design: .monospaced))
            .frame(minWidth: 360, idealWidth: 560, maxWidth: 640)
            .focused($addressFocused)
            .onSubmit { submit(address) }
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(.red, lineWidth: addressInvalid ? 1 : 0))
            .accessibilityIdentifier("address.field")
    }

    private func submit(_ text: String) {
        guard let ref = PRRef(string: text) else {
            addressInvalid = true
            return
        }
        open(ref)
    }

    private func open(_ ref: PRRef) {
        guard let service = services.service(for: ref) else { return }
        addressInvalid = false
        address = ref.webURL.absoluteString
        addressFocused = false
        let model = PRDetailModel(ref: ref, service: service, highlighter: services.highlighter, rules: services.rulesStore.rules)
        model.onDetail = { [recents = services.recents, options = services.options] pullRequest in
            if !options.isHarness { recents.record(ref, title: pullRequest.title) }
        }
        model.onLoaded = { [weak model, options = services.options] in
            guard options.isHarness, !options.settings, let model else { return }
            let runner = HarnessRunner(options: options, model: model, pullRequestList: pullRequestList, window: window)
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
            open(link.ref)
        }
        return .handled
    }

    private func goHome() {
        detail = nil
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
        if let text = NSPasteboard.general.string(forType: .string), let ref = PRRef(string: text) { open(ref) }
    }
}

struct WindowActions {
    let focusAddress: () -> Void
    let openFromClipboard: () -> Void
    /// `nil` when the window has no active repository.
    let showPullRequests: ((PullRequestListScope) -> Void)?
    /// `nil` when no pull request is open.
    let showTab: ((PRDetailModel.Tab) -> Void)?
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
            Button(Shortcut.showSummary.title) { actions?.showTab?(.summary) }
                .keyboardShortcut(Shortcut.showSummary.keyboardShortcut)
                .disabled(actions?.showTab == nil)
            Button(Shortcut.showFiles.title) { actions?.showTab?(.files) }
                .keyboardShortcut(Shortcut.showFiles.keyboardShortcut)
                .disabled(actions?.showTab == nil)
            Divider()
        }
    }
}

struct WindowAccessor: NSViewRepresentable {
    let onWindow: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = AccessorView()
        view.onWindow = onWindow
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    private final class AccessorView: NSView {
        var onWindow: ((NSWindow?) -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            let window = window
            Task { @MainActor in onWindow?(window) }
        }
    }
}
