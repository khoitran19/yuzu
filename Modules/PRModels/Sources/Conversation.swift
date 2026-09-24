import Foundation

/// The pull request Conversation page without event rows: comments, reviews, and the head commit checks.
public struct Conversation: Sendable, Equatable, Codable {
    public let items: [TimelineItem]
    public let checks: [Check]

    public init(items: [TimelineItem], checks: [Check]) {
        self.items = items
        self.checks = checks
    }
}

public enum TimelineItem: Sendable, Equatable, Codable {
    case comment(IssueComment)
    case review(Review)

    public var createdAt: Date {
        switch self {
        case let .comment(comment): comment.createdAt
        case let .review(review): review.createdAt
        }
    }
}

public struct Author: Sendable, Equatable, Codable {
    public let actor: Actor
    public let isBot: Bool
    /// GitHub `CommentAuthorAssociation`, for example `MEMBER` or `CONTRIBUTOR`.
    public let association: String

    public init(actor: Actor, isBot: Bool, association: String) {
        self.actor = actor
        self.isBot = isBot
        self.association = association
    }
}

public struct IssueComment: Sendable, Equatable, Codable, Identifiable {
    public let id: String
    public let author: Author?
    public let bodyHTML: String
    public let createdAt: Date
    public let url: URL?
    /// GitHub `ReportedContentClassifiers` value; `nil` when the comment is not hidden.
    public let minimizedReason: String?

    public init(id: String, author: Author?, bodyHTML: String, createdAt: Date, url: URL?, minimizedReason: String?) {
        self.id = id
        self.author = author
        self.bodyHTML = bodyHTML
        self.createdAt = createdAt
        self.url = url
        self.minimizedReason = minimizedReason
    }
}

public struct Review: Sendable, Equatable, Codable, Identifiable {
    public enum State: String, Sendable, Codable {
        case approved = "APPROVED"
        case changesRequested = "CHANGES_REQUESTED"
        case commented = "COMMENTED"
        case dismissed = "DISMISSED"
        case pending = "PENDING"
    }

    public let id: String
    public let author: Author?
    public let state: State
    public let bodyHTML: String
    public let createdAt: Date
    public let url: URL?
    public let comments: [InlineComment]

    public init(
        id: String, author: Author?, state: State, bodyHTML: String, createdAt: Date, url: URL?, comments: [InlineComment]
    ) {
        self.id = id
        self.author = author
        self.state = state
        self.bodyHTML = bodyHTML
        self.createdAt = createdAt
        self.url = url
        self.comments = comments
    }
}

/// A review comment on a diff line, as the Conversation page shows it.
public struct InlineComment: Sendable, Equatable, Codable, Identifiable {
    public let id: String
    public let author: Author?
    public let bodyHTML: String
    public let createdAt: Date
    public let path: String
    public let diffHunk: String
    /// The first comment of the thread; GitHub points every reply at it.
    public let replyToID: String?
    public let isOutdated: Bool

    public init(
        id: String, author: Author?, bodyHTML: String, createdAt: Date, path: String, diffHunk: String,
        replyToID: String?, isOutdated: Bool
    ) {
        self.id = id
        self.author = author
        self.bodyHTML = bodyHTML
        self.createdAt = createdAt
        self.path = path
        self.diffHunk = diffHunk
        self.replyToID = replyToID
        self.isOutdated = isOutdated
    }
}

public struct Check: Sendable, Equatable, Codable {
    public enum State: String, Sendable, Codable {
        case success, failure, pending, skipped, neutral, cancelled
    }

    public let name: String
    /// The workflow name for GitHub Actions jobs.
    public let workflow: String?
    /// The workflow trigger, for example `pull_request`.
    public let event: String?
    public let state: State
    public let summary: String?
    public let url: URL?
    public let avatarURL: URL?
    public let isRequired: Bool
    public let startedAt: Date?
    public let completedAt: Date?

    public init(
        name: String, workflow: String?, event: String?, state: State, summary: String?, url: URL?, avatarURL: URL?,
        isRequired: Bool, startedAt: Date?, completedAt: Date?
    ) {
        self.name = name
        self.workflow = workflow
        self.event = event
        self.state = state
        self.summary = summary
        self.url = url
        self.avatarURL = avatarURL
        self.isRequired = isRequired
        self.startedAt = startedAt
        self.completedAt = completedAt
    }
}
