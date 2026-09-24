import AppKit
import SwiftUI
import WebKit

/// The Summary page HTML. `timeline` and `checks` also sit inside `document`; later values replace them in place.
public struct SummaryPage: Equatable, Sendable {
    let document: String
    let timeline: String
    let checks: String
}

struct SummaryView: View {
    let page: SummaryPage
    let focusPending: Bool
    let onFocus: () -> Void

    var body: some View {
        HTMLView(page: page, focusPending: focusPending, onFocus: onFocus)
            .accessibilityIdentifier("prDetail.summary")
    }
}

private struct HTMLView: NSViewRepresentable {
    let page: SummaryPage
    let focusPending: Bool
    let onFocus: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> FocusableWebView {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(context.coordinator.avatars, forURLScheme: AvatarScheme.name)
        let webView = FocusableWebView(frame: .zero, configuration: configuration)
        context.coordinator.openURL = context.environment.openURL
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.load(page, in: webView)
        return webView
    }

    func updateNSView(_ webView: FocusableWebView, context: Context) {
        context.coordinator.openURL = context.environment.openURL
        webView.onFocus = onFocus
        if focusPending { webView.requestFocus() }
        context.coordinator.load(page, in: webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let avatars = AvatarScheme()
        var openURL: OpenURLAction?
        private var document = ""
        private var page: SummaryPage?
        /// The parts in the DOM; they differ from `page` while newer parts wait for the page to load.
        private var shownTimeline = ""
        private var shownChecks = ""
        private var isLoading = false

        /// Replaces only the changed parts when the description is unchanged, so the scroll position stays.
        func load(_ page: SummaryPage, in webView: WKWebView) {
            self.page = page
            if page.document != document {
                document = page.document
                shownTimeline = page.timeline
                shownChecks = page.checks
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
            if page.checks != shownChecks {
                shownChecks = page.checks
                replace(SummaryHTML.checksElementID, with: page.checks, in: webView)
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
