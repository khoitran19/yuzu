import Foundation
import PRModels

public enum GitHubError: Error, LocalizedError, Equatable {
    case unauthorized
    case notFound
    case http(status: Int, message: String)
    case graphQL(String)
    case malformedResponse

    public var errorDescription: String? {
        switch self {
        case .unauthorized: "GitHub rejected the token. Sign in again."
        case .notFound: "GitHub cannot find this pull request, or your token cannot read the repository."
        case let .http(status, message): "GitHub returned \(status): \(message)"
        case let .graphQL(message): "GitHub GraphQL error: \(message)"
        case .malformedResponse: "GitHub returned a response the app cannot read."
        }
    }
}

public struct GitHubClient: Sendable {
    private let token: String
    private let session: URLSession
    private static let api = URL(string: "https://api.github.com")!

    public init(token: String, session: URLSession = .shared) {
        self.token = token
        self.session = session
    }

    public func viewer() async throws -> Actor {
        let data = try await rest(path: "/user")
        let user = try JSONDecoder().decode(RESTUser.self, from: data)
        return Actor(login: user.login, avatarURL: URL(string: user.avatar_url))
    }

    // MARK: REST

    func rest(path: String, query: [URLQueryItem] = [], accept: String = "application/vnd.github+json") async throws -> Data {
        var components = URLComponents(url: Self.api.appending(path: path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }
        var request = URLRequest(url: components.url!)
        request.setValue(accept, forHTTPHeaderField: "Accept")
        return try await send(request)
    }

    // MARK: GraphQL

    func graphQL<Response: Decodable>(_ query: String, variables: [String: JSONValue], as _: Response.Type) async throws -> Response {
        var request = URLRequest(url: Self.api.appending(path: "/graphql"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(GraphQLRequest(query: query, variables: variables))
        let data = try await send(request)
        let envelope = try Self.decoder.decode(GraphQLEnvelope<Response>.self, from: data)
        if let errors = envelope.errors, !errors.isEmpty {
            if errors.contains(where: { $0.type == "NOT_FOUND" }) { throw GitHubError.notFound }
            throw GitHubError.graphQL(errors.map(\.message).joined(separator: "; "))
        }
        guard let payload = envelope.data else { throw GitHubError.malformedResponse }
        return payload
    }

    private func send(_ request: URLRequest) async throws -> Data {
        var request = request
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GitHubError.malformedResponse }
        switch http.statusCode {
        case 200..<300: return data
        case 401: throw GitHubError.unauthorized
        case 404: throw GitHubError.notFound
        default:
            let message = (try? JSONDecoder().decode(RESTError.self, from: data))?.message
                ?? String(decoding: data.prefix(200), as: UTF8.self)
            throw GitHubError.http(status: http.statusCode, message: message)
        }
    }

    static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
}

enum JSONValue: Encodable, Sendable {
    case string(String)
    case int(Int)
    case null

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value): try container.encode(value)
        case let .int(value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

private struct GraphQLRequest: Encodable {
    let query: String
    let variables: [String: JSONValue]
}

private struct GraphQLEnvelope<Payload: Decodable>: Decodable {
    let data: Payload?
    let errors: [GraphQLError]?
}

private struct GraphQLError: Decodable {
    let message: String
    let type: String?
}

private struct RESTError: Decodable {
    let message: String
}

private struct RESTUser: Decodable {
    let login: String
    let avatar_url: String
}
