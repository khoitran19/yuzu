import Foundation
import PRModels

extension GitHubClient {
    static let pullRequestListPageSize = 50
    static let pullRequestListLimit = 100

    @concurrent public func openPullRequests(in repo: RepoRef, scope: PullRequestListScope) async throws -> PullRequestList {
        let author = scope == .mine ? "author:@me" : "-author:@me"
        let query = "repo:\(repo.displayName) is:pr is:open \(author) sort:updated-desc"
        var pullRequests: [PullRequestSummary] = []
        var totalCount = 0
        var cursor: String?
        repeat {
            let variables: [String: JSONValue] = [
                "query": .string(query), "first": .int(Self.pullRequestListPageSize), "cursor": cursor.map(JSONValue.string) ?? .null,
            ]
            let search = try await graphQL(PullRequestListQueries.search, variables: variables, as: SearchPayload.self).search
            totalCount = search.issueCount
            pullRequests += search.nodes.compactMap(\.model)
            cursor = search.pageInfo.hasNextPage ? search.pageInfo.endCursor : nil
        } while cursor != nil && pullRequests.count < Self.pullRequestListLimit
        return PullRequestList(pullRequests: Array(pullRequests.prefix(Self.pullRequestListLimit)), totalCount: totalCount)
    }
}

private enum PullRequestListQueries {
    static let search = """
        query($query: String!, $first: Int!, $cursor: String) {
          search(type: ISSUE, query: $query, first: $first, after: $cursor) {
            issueCount
            pageInfo { hasNextPage endCursor }
            nodes {
              ... on PullRequest {
                number title isDraft updatedAt totalCommentsCount reviewDecision
                repository { name owner { login } }
                author { login avatarUrl(size: 80) }
                commits(last: 1) { nodes { commit { statusCheckRollup { state } } } }
              }
            }
          }
        }
        """
}

private struct SearchPayload: Decodable {
    struct Search: Decodable {
        let issueCount: Int
        let pageInfo: PageInfo
        let nodes: [Node]
    }

    let search: Search
}

/// Search results other than pull requests decode with every field `nil`.
private struct Node: Decodable {
    struct Repository: Decodable {
        struct Owner: Decodable { let login: String }
        let name: String
        let owner: Owner
    }

    struct Commits: Decodable {
        struct CommitNode: Decodable { let commit: Commit }
        struct Commit: Decodable { let statusCheckRollup: Rollup? }
        struct Rollup: Decodable { let state: String }
        let nodes: [CommitNode]
    }

    let number: Int?
    let title: String?
    let isDraft: Bool?
    let updatedAt: Date?
    let totalCommentsCount: Int?
    let reviewDecision: String?
    let repository: Repository?
    let author: AuthorNode?
    let commits: Commits?

    var model: PullRequestSummary? {
        guard let number, let title, let updatedAt, let repository else { return nil }
        return PullRequestSummary(
            ref: PRRef(owner: repository.owner.login, repo: repository.name, number: number),
            title: title, isDraft: isDraft ?? false, author: author?.actor, updatedAt: updatedAt,
            commentCount: totalCommentsCount ?? 0,
            checks: commits?.nodes.first?.commit.statusCheckRollup.flatMap { Self.checks(state: $0.state) },
            reviewDecision: reviewDecision.flatMap(PullRequestSummary.ReviewDecision.init(rawValue:))
        )
    }

    private static func checks(state: String) -> PullRequestSummary.ChecksState? {
        switch state {
        case "SUCCESS": .success
        case "FAILURE", "ERROR": .failure
        case "PENDING", "EXPECTED": .pending
        default: nil
        }
    }
}
