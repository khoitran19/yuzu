import Foundation
import Synchronization

/// Routes each request by its bearer token, so tests can run in parallel.
nonisolated final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    struct Request: Sendable {
        let url: URL
        let body: Data
    }

    typealias Handler = @Sendable (Request) throws -> String

    private struct Route {
        let handler: Handler
        var requests: [Request] = []
    }

    private static let routes = Mutex<[String: Route]>([:])

    static func session(token: String, handler: @escaping Handler) -> URLSession {
        routes.withLock { $0[token] = Route(handler: handler) }
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: configuration)
    }

    static func requests(token: String) -> [Request] {
        routes.withLock { $0[token]?.requests ?? [] }
    }

    override class func canInit(with _: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let token = request.value(forHTTPHeaderField: "Authorization")?.replacingOccurrences(of: "Bearer ", with: "") ?? ""
        let recorded = Request(url: request.url!, body: Self.body(of: request))
        let handler = Self.routes.withLock { routes -> Handler? in
            routes[token]?.requests.append(recorded)
            return routes[token]?.handler
        }
        guard let handler, let json = try? handler(recorded) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        let http = HTTPURLResponse(
            url: recorded.url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(json.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func body(of request: URLRequest) -> Data {
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
        return body
    }
}
