import Foundation
import PRModels

extension GitHubClient {
    /// Each action is one request. A refused `startReview` costs one more, to find a pending review that already exists.
    @concurrent public func comment(_ action: CommentAction, pullRequestID: String) async throws -> CommentResult {
        let mutation = Self.mutation(for: action, pullRequestID: pullRequestID)
        switch action {
        case .addThread(_, _, review: nil):
            let review = try await send(mutation, as: PublishedThreadPayload.self).pullRequestReview
            guard let thread = review?.pullRequest.reviewThreads.nodes
                .last(where: { $0.comments.nodes.first?.pullRequestReview?.id == review?.id })
            else { throw GitHubError.malformedResponse }
            return .thread(thread.model)
        case .addThread:
            guard let thread = try await send(mutation, as: ThreadPayload.self).thread else { throw GitHubError.malformedResponse }
            return .thread(thread.model)
        case .startReview:
            do {
                guard let review = try await send(mutation, as: ReviewPayload.self).pullRequestReview else {
                    throw GitHubError.malformedResponse
                }
                return .review(id: review.id)
            } catch let GitHubError.rejected(message) {
                guard let id = try await pendingReviewID(pullRequestID: pullRequestID) else { throw GitHubError.rejected(message) }
                return .review(id: id)
            }
        case .reply:
            guard let comment = try await send(mutation, as: ReplyPayload.self).comment else { throw GitHubError.malformedResponse }
            return .comment(comment.model)
        case .edit:
            guard let comment = try await send(mutation, as: EditPayload.self).pullRequestReviewComment else {
                throw GitHubError.malformedResponse
            }
            return .comment(comment.model)
        case .delete, .submitReview, .discardReview:
            _ = try await send(mutation, as: MutationPayload.self)
            return .done
        }
    }

    /// A single comment is a `COMMENT` review with one thread; its payload reads the thread back, as a comment has no thread link.
    static func mutation(for action: CommentAction, pullRequestID: String) -> Mutation {
        let comment = ReviewThreadFields.comment
        switch action {
        case let .addThread(target, body, nil):
            let review = [
                MutationField("pullRequestId", "ID!", .string(pullRequestID)),
                MutationField("event", "PullRequestReviewEvent", .string(PullRequestAction.ReviewEvent.comment.rawValue)),
            ]
            let thread = threadFields(target, body: body)
            return Mutation(
                "addPullRequestReview", review + thread,
                input: "\(Mutation.input(review)), threads: [{\(Mutation.input(thread))}]",
                selection: "pullRequestReview { id pullRequest { reviewThreads(last: 5) { nodes { \(ReviewThreadFields.thread) } } } }"
            )
        case let .addThread(target, body, review?):
            return Mutation(
                "addPullRequestReviewThread",
                [MutationField("pullRequestReviewId", "ID!", .string(review))] + threadFields(target, body: body),
                selection: "thread { \(ReviewThreadFields.thread) }"
            )
        case let .startReview(commitOid):
            return Mutation(
                "addPullRequestReview",
                [
                    MutationField("pullRequestId", "ID!", .string(pullRequestID)),
                    MutationField("commitOID", "GitObjectID", .string(commitOid)),
                ],
                selection: "pullRequestReview { id }"
            )
        case let .reply(thread, body, review):
            return Mutation(
                "addPullRequestReviewThreadReply",
                [MutationField("pullRequestReviewThreadId", "ID!", .string(thread)), MutationField("body", "String!", .string(body))]
                    + (review.map { [MutationField("pullRequestReviewId", "ID", .string($0))] } ?? []),
                selection: "comment { \(comment) }"
            )
        case let .edit(id, body):
            return Mutation(
                "updatePullRequestReviewComment",
                [MutationField("pullRequestReviewCommentId", "ID!", .string(id)), MutationField("body", "String!", .string(body))],
                selection: "pullRequestReviewComment { \(comment) }"
            )
        case let .delete(id):
            return Mutation("deletePullRequestReviewComment", [MutationField("id", "ID!", .string(id))])
        case let .submitReview(review, event, body):
            return Mutation(
                "submitPullRequestReview",
                [
                    MutationField("pullRequestReviewId", "ID!", .string(review)),
                    MutationField("event", "PullRequestReviewEvent!", .string(event.rawValue)),
                ] + (body.isEmpty ? [] : [MutationField("body", "String", .string(body))])
            )
        case let .discardReview(review):
            return Mutation("deletePullRequestReview", [MutationField("pullRequestReviewId", "ID!", .string(review))])
        }
    }

    /// GitHub shows a pending review only to its author, so the first one is the viewer's.
    private func pendingReviewID(pullRequestID: String) async throws -> String? {
        let query = """
        query($id: ID!) {
          node(id: $id) { ... on PullRequest { reviews(states: [PENDING], first: 1) { nodes { id } } } }
        }
        """
        let response = try await graphQL(query, variables: ["id": .string(pullRequestID)], as: PendingReviewPayload.self)
        return response.node?.reviews.nodes.first?.id
    }

    private static func threadFields(_ target: CommentTarget, body: String) -> [MutationField] {
        let side = MutationField("side", "DiffSide", .string(target.side.rawValue))
        let range = target.startLine.map {
            [MutationField("startLine", "Int", .int($0)), MutationField("startSide", "DiffSide", .string(target.side.rawValue))]
        } ?? []
        return [
            MutationField("body", "String!", .string(body)), MutationField("path", "String!", .string(target.path)),
            MutationField("line", "Int!", .int(target.line)), side,
        ] + range
    }
}

private struct PublishedThreadPayload: Decodable {
    struct Review: Decodable {
        struct PullRequest: Decodable { let reviewThreads: Threads }
        struct Threads: Decodable { let nodes: [ThreadsNode.Thread] }
        let id: String
        let pullRequest: PullRequest
    }

    let pullRequestReview: Review?
}

private struct ThreadPayload: Decodable {
    let thread: ThreadsNode.Thread?
}

private struct ReviewPayload: Decodable {
    struct Review: Decodable { let id: String }
    let pullRequestReview: Review?
}

private struct PendingReviewPayload: Decodable {
    struct PullRequest: Decodable {
        struct Reviews: Decodable { let nodes: [ReviewPayload.Review] }
        let reviews: Reviews
    }

    let node: PullRequest?
}

private struct ReplyPayload: Decodable {
    let comment: ThreadsNode.Comment?
}

private struct EditPayload: Decodable {
    let pullRequestReviewComment: ThreadsNode.Comment?
}
