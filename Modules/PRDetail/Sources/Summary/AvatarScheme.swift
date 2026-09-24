import Foundation
import WebKit

/// Serves `yuzu-avatar:` image URLs from `AvatarCache`, so the Summary page never downloads an avatar twice.
final class AvatarScheme: NSObject, WKURLSchemeHandler {
    static let name = "yuzu-avatar"

    private let cache: AvatarCache
    private var running: Set<ObjectIdentifier> = []

    init(cache: AvatarCache = .shared) {
        self.cache = cache
    }

    nonisolated static func url(for source: URL) -> String {
        var components = URLComponents()
        components.scheme = name
        components.host = "avatar"
        components.queryItems = [URLQueryItem(name: "src", value: source.absoluteString)]
        return components.string ?? ""
    }

    nonisolated static func source(of url: URL?) -> URL? {
        guard let url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let value = components.queryItems?.first(where: { $0.name == "src" })?.value,
              let source = URL(string: value), source.scheme == "https"
        else { return nil }
        return source
    }

    func webView(_ webView: WKWebView, start task: any WKURLSchemeTask) {
        let id = ObjectIdentifier(task)
        guard let requestURL = task.request.url, let source = Self.source(of: requestURL) else {
            task.didFailWithError(URLError(.badURL))
            return
        }
        running.insert(id)
        Task {
            let data: Data
            do {
                data = try await cache.data(for: source)
            } catch {
                if running.remove(id) != nil { task.didFailWithError(error) }
                return
            }
            // WebKit raises an exception for a callback after `stop`.
            guard running.remove(id) != nil else { return }
            task.didReceive(URLResponse(url: requestURL, mimeType: Self.mimeType(of: data), expectedContentLength: data.count, textEncodingName: nil))
            task.didReceive(data)
            task.didFinish()
        }
    }

    func webView(_ webView: WKWebView, stop task: any WKURLSchemeTask) {
        running.remove(ObjectIdentifier(task))
    }

    private static func mimeType(of data: Data) -> String {
        switch data.first {
        case 0x89: "image/png"
        case 0xFF: "image/jpeg"
        case 0x47: "image/gif"
        case 0x3C: "image/svg+xml"
        default: "image/webp"
        }
    }
}
