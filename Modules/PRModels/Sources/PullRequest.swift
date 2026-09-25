import Foundation

public struct PullRequest: Sendable, Equatable, Codable {
    public enum State: String, Sendable, Codable { case open = "OPEN", closed = "CLOSED", merged = "MERGED" }

    public let nodeID: String
    public let ref: PRRef
    public let title: String
    public var state: State
    public var isDraft: Bool
    public let author: Actor?
    public let bodyHTML: String
    public let baseRefName: String
    public let headRefName: String
    public let baseOid: String
    public let headOid: String
    public let additions: Int
    public let deletions: Int
    public let changedFiles: Int
    public let commitCount: Int
    public let createdAt: Date

    public init(
        nodeID: String, ref: PRRef, title: String, state: State, isDraft: Bool, author: Actor?,
        bodyHTML: String, baseRefName: String, headRefName: String, baseOid: String, headOid: String,
        additions: Int, deletions: Int, changedFiles: Int, commitCount: Int, createdAt: Date
    ) {
        self.nodeID = nodeID
        self.ref = ref
        self.title = title
        self.state = state
        self.isDraft = isDraft
        self.author = author
        self.bodyHTML = bodyHTML
        self.baseRefName = baseRefName
        self.headRefName = headRefName
        self.baseOid = baseOid
        self.headOid = headOid
        self.additions = additions
        self.deletions = deletions
        self.changedFiles = changedFiles
        self.commitCount = commitCount
        self.createdAt = createdAt
    }
}

public struct Actor: Sendable, Equatable, Hashable, Codable {
    public let login: String
    public let avatarURL: URL?

    public init(login: String, avatarURL: URL?) {
        self.login = login
        self.avatarURL = avatarURL
    }
}

public enum ViewedState: String, Sendable, Codable {
    case viewed = "VIEWED"
    case unviewed = "UNVIEWED"
    /// Viewed earlier, then the file changed.
    case dismissed = "DISMISSED"
}

public struct ChangedFile: Sendable, Identifiable, Equatable, Codable {
    public enum Status: String, Sendable, Codable {
        case added, removed, modified, renamed, copied, changed, unchanged
    }

    public var id: String { path }
    public let path: String
    public let previousPath: String?
    public let status: Status
    public let additions: Int
    public let deletions: Int
    /// `nil` when GitHub omits the patch: binary files, renames without changes, and large diffs.
    public let patch: String?
    public var viewedState: ViewedState

    public init(
        path: String, previousPath: String?, status: Status, additions: Int, deletions: Int,
        patch: String?, viewedState: ViewedState
    ) {
        self.path = path
        self.previousPath = previousPath
        self.status = status
        self.additions = additions
        self.deletions = deletions
        self.patch = patch
        self.viewedState = viewedState
    }

    public var isMarkdown: Bool {
        switch (path as NSString).pathExtension.lowercased() {
        case "md", "markdown", "mdown", "mkd": true
        default: false
        }
    }
}

public enum DiffSide: String, Sendable, Codable {
    case left = "LEFT"
    case right = "RIGHT"
}

public struct ReviewThread: Sendable, Identifiable, Equatable, Codable {
    public let id: String
    public let path: String
    /// `nil` when the thread is outdated and GitHub cannot place it on the current diff.
    public let line: Int?
    public let startLine: Int?
    public let side: DiffSide
    public let isResolved: Bool
    public let isOutdated: Bool
    public let comments: [ReviewComment]

    public init(
        id: String, path: String, line: Int?, startLine: Int?, side: DiffSide,
        isResolved: Bool, isOutdated: Bool, comments: [ReviewComment]
    ) {
        self.id = id
        self.path = path
        self.line = line
        self.startLine = startLine
        self.side = side
        self.isResolved = isResolved
        self.isOutdated = isOutdated
        self.comments = comments
    }
}

public struct ReviewComment: Sendable, Identifiable, Equatable, Codable {
    public let id: String
    public let author: Actor?
    /// The rendered text, for display.
    public let bodyText: String
    /// The Markdown source, for editing.
    public let body: String
    public let createdAt: Date
    /// In the viewer's pending review: only the viewer sees it until the review is submitted.
    public let isPending: Bool
    public let viewerCanUpdate: Bool
    public let viewerCanDelete: Bool
    /// The review that holds the comment.
    public let reviewID: String?

    public init(
        id: String, author: Actor?, bodyText: String, body: String? = nil, createdAt: Date, isPending: Bool = false,
        viewerCanUpdate: Bool = false, viewerCanDelete: Bool = false, reviewID: String? = nil
    ) {
        self.id = id
        self.author = author
        self.bodyText = bodyText
        self.body = body ?? bodyText
        self.createdAt = createdAt
        self.isPending = isPending
        self.viewerCanUpdate = viewerCanUpdate
        self.viewerCanDelete = viewerCanDelete
        self.reviewID = reviewID
    }

    private enum CodingKeys: String, CodingKey {
        case id, author, bodyText, body, createdAt, isPending, viewerCanUpdate, viewerCanDelete, reviewID
    }

    /// Fixtures recorded before comments could change have only the first four fields.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            id: try container.decode(String.self, forKey: .id),
            author: try container.decodeIfPresent(Actor.self, forKey: .author),
            bodyText: try container.decode(String.self, forKey: .bodyText),
            body: try container.decodeIfPresent(String.self, forKey: .body),
            createdAt: try container.decode(Date.self, forKey: .createdAt),
            isPending: try container.decodeIfPresent(Bool.self, forKey: .isPending) ?? false,
            viewerCanUpdate: try container.decodeIfPresent(Bool.self, forKey: .viewerCanUpdate) ?? false,
            viewerCanDelete: try container.decodeIfPresent(Bool.self, forKey: .viewerCanDelete) ?? false,
            reviewID: try container.decodeIfPresent(String.self, forKey: .reviewID)
        )
    }
}

/// Where a new comment goes: one line, or `startLine...line`, on one side of one file.
public struct CommentTarget: Sendable, Hashable, Codable {
    public let path: String
    public let side: DiffSide
    public let line: Int
    /// `nil` for one line. Otherwise less than `line`, on the same side.
    public let startLine: Int?

    public init(path: String, side: DiffSide, line: Int, startLine: Int? = nil) {
        self.path = path
        self.side = side
        self.line = line
        self.startLine = startLine
    }
}

public struct PullRequestSnapshot: Sendable, Equatable, Codable {
    public var pullRequest: PullRequest
    public var files: [ChangedFile]
    public let threads: [ReviewThread]
    /// `nil` in fixtures recorded before the Conversation part existed.
    public var conversation: Conversation?

    public init(pullRequest: PullRequest, files: [ChangedFile], threads: [ReviewThread], conversation: Conversation? = nil) {
        self.pullRequest = pullRequest
        self.files = files
        self.threads = threads
        self.conversation = conversation
    }
}
