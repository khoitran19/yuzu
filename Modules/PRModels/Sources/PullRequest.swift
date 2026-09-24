import Foundation

public struct PullRequest: Sendable, Equatable, Codable {
    public enum State: String, Sendable, Codable { case open = "OPEN", closed = "CLOSED", merged = "MERGED" }

    public let nodeID: String
    public let ref: PRRef
    public let title: String
    public let state: State
    public let isDraft: Bool
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
    public let bodyText: String
    public let createdAt: Date

    public init(id: String, author: Actor?, bodyText: String, createdAt: Date) {
        self.id = id
        self.author = author
        self.bodyText = bodyText
        self.createdAt = createdAt
    }
}

public struct PullRequestSnapshot: Sendable, Equatable, Codable {
    public let pullRequest: PullRequest
    public var files: [ChangedFile]
    public let threads: [ReviewThread]
    /// `nil` in fixtures recorded before the Conversation part existed.
    public let conversation: Conversation?

    public init(pullRequest: PullRequest, files: [ChangedFile], threads: [ReviewThread], conversation: Conversation? = nil) {
        self.pullRequest = pullRequest
        self.files = files
        self.threads = threads
        self.conversation = conversation
    }
}
