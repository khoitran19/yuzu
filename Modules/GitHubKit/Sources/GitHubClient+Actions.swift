import Foundation
import PRModels

extension GitHubClient {
    public func perform(_ action: PullRequestAction, pullRequestID: String) async throws {
        let (field, fields) = Self.mutation(for: action, pullRequestID: pullRequestID)
        let declarations = fields.map { "$\($0.name): \($0.type)" }.joined(separator: ", ")
        let input = fields.map { "\($0.name): $\($0.name)" }.joined(separator: ", ")
        let variables = Dictionary(uniqueKeysWithValues: fields.map { ($0.name, $0.value) })
        let envelope = try await graphQLEnvelope(
            "mutation(\(declarations)) {\n  \(field)(input: {\(input)}) { clientMutationId }\n}", variables: variables,
            as: MutationPayload.self
        )
        guard envelope.errors.isEmpty else { throw GitHubError.rejected(envelope.errors.map(\.message).joined(separator: " ")) }
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

private struct MutationPayload: Decodable {}
