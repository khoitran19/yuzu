import AppKit
import PRModels
import SwiftUI
import WebKit

struct SummaryView: View {
    let pullRequest: PullRequest

    var body: some View {
        HTMLView(html: SummaryHTML.document(body: pullRequest.bodyHTML, author: pullRequest.author?.login, createdAt: pullRequest.createdAt))
            .accessibilityIdentifier("prDetail.summary")
    }
}

private struct HTMLView: NSViewRepresentable {
    let html: String

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        webView.loadHTMLString(html, baseURL: URL(string: "https://github.com"))
        context.coordinator.html = html
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        guard context.coordinator.html != html else { return }
        context.coordinator.html = html
        webView.loadHTMLString(html, baseURL: URL(string: "https://github.com"))
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        var html = ""

        func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
            guard action.navigationType == .linkActivated, let url = action.request.url else { return .allow }
            NSWorkspace.shared.open(url)
            return .cancel
        }
    }
}

enum SummaryHTML {
    static func document(body: String, author: String?, createdAt: Date) -> String {
        let content = body.isEmpty ? "<p class=\"empty\">No description provided.</p>" : body
        let date = createdAt.formatted(date: .abbreviated, time: .shortened)
        return """
        <!doctype html>
        <html><head><meta charset="utf-8"><style>\(css)</style></head>
        <body><div class="card">
        <div class="card-header"><strong>\(escape(author ?? "ghost"))</strong> opened this pull request on \(escape(date))</div>
        <div class="markdown-body">\(content)</div>
        </div></body></html>
        """
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;").replacingOccurrences(of: ">", with: "&gt;")
    }

    private static let css = """
    :root { color-scheme: light dark; --fg: #1f2328; --muted: #59636e; --border: #d1d9e0; --subtle: #f6f8fa; --link: #0969da; --code: rgba(129,139,152,.12); }
    @media (prefers-color-scheme: dark) { :root { --fg: #e6edf3; --muted: #9198a1; --border: #3d444d; --subtle: #151b23; --link: #4493f8; --code: rgba(101,108,118,.2); } }
    html, body { background: transparent; }
    body { font: 14px/1.5 -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; color: var(--fg); margin: 16px; }
    .card { border: 1px solid var(--border); border-radius: 6px; max-width: 1012px; }
    .card-header { background: var(--subtle); border-bottom: 1px solid var(--border); padding: 8px 16px; color: var(--muted); border-radius: 6px 6px 0 0; }
    .card-header strong { color: var(--fg); }
    .markdown-body { padding: 16px; overflow-wrap: break-word; }
    .markdown-body > :first-child { margin-top: 0; }
    .markdown-body > :last-child { margin-bottom: 0; }
    .empty { color: var(--muted); font-style: italic; }
    a { color: var(--link); text-decoration: none; } a:hover { text-decoration: underline; }
    h1, h2 { border-bottom: 1px solid var(--border); padding-bottom: .3em; }
    h1 { font-size: 2em; } h2 { font-size: 1.5em; } h3 { font-size: 1.25em; }
    h1, h2, h3, h4 { margin: 24px 0 16px; font-weight: 600; line-height: 1.25; }
    p, ul, ol, table, pre, blockquote, details { margin: 0 0 16px; }
    ul, ol { padding-left: 2em; }
    code, pre { font: 12px ui-monospace, SFMono-Regular, Menlo, monospace; }
    code { background: var(--code); padding: .2em .4em; border-radius: 6px; }
    pre { background: var(--subtle); padding: 16px; border-radius: 6px; overflow: auto; line-height: 1.45; }
    pre code { background: none; padding: 0; }
    blockquote { color: var(--muted); border-left: .25em solid var(--border); padding: 0 1em; margin-left: 0; }
    table { border-collapse: collapse; display: block; overflow: auto; }
    th, td { border: 1px solid var(--border); padding: 6px 13px; }
    th { font-weight: 600; }
    img { max-width: 100%; }
    hr { border: 0; height: .25em; background: var(--border); margin: 24px 0; }
    input[type=checkbox] { margin: 0 .2em .25em -1.4em; vertical-align: middle; }
    li.task-list-item { list-style: none; }
    summary { cursor: pointer; }
    """
}
