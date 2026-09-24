import AppKit
import SwiftUI
import WebKit

/// The Summary page HTML. `conversation` also sits inside `document`; a later `conversation` replaces it in place.
public struct SummaryPage: Equatable, Sendable {
    let document: String
    let conversation: String
}

struct SummaryView: View {
    let page: SummaryPage

    var body: some View {
        HTMLView(page: page)
            .accessibilityIdentifier("prDetail.summary")
    }
}

private struct HTMLView: NSViewRepresentable {
    let page: SummaryPage

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.setURLSchemeHandler(context.coordinator.avatars, forURLScheme: AvatarScheme.name)
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        context.coordinator.load(page, in: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        context.coordinator.load(page, in: webView)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let avatars = AvatarScheme()
        private var document = ""
        private var conversation = ""
        /// The conversation in the DOM; it differs from `conversation` while a newer one waits for the page to load.
        private var shownConversation = ""
        private var isLoading = false

        /// Replaces only the conversation when the description is unchanged, so the scroll position stays.
        func load(_ page: SummaryPage, in webView: WKWebView) {
            conversation = page.conversation
            if page.document != document {
                document = page.document
                shownConversation = page.conversation
                isLoading = true
                webView.loadHTMLString(page.document, baseURL: URL(string: "https://github.com"))
            } else if !isLoading {
                showConversation(in: webView)
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            isLoading = false
            showConversation(in: webView)
        }

        private func showConversation(in webView: WKWebView) {
            guard conversation != shownConversation else { return }
            shownConversation = conversation
            inject(conversation, into: webView)
        }

        private func inject(_ html: String, into webView: WKWebView) {
            webView.callAsyncJavaScript(
                "document.getElementById(id).innerHTML = html",
                arguments: ["id": SummaryHTML.conversationElementID, "html": html],
                in: nil, in: .page
            )
        }

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard action.navigationType == .linkActivated, let url = action.request.url else { return .allow }
            NSWorkspace.shared.open(url)
            return .cancel
        }
    }
}
