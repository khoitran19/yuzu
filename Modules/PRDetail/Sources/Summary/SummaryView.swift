import AppKit
import PRModels
import SwiftUI
import WebKit

/// The Summary page HTML. `timeline` and `sidebar` also sit inside `document`; later values replace them in place.
public struct SummaryPage: Equatable, Sendable {
    let document: String
    let timeline: String
    let sidebar: String
}

extension WKContentWorld {
    /// The sidebar click script runs here, so the page's own scripts cannot reach the message handler.
    public static let summarySidebar = WKContentWorld.world(name: "summarySidebar")
}

/// The merge methods the split button's caret offers.
struct MethodMenu {
    let allowed: [MergeMethod]
    let selected: MergeMethod
    let select: (MergeMethod) -> Void
}

struct SummaryView: View {
    let page: SummaryPage
    let focusPending: Bool
    let onFocus: () -> Void
    let methods: MethodMenu
    let onAction: (SidebarAction) -> Void

    var body: some View {
        HTMLView(page: page, focusPending: focusPending, onFocus: onFocus, methods: methods, onAction: onAction)
            .accessibilityIdentifier("prDetail.summary")
    }
}

private struct HTMLView: NSViewRepresentable {
    let page: SummaryPage
    let focusPending: Bool
    let onFocus: () -> Void
    let methods: MethodMenu
    let onAction: (SidebarAction) -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> FocusableWebView {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(context.coordinator.avatars, forURLScheme: AvatarScheme.name)
        let scripts = configuration.userContentController
        scripts.addUserScript(
            WKUserScript(
                source: Coordinator.sidebarScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true, in: .summarySidebar
            ))
        scripts.add(SidebarMessageProxy(context.coordinator), contentWorld: .summarySidebar, name: "sidebar")
        let webView = FocusableWebView(frame: .zero, configuration: configuration)
        context.coordinator.webView = webView
        context.coordinator.openURL = context.environment.openURL
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.load(page, in: webView)
        return webView
    }

    func updateNSView(_ webView: FocusableWebView, context: Context) {
        context.coordinator.openURL = context.environment.openURL
        context.coordinator.methods = methods
        context.coordinator.onAction = onAction
        webView.onFocus = onFocus
        if focusPending { webView.requestFocus() }
        context.coordinator.load(page, in: webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let avatars = AvatarScheme()
        var openURL: OpenURLAction?
        var methods: MethodMenu?
        var onAction: ((SidebarAction) -> Void)?
        weak var webView: WKWebView?
        private var document = ""
        private var page: SummaryPage?
        /// The parts in the DOM; they differ from `page` while newer parts wait for the page to load.
        private var shownTimeline = ""
        private var shownSidebar = ""
        private var isLoading = false

        /// Replaces only the changed parts when the description is unchanged, so the scroll position stays.
        func load(_ page: SummaryPage, in webView: WKWebView) {
            self.page = page
            if page.document != document {
                document = page.document
                shownTimeline = page.timeline
                shownSidebar = page.sidebar
                isLoading = true
                webView.loadHTMLString(page.document, baseURL: URL(string: "https://github.com"))
            } else if !isLoading {
                showParts(in: webView)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
            showParts(in: webView)
        }

        private func showParts(in webView: WKWebView) {
            guard let page else { return }
            if page.timeline != shownTimeline {
                shownTimeline = page.timeline
                replace(SummaryHTML.timelineElementID, with: page.timeline, in: webView)
            }
            if page.sidebar != shownSidebar {
                shownSidebar = page.sidebar
                replace(SummaryHTML.sidebarElementID, with: page.sidebar, in: webView)
            }
        }

        /// Keeps the open or closed state of the Checks list, which the user can toggle.
        private func replace(_ id: String, with html: String, in webView: WKWebView) {
            webView.callAsyncJavaScript(
                """
                const element = document.getElementById(id)
                const open = element.querySelector('details.checks')?.open
                element.innerHTML = html
                const details = element.querySelector('details.checks')
                if (open !== undefined && details) details.open = open
                """,
                arguments: ["id": id, "html": html],
                in: nil, in: .page
            )
        }

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard action.navigationType == .linkActivated, let url = action.request.url else { return .allow }
            if let openURL { openURL(url) } else { NSWorkspace.shared.open(url) }
            return .cancel
        }

        fileprivate func receive(_ message: WKScriptMessage) {
            guard message.frameInfo.isMainFrame, let body = message.body as? [String: Any],
                let name = body["action"] as? String, let action = SidebarAction(rawValue: name)
            else { return }
            guard action == .chooseMethod else {
                onAction?(action)
                return
            }
            if let rect = body["rect"] as? [Double], rect.count == 4 {
                showMethodMenu(below: CGRect(x: rect[0], y: rect[1], width: rect[2], height: rect[3]))
            }
        }

        private func showMethodMenu(below rect: CGRect) {
            guard let methods, let webView else { return }
            let menu = NSMenu()
            for method in methods.allowed {
                let item = NSMenuItem(title: method.buttonTitle, action: #selector(chooseMethod(_:)), keyEquivalent: "")
                item.subtitle = method.menuDescription
                item.target = self
                item.representedObject = method.rawValue
                item.state = method == methods.selected ? .on : .off
                menu.addItem(item)
            }
            let y = webView.isFlipped ? rect.maxY + 4 : webView.bounds.height - rect.maxY - 4
            menu.popUp(positioning: nil, at: NSPoint(x: max(0, rect.maxX - menu.size.width), y: y), in: webView)
        }

        @objc private func chooseMethod(_ item: NSMenuItem) {
            guard let raw = item.representedObject as? String, let method = MergeMethod(rawValue: raw) else { return }
            methods?.select(method)
        }

        /// Accepts only real clicks on sidebar buttons; `activate` lets the QA harness press a button.
        static let sidebarScript = """
            const sidebar = () => document.querySelector('body > .layout > aside#sidebar')
            function post(button) {
              const rect = button.getBoundingClientRect()
              window.webkit.messageHandlers.sidebar.postMessage({
                action: button.dataset.action, rect: [rect.left, rect.top, rect.width, rect.height]
              })
            }
            document.addEventListener('click', event => {
              if (!event.isTrusted || !(event.target instanceof Element)) return
              const button = event.target.closest('[data-action]')
              if (!button || button.disabled || !sidebar()?.contains(button)) return
              event.preventDefault()
              post(button)
            }, true)
            function activate(selector) {
              const element = document.querySelector(selector)
              if (!element) return false
              const button = element.closest('[data-action]')
              if (button && !button.disabled && sidebar()?.contains(button)) post(button)
              else element.click()
              return true
            }
            """
    }
}

private final class SidebarMessageProxy: NSObject, WKScriptMessageHandler {
    weak var coordinator: HTMLView.Coordinator?

    init(_ coordinator: HTMLView.Coordinator) {
        self.coordinator = coordinator
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        coordinator?.receive(message)
    }
}

extension MergeMethod {
    fileprivate var menuDescription: String {
        switch self {
        case .merge: "All commits from this branch are added to the base branch with a merge commit."
        case .squash: "The commits from this branch are combined into one commit in the base branch."
        case .rebase: "The commits from this branch are rebased and added to the base branch."
        }
    }
}

/// Takes keyboard focus on request, at once or when it joins a window.
final class FocusableWebView: WKWebView {
    var onFocus: (() -> Void)?
    private var wantsFocus = false

    func requestFocus() {
        wantsFocus = true
        takeFocusIfPossible()
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        takeFocusIfPossible()
    }

    private func takeFocusIfPossible() {
        guard wantsFocus, let window else { return }
        wantsFocus = false
        window.makeFirstResponder(self)
        let onFocus = onFocus
        Task { @MainActor in onFocus?() }
    }
}
