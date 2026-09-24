import Foundation

public struct RepoRef: Hashable, Sendable, Codable {
    public let owner: String
    public let name: String

    public init(owner: String, name: String) {
        self.owner = owner
        self.name = name
    }

    public init(_ ref: PRRef) {
        self.init(owner: ref.owner, name: ref.repo)
    }

    public var displayName: String { "\(owner)/\(name)" }
}

/// Which open pull requests of a repository to list, by author.
public enum PullRequestListScope: String, Sendable, Hashable, CaseIterable, Codable {
    case mine
    case others
}

/// One row of the open pull request list.
public struct PullRequestSummary: Sendable, Equatable, Identifiable, Codable {
    /// GitHub `StatusState` of the head commit, reduced to the three icons the list shows.
    public enum ChecksState: String, Sendable, Codable {
        case success, failure, pending
    }

    public enum ReviewDecision: String, Sendable, Codable {
        case approved = "APPROVED"
        case changesRequested = "CHANGES_REQUESTED"
        case reviewRequired = "REVIEW_REQUIRED"
    }

    public var id: PRRef { ref }
    public let ref: PRRef
    public let title: String
    public let isDraft: Bool
    public let author: Actor?
    public let updatedAt: Date
    public let commentCount: Int
    public let checks: ChecksState?
    public let reviewDecision: ReviewDecision?

    public init(
        ref: PRRef, title: String, isDraft: Bool, author: Actor?, updatedAt: Date, commentCount: Int,
        checks: ChecksState?, reviewDecision: ReviewDecision?
    ) {
        self.ref = ref
        self.title = title
        self.isDraft = isDraft
        self.author = author
        self.updatedAt = updatedAt
        self.commentCount = commentCount
        self.checks = checks
        self.reviewDecision = reviewDecision
    }
}

public struct PullRequestList: Sendable, Equatable {
    public let pullRequests: [PullRequestSummary]
    /// All matches on GitHub; can be more than `pullRequests.count`.
    public let totalCount: Int

    public init(pullRequests: [PullRequestSummary], totalCount: Int) {
        self.pullRequests = pullRequests
        self.totalCount = totalCount
    }
}
