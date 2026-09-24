import Foundation
import Synchronization

/// Routes each request by its `client_id` form field, so tests can run in parallel.
nonisolated final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    struct Response {
        let status: Int
        let json: String
    }

    struct Recorded {
        let url: URL
        let headers: [String: String]
        let form: [String: String]
    }

    private struct Route {
        var responses: [String: [Response]]
        var requests: [Recorded] = []
    }

    private static let routes = Mutex<[String: Route]>([:])

    static func session(clientID: String, responses: [String: [Response]]) -> URLSession {
        routes.withLock { $0[clientID] = Route(responses: responses) }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    static func requests(clientID: String) -> [Recorded] {
        routes.withLock { $0[clientID]?.requests ?? [] }
    }

    override class func canInit(with _: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let form = Self.form(from: request)
        let url = request.url!
        let clientID = form["client_id"] ?? ""
        let response: Response? = Self.routes.withLock { routes in
            routes[clientID]?.requests.append(Recorded(url: url, headers: request.allHTTPHeaderFields ?? [:], form: form))
            guard var queue = routes[clientID]?.responses[url.path], !queue.isEmpty else { return nil }
            let next = queue.count > 1 ? queue.removeFirst() : queue[0]
            routes[clientID]?.responses[url.path] = queue
            return next
        }
        guard let response else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let http = HTTPURLResponse(url: url, statusCode: response.status, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(response.json.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func form(from request: URLRequest) -> [String: String] {
        var body = request.httpBody ?? Data()
        if body.isEmpty, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var buffer = [UInt8](repeating: 0, count: 4_096)
            while stream.hasBytesAvailable {
                let count = stream.read(&buffer, maxLength: buffer.count)
                guard count > 0 else { break }
                body.append(buffer, count: count)
            }
        }
        var components = URLComponents()
        components.percentEncodedQuery = String(decoding: body, as: UTF8.self)
        return Dictionary((components.queryItems ?? []).map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { _, last in last })
    }
}
