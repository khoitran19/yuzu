import AppKit
import PRDetail
import PRModels
import SwiftUI

struct MainWindowView: View {
    @Environment(AppServices.self) private var services
    @State private var detail: PRDetailModel?
    @State private var address = ""
    @State private var addressInvalid = false
    @State private var window: NSWindow?
    @State private var harness: HarnessRunner?
    @FocusState private var addressFocused: Bool

    var body: some View {
        Group {
            if let detail {
                PRDetailView(model: detail)
                    .id(detail.ref)
            } else {
                HomeView(address: $address, open: submit(_:))
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button(action: goHome) { Image(systemName: "house") }
                    .help("Home")
                    .disabled(detail == nil)
            }
            ToolbarItem(placement: .principal) { addressField }
        }
        .navigationTitle(detail?.pullRequest?.title ?? "PR Viewer")
        .navigationSubtitle(detail?.ref.displayName ?? "")
        .background(WindowAccessor { window = $0 })
        .environment(\.openURL, OpenURLAction(handler: openLink))
        .focusedSceneValue(\.windowActions, WindowActions(
            focusAddress: { addressFocused = true },
            openFromClipboard: openFromClipboard
        ))
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
            let runner = HarnessRunner(options: options, model: model, window: window)
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

    private func openFromClipboard() {
        if let text = NSPasteboard.general.string(forType: .string), let ref = PRRef(string: text) { open(ref) }
    }
}

struct WindowActions {
    let focusAddress: () -> Void
    let openFromClipboard: () -> Void
}

extension FocusedValues {
    @Entry var windowActions: WindowActions?
}

struct PullRequestCommands: Commands {
    @FocusedValue(\.windowActions) private var actions

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Open Pull Request…") { actions?.focusAddress() }
                .keyboardShortcut("l")
                .disabled(actions == nil)
            Button("Open Pull Request from Clipboard") { actions?.openFromClipboard() }
                .keyboardShortcut("v", modifiers: [.command, .shift])
                .disabled(actions == nil)
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
