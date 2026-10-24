import Foundation
import GitHubKit
import WebKit

/// Serves `yuzu-image:` URLs with the GitHub token, for images in private repositories that the web view cannot load.
final class GitHubImageScheme: NSObject, WKURLSchemeHandler {
    typealias Fetch = @Sendable (URL) async throws -> Data

    nonisolated static let name = "yuzu-image"

    private let fetch: Fetch
    private var cache: [URL: Data] = [:]
    private var running: Set<ObjectIdentifier> = []

    init(fetch: @escaping Fetch) {
        self.fetch = fetch
    }

    /// Points each `<img>` at this scheme when its source needs the token. Other images keep their URL.
    nonisolated static func rewrite(_ html: String) -> String {
        guard html.contains("<img") else { return html }
        return html.replacing(#/(<img\b[^>]*?\bsrc=")([^"]+)"/#) { match in
            let value = match.output.2.replacingOccurrences(of: "&amp;", with: "&")
            guard let source = URL(string: value), GitHubClient.privateImageURL(for: source) != nil else {
                return String(match.output.0)
            }
            return match.output.1 + SummaryHTML.escape(url(for: source)) + "\""
        }
    }

    nonisolated static func url(for source: URL) -> String {
        var components = URLComponents()
        components.scheme = name
        components.host = "image"
        components.queryItems = [URLQueryItem(name: "src", value: source.absoluteString)]
        return components.string ?? ""
    }

    func webView(_ webView: WKWebView, start task: any WKURLSchemeTask) {
        let id = ObjectIdentifier(task)
        guard let requestURL = task.request.url, let source = AvatarScheme.source(of: requestURL) else {
            task.didFailWithError(URLError(.badURL))
            return
        }
        running.insert(id)
        Task {
            let data: Data
            do {
                if let cached = cache[source] {
                    data = cached
                } else {
                    data = try await fetch(source)
                    cache[source] = data
                }
            } catch {
                if running.remove(id) != nil { task.didFailWithError(error) }
                return
            }
            guard running.remove(id) != nil else { return }
            task.didReceive(URLResponse(url: requestURL, mimeType: AvatarScheme.mimeType(of: data), expectedContentLength: data.count, textEncodingName: nil))
            task.didReceive(data)
            task.didFinish()
        }
    }

    func webView(_ webView: WKWebView, stop task: any WKURLSchemeTask) {
        running.remove(ObjectIdentifier(task))
    }
}
