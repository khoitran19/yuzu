import Foundation
import PRModels

extension GitHubClient {
    /// Comments and reviews only; event rows such as commits, labels, and deployments are not requested.
    public func conversation(of ref: PRRef) async throws -> Conversation {
        async let items = timelineItems(ref)
        async let status = status(of: ref)
        let current = try await status
        return Conversation(items: try await items, checks: current.checks, merge: current.merge)
    }

    private func timelineItems(_ ref: PRRef) async throws -> [TimelineItem] {
        var items: [TimelineItem] = []
        var cursor: String?
        repeat {
            var variables = ref.variables
            variables["cursor"] = cursor.map(JSONValue.string) ?? .null
            let response = try await graphQL(ConversationQueries.timeline, variables: variables, as: RepositoryPayload<TimelineNode>.self)
            guard let page = response.repository?.pullRequest?.timelineItems else { throw GitHubError.notFound }
            items += page.nodes.compactMap(\.model)
            cursor = page.pageInfo.hasNextPage ? page.pageInfo.endCursor : nil
        } while cursor != nil
        return items
    }

    /// Page 1 also carries the merge box fields; later pages carry only checks.
    public func status(of ref: PRRef) async throws -> PullRequestStatus {
        var checks: [Check] = []
        var merge: MergeStatus?
        var cursor: String?
        repeat {
            var variables = ref.variables
            variables["cursor"] = cursor.map(JSONValue.string) ?? .null
            variables["first"] = .bool(cursor == nil)
            let response = try await graphQL(ConversationQueries.status, variables: variables, as: StatusPayload.self)
            guard let repository = response.repository, let pullRequest = repository.pullRequest else { throw GitHubError.notFound }
            if cursor == nil { merge = repository.mergeStatus }
            guard let contexts = pullRequest.commits.nodes.first?.commit.statusCheckRollup?.contexts else { break }
            checks += contexts.nodes.compactMap(\.model)
            cursor = contexts.pageInfo.hasNextPage ? contexts.pageInfo.endCursor : nil
        } while cursor != nil
        return PullRequestStatus(checks: checks, merge: merge)
    }
}

private enum ConversationQueries {
    static let timeline = """
    query($owner: String!, $name: String!, $number: Int!, $cursor: String) {
      repository(owner: $owner, name: $name) {
        pullRequest(number: $number) {
          timelineItems(first: 100, after: $cursor, itemTypes: [ISSUE_COMMENT, PULL_REQUEST_REVIEW]) {
            pageInfo { hasNextPage endCursor }
            nodes {
              __typename
              ... on IssueComment {
                id bodyHTML createdAt url isMinimized minimizedReason authorAssociation
                author { ...author }
              }
              ... on PullRequestReview {
                id state bodyHTML createdAt submittedAt url authorAssociation
                author { ...author }
                comments(first: 100) {
                  nodes {
                    id bodyHTML createdAt path diffHunk outdated authorAssociation
                    replyTo { id }
                    author { ...author }
                  }
                }
              }
            }
          }
        }
      }
    }
    fragment author on Actor { __typename login avatarUrl(size: 80) }
    """

    static let status = """
    query($owner: String!, $name: String!, $number: Int!, $cursor: String, $first: Boolean!) {
      repository(owner: $owner, name: $name) {
        ...repository @include(if: $first)
        pullRequest(number: $number) {
          ...merge @include(if: $first)
          commits(last: 1) {
            nodes {
              commit {
                statusCheckRollup {
                  contexts(first: 100, after: $cursor) {
                    pageInfo { hasNextPage endCursor }
                    nodes {
                      __typename
                      ... on CheckRun {
                        name status conclusion detailsUrl startedAt completedAt
                        isRequired(pullRequestNumber: $number)
                        checkSuite { app { logoUrl(size: 40) } workflowRun { event workflow { name } } }
                      }
                      ... on StatusContext {
                        context state description targetUrl avatarUrl(size: 40)
                        isRequired(pullRequestNumber: $number)
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
    fragment repository on Repository {
      viewerPermission mergeCommitAllowed squashMergeAllowed rebaseMergeAllowed viewerDefaultMergeMethod autoMergeAllowed
    }
    fragment merge on PullRequest {
      state isDraft headRefOid mergeable mergeStateStatus reviewDecision
      viewerDidAuthor viewerCanUpdate viewerCanMergeAsAdmin viewerCanEnableAutoMerge viewerCanDisableAutoMerge
      viewerLatestReview { state }
      isMergeQueueEnabled
      mergeQueueEntry { position state estimatedTimeToMerge enqueuedAt }
      mergeQueue { url entries { totalCount } }
      autoMergeRequest { mergeMethod enabledBy { login } }
    }
    """
}

private struct TimelineAuthor: Decodable {
    let __typename: String
    let login: String
    let avatarUrl: String?

    func model(association: String?) -> Author {
        Author(
            actor: Actor(login: login, avatarURL: avatarUrl.flatMap(URL.init(string:))),
            isBot: __typename == "Bot", association: association ?? "NONE"
        )
    }
}

private struct TimelineNode: Decodable {
    struct Items: Decodable {
        let pageInfo: PageInfo
        let nodes: [Item]
    }

    struct ReplyTo: Decodable { let id: String }

    struct Comment: Decodable {
        let id: String
        let bodyHTML: String
        let createdAt: Date
        let path: String
        let diffHunk: String
        let outdated: Bool
        let authorAssociation: String?
        let replyTo: ReplyTo?
        let author: TimelineAuthor?
    }

    struct Comments: Decodable { let nodes: [Comment] }

    /// One struct for both item types; fields of the other type decode as `nil`.
    struct Item: Decodable {
        let __typename: String
        let id: String?
        let bodyHTML: String?
        let createdAt: Date?
        let submittedAt: Date?
        let url: String?
        let isMinimized: Bool?
        let minimizedReason: String?
        let authorAssociation: String?
        let author: TimelineAuthor?
        let state: String?
        let comments: Comments?

        var model: TimelineItem? {
            guard let id, let bodyHTML, let createdAt else { return nil }
            let author = author?.model(association: authorAssociation)
            let url = url.flatMap(URL.init(string:))
            switch __typename {
            case "IssueComment":
                return .comment(IssueComment(
                    id: id, author: author, bodyHTML: bodyHTML, createdAt: createdAt, url: url,
                    minimizedReason: isMinimized == true ? (minimizedReason ?? "hidden") : nil
                ))
            case "PullRequestReview":
                guard let state = state.flatMap(Review.State.init(rawValue:)), state != .pending else { return nil }
                return .review(Review(
                    id: id, author: author, state: state, bodyHTML: bodyHTML, createdAt: submittedAt ?? createdAt, url: url,
                    comments: (comments?.nodes ?? []).map { comment in
                        InlineComment(
                            id: comment.id, author: comment.author?.model(association: comment.authorAssociation),
                            bodyHTML: comment.bodyHTML, createdAt: comment.createdAt, path: comment.path,
                            diffHunk: comment.diffHunk, replyToID: comment.replyTo?.id, isOutdated: comment.outdated
                        )
                    }
                ))
            default:
                return nil
            }
        }
    }

    let timelineItems: Items
}

/// The merge fields decode as `nil` on pages after the first.
private struct StatusPayload: Decodable {
    struct Repository: Decodable {
        let viewerPermission: String?
        let mergeCommitAllowed: Bool?
        let squashMergeAllowed: Bool?
        let rebaseMergeAllowed: Bool?
        let viewerDefaultMergeMethod: String?
        let autoMergeAllowed: Bool?
        let pullRequest: StatusNode?

        var mergeStatus: MergeStatus? {
            guard let node = pullRequest, let state = node.state.flatMap(PullRequest.State.init(rawValue:)), let headOid = node.headRefOid
            else { return nil }
            let allowed: [(MergeMethod, Bool?)] = [
                (.merge, mergeCommitAllowed), (.squash, squashMergeAllowed), (.rebase, rebaseMergeAllowed),
            ]
            return MergeStatus(
                state: state, isDraft: node.isDraft ?? false, headOid: headOid,
                mergeable: node.mergeable.flatMap(MergeStatus.Mergeable.init(rawValue:)) ?? .unknown,
                mergeStateStatus: node.mergeStateStatus.flatMap(MergeStatus.StateStatus.init(rawValue:)) ?? .unknown,
                reviewDecision: node.reviewDecision.flatMap(PullRequestSummary.ReviewDecision.init(rawValue:)),
                viewerDidAuthor: node.viewerDidAuthor ?? false, viewerCanUpdate: node.viewerCanUpdate ?? false,
                viewerCanMerge: ["ADMIN", "MAINTAIN", "WRITE"].contains(viewerPermission ?? ""),
                viewerCanMergeAsAdmin: node.viewerCanMergeAsAdmin ?? false,
                viewerCanEnableAutoMerge: node.viewerCanEnableAutoMerge ?? false,
                viewerCanDisableAutoMerge: node.viewerCanDisableAutoMerge ?? false,
                viewerReviewState: node.viewerLatestReview.flatMap { Review.State(rawValue: $0.state) },
                allowedMethods: allowed.compactMap { $1 == true ? $0 : nil },
                defaultMethod: viewerDefaultMergeMethod.flatMap(MergeMethod.init(rawValue:)) ?? .merge,
                autoMergeAllowed: autoMergeAllowed ?? false, isMergeQueueEnabled: node.isMergeQueueEnabled ?? false,
                queueEntry: node.mergeQueueEntry.map { entry in
                    MergeStatus.QueueEntry(
                        position: entry.position, totalCount: node.mergeQueue?.entries?.totalCount,
                        state: MergeStatus.QueueEntry.State(rawValue: entry.state) ?? .queued,
                        estimatedSecondsToMerge: entry.estimatedTimeToMerge, enqueuedAt: entry.enqueuedAt
                    )
                },
                mergeQueueURL: node.mergeQueue?.url.flatMap(URL.init(string:)),
                autoMerge: node.autoMergeRequest.map { request in
                    MergeStatus.AutoMerge(method: MergeMethod(rawValue: request.mergeMethod) ?? .merge, enabledBy: request.enabledBy?.login)
                }
            )
        }
    }

    let repository: Repository?
}

private struct StatusNode: Decodable {
    struct LatestReview: Decodable { let state: String }
    struct QueueEntry: Decodable {
        let position: Int
        let state: String
        let estimatedTimeToMerge: Int?
        let enqueuedAt: Date?
    }
    struct Queue: Decodable {
        struct Entries: Decodable { let totalCount: Int }
        let url: String?
        let entries: Entries?
    }
    struct AutoMergeRequest: Decodable {
        struct Login: Decodable { let login: String }
        let mergeMethod: String
        let enabledBy: Login?
    }

    let state: String?
    let isDraft: Bool?
    let headRefOid: String?
    let mergeable: String?
    let mergeStateStatus: String?
    let reviewDecision: String?
    let viewerDidAuthor: Bool?
    let viewerCanUpdate: Bool?
    let viewerCanMergeAsAdmin: Bool?
    let viewerCanEnableAutoMerge: Bool?
    let viewerCanDisableAutoMerge: Bool?
    let viewerLatestReview: LatestReview?
    let isMergeQueueEnabled: Bool?
    let mergeQueueEntry: QueueEntry?
    let mergeQueue: Queue?
    let autoMergeRequest: AutoMergeRequest?
    let commits: ChecksNode.Commits
}

private struct ChecksNode: Decodable {
    struct Commits: Decodable { let nodes: [CommitNode] }
    struct CommitNode: Decodable { let commit: Commit }
    struct Commit: Decodable { let statusCheckRollup: Rollup? }
    struct Rollup: Decodable { let contexts: Contexts }

    struct Contexts: Decodable {
        let pageInfo: PageInfo
        let nodes: [Context]
    }

    struct CheckSuite: Decodable {
        struct App: Decodable { let logoUrl: String? }
        struct WorkflowRun: Decodable {
            struct Workflow: Decodable { let name: String }
            let event: String?
            let workflow: Workflow?
        }

        let app: App?
        let workflowRun: WorkflowRun?
    }

    /// One struct for `CheckRun` and `StatusContext`; fields of the other type decode as `nil`.
    struct Context: Decodable {
        let __typename: String
        let name: String?
        let status: String?
        let conclusion: String?
        let detailsUrl: String?
        let startedAt: Date?
        let completedAt: Date?
        let checkSuite: CheckSuite?
        let context: String?
        let state: String?
        let description: String?
        let targetUrl: String?
        let avatarUrl: String?
        let isRequired: Bool?

        var model: Check? {
            switch __typename {
            case "CheckRun":
                guard let name else { return nil }
                return Check(
                    name: name, workflow: checkSuite?.workflowRun?.workflow?.name, event: checkSuite?.workflowRun?.event,
                    state: status == "COMPLETED" ? Self.state(conclusion: conclusion) : .pending, summary: nil,
                    url: detailsUrl.flatMap(URL.init(string:)), avatarURL: checkSuite?.app?.logoUrl.flatMap(URL.init(string:)),
                    isRequired: isRequired ?? false, startedAt: startedAt, completedAt: completedAt
                )
            case "StatusContext":
                guard let context else { return nil }
                let state: Check.State = switch self.state {
                case "SUCCESS": .success
                case "FAILURE", "ERROR": .failure
                default: .pending
                }
                return Check(
                    name: context, workflow: nil, event: nil, state: state, summary: description,
                    url: targetUrl.flatMap(URL.init(string:)), avatarURL: avatarUrl.flatMap(URL.init(string:)),
                    isRequired: isRequired ?? false, startedAt: nil, completedAt: nil
                )
            default:
                return nil
            }
        }

        private static func state(conclusion: String?) -> Check.State {
            switch conclusion {
            case "SUCCESS": .success
            case "SKIPPED": .skipped
            case "CANCELLED": .cancelled
            case "NEUTRAL", "STALE": .neutral
            default: .failure
            }
        }
    }

    let commits: Commits
}
