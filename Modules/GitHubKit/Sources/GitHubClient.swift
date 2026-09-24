import Foundation
import PRModels

public enum GitHubError: Error, LocalizedError, Equatable {
    case unauthorized
    case notFound
    case http(status: Int, message: String)
    case graphQL(String)
    case malformedResponse
    case partialFailure(paths: [String])
    /// GitHub refused a change, for example a merge that branch rules block.
    case rejected(String)

    public var errorDescription: String? {
        switch self {
        case .unauthorized: "GitHub rejected the token. Sign in again."
        case .notFound: "GitHub cannot find this pull request, or your token cannot read the repository."
        case let .http(status, message): "GitHub returned \(status): \(message)"
        case let .graphQL(message): "GitHub GraphQL error: \(message)"
        case .malformedResponse: "GitHub returned a response the app cannot read."
        case let .partialFailure(paths):
            "GitHub did not update \(paths.count) of the files: \(paths.joined(separator: ", "))"
        case let .rejected(message): message
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
        try await restResponse(path: path, query: query, accept: accept).data
    }

    func restResponse(
        path: String, query: [URLQueryItem] = [], accept: String = "application/vnd.github+json"
    ) async throws -> (data: Data, response: HTTPURLResponse) {
        var components = URLComponents(url: Self.api.appending(path: path), resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }
        var request = URLRequest(url: components.url!)
        request.setValue(accept, forHTTPHeaderField: "Accept")
        return try await sendResponse(request)
    }

    // MARK: GraphQL

    func graphQL<Response: Decodable>(_ query: String, variables: [String: JSONValue], as type: Response.Type) async throws -> Response {
        let envelope = try await graphQLEnvelope(query, variables: variables, as: type)
        if !envelope.errors.isEmpty { throw Self.error(for: envelope.errors) }
        guard let payload = envelope.data else { throw GitHubError.malformedResponse }
        return payload
    }

    func graphQLEnvelope<Response: Decodable>(
        _ query: String, variables: [String: JSONValue], as _: Response.Type
    ) async throws -> GraphQLEnvelope<Response> {
        var request = URLRequest(url: Self.api.appending(path: "/graphql"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(GraphQLRequest(query: query, variables: variables))
        let data = try await send(request)
        return try Self.decoder.decode(GraphQLEnvelope<Response>.self, from: data)
    }

    static func error(for errors: [GraphQLError]) -> GitHubError {
        if errors.contains(where: { $0.type == "NOT_FOUND" }) { return .notFound }
        return .graphQL(errors.map(\.message).joined(separator: "; "))
    }

    private func send(_ request: URLRequest) async throws -> Data {
        try await sendResponse(request).data
    }

    private func sendResponse(_ request: URLRequest) async throws -> (data: Data, response: HTTPURLResponse) {
        var request = request
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw GitHubError.malformedResponse }
        switch http.statusCode {
        case 200..<300: return (data, http)
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
    case bool(Bool)
    case null

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .string(value): try container.encode(value)
        case let .int(value): try container.encode(value)
        case let .bool(value): try container.encode(value)
        case .null: try container.encodeNil()
        }
    }
}

private struct GraphQLRequest: Encodable {
    let query: String
    let variables: [String: JSONValue]
}

struct GraphQLEnvelope<Payload: Decodable>: Decodable {
    let data: Payload?
    let errors: [GraphQLError]

    private enum CodingKeys: String, CodingKey { case data, errors }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        data = try container.decodeIfPresent(Payload.self, forKey: .data)
        errors = try container.decodeIfPresent([GraphQLError].self, forKey: .errors) ?? []
    }
}

struct GraphQLError: Decodable {
    enum PathElement: Decodable {
        case key(String)
        case index(Int)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let index = try? container.decode(Int.self) {
                self = .index(index)
            } else {
                self = .key(try container.decode(String.self))
            }
        }
    }

    let message: String
    let type: String?
    let path: [PathElement]?
}

private struct RESTError: Decodable {
    let message: String
}

private struct RESTUser: Decodable {
    let login: String
    let avatar_url: String
}
