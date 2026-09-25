import Foundation
import PRModels

extension GitHubClient {
    public func perform(_ action: PullRequestAction, pullRequestID: String) async throws {
        let (field, fields) = Self.mutation(for: action, pullRequestID: pullRequestID)
        _ = try await send(Mutation(field, fields), as: MutationPayload.self)
    }

    /// Throws `GitHubError.rejected` with GitHub's messages when the response has errors.
    func send<Payload: Decodable>(_ mutation: Mutation, as _: Payload.Type) async throws -> Payload {
        let envelope = try await graphQLEnvelope(mutation.document, variables: mutation.variables, as: [String: Payload?].self)
        guard envelope.errors.isEmpty else { throw GitHubError.rejected(envelope.errors.map(\.message).joined(separator: " ")) }
        guard let payload = envelope.data?[mutation.field] ?? nil else { throw GitHubError.malformedResponse }
        return payload
    }

    /// Input fields with a `nil` value are left out, so GitHub uses the repository default.
    static func mutation(for action: PullRequestAction, pullRequestID: String) -> (field: String, input: [MutationField]) {
        let id = MutationField("pullRequestId", "ID!", .string(pullRequestID))
        func optional(_ name: String, _ value: String?) -> [MutationField] {
            value.map { [MutationField(name, "String", .string($0))] } ?? []
        }
        switch action {
        case let .review(event, body):
            return (
                "addPullRequestReview",
                [id, MutationField("event", "PullRequestReviewEvent", .string(event.rawValue))]
                    + optional("body", body.isEmpty ? nil : body)
            )
        case let .merge(method, headOid, title, body):
            return (
                "mergePullRequest",
                [
                    id, MutationField("mergeMethod", "PullRequestMergeMethod", .string(method.rawValue)),
                    MutationField("expectedHeadOid", "GitObjectID", .string(headOid)),
                ] + optional("commitHeadline", title) + optional("commitBody", body)
            )
        case let .enableAutoMerge(method, headOid):
            return (
                "enablePullRequestAutoMerge",
                [
                    id, MutationField("mergeMethod", "PullRequestMergeMethod", .string(method.rawValue)),
                    MutationField("expectedHeadOid", "GitObjectID", .string(headOid)),
                ]
            )
        case .disableAutoMerge:
            return ("disablePullRequestAutoMerge", [id])
        case let .enqueue(headOid):
            return ("enqueuePullRequest", [id, MutationField("expectedHeadOid", "GitObjectID", .string(headOid))])
        case .dequeue:
            // `DequeuePullRequestInput` names the pull request `id`, not `pullRequestId`.
            return ("dequeuePullRequest", [MutationField("id", "ID!", .string(pullRequestID))])
        case .markReadyForReview:
            return ("markPullRequestReadyForReview", [id])
        case .convertToDraft:
            return ("convertPullRequestToDraft", [id])
        }
    }
}

struct MutationField {
    let name: String
    let type: String
    let value: JSONValue

    init(_ name: String, _ type: String, _ value: JSONValue) {
        self.name = name
        self.type = type
        self.value = value
    }
}

struct Mutation {
    let field: String
    let fields: [MutationField]
    let input: String
    let selection: String

    /// `input` defaults to each field set from its variable.
    init(_ field: String, _ fields: [MutationField], input: String? = nil, selection: String = "clientMutationId") {
        self.field = field
        self.fields = fields
        self.input = input ?? Self.input(fields)
        self.selection = selection
    }

    static func input(_ fields: [MutationField]) -> String {
        fields.map { "\($0.name): $\($0.name)" }.joined(separator: ", ")
    }

    var document: String {
        let declarations = fields.map { "$\($0.name): \($0.type)" }.joined(separator: ", ")
        return "mutation(\(declarations)) {\n  \(field)(input: {\(input)}) { \(selection) }\n}"
    }

    var variables: [String: JSONValue] {
        Dictionary(uniqueKeysWithValues: fields.map { ($0.name, $0.value) })
    }
}

struct MutationPayload: Decodable {}
