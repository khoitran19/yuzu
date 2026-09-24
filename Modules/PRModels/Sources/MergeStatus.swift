import Foundation

public enum MergeMethod: String, Sendable, Codable, CaseIterable {
    case merge = "MERGE"
    case squash = "SQUASH"
    case rebase = "REBASE"
}

/// What the merge box shows, and what the viewer may do. It comes with the checks, so it costs no extra request.
public struct MergeStatus: Sendable, Equatable, Codable {
    public enum Mergeable: String, Sendable, Codable {
        case mergeable = "MERGEABLE"
        case conflicting = "CONFLICTING"
        case unknown = "UNKNOWN"
    }

    /// GitHub `MergeStateStatus`.
    public enum StateStatus: String, Sendable, Codable {
        case behind = "BEHIND"
        case blocked = "BLOCKED"
        case clean = "CLEAN"
        case dirty = "DIRTY"
        case hasHooks = "HAS_HOOKS"
        case unknown = "UNKNOWN"
        case unstable = "UNSTABLE"
    }

    public struct QueueEntry: Sendable, Equatable, Codable {
        /// GitHub `MergeQueueEntryState`.
        public enum State: String, Sendable, Codable {
            case queued = "QUEUED"
            case awaitingChecks = "AWAITING_CHECKS"
            case mergeable = "MERGEABLE"
            case unmergeable = "UNMERGEABLE"
            case locked = "LOCKED"
        }

        /// 1 is the next entry to merge.
        public var position: Int
        public var totalCount: Int?
        public var state: State
        public var estimatedSecondsToMerge: Int?
        public var enqueuedAt: Date?

        public init(position: Int, totalCount: Int?, state: State, estimatedSecondsToMerge: Int?, enqueuedAt: Date?) {
            self.position = position
            self.totalCount = totalCount
            self.state = state
            self.estimatedSecondsToMerge = estimatedSecondsToMerge
            self.enqueuedAt = enqueuedAt
        }
    }

    public struct AutoMerge: Sendable, Equatable, Codable {
        public var method: MergeMethod
        public var enabledBy: String?

        public init(method: MergeMethod, enabledBy: String?) {
            self.method = method
            self.enabledBy = enabledBy
        }
    }

    public var state: PullRequest.State
    public var isDraft: Bool
    /// The head commit that the checks and the mergeability describe; merges send it as `expectedHeadOid`.
    public var headOid: String
    public var mergeable: Mergeable
    public var mergeStateStatus: StateStatus
    public var reviewDecision: PullRequestSummary.ReviewDecision?
    public var viewerDidAuthor: Bool
    public var viewerCanUpdate: Bool
    /// The viewer has write, maintain, or admin permission on the repository.
    public var viewerCanMerge: Bool
    public var viewerCanMergeAsAdmin: Bool
    public var viewerCanEnableAutoMerge: Bool
    public var viewerCanDisableAutoMerge: Bool
    public var viewerReviewState: Review.State?
    public var allowedMethods: [MergeMethod]
    public var defaultMethod: MergeMethod
    public var autoMergeAllowed: Bool
    public var isMergeQueueEnabled: Bool
    public var queueEntry: QueueEntry?
    public var mergeQueueURL: URL?
    public var autoMerge: AutoMerge?

    public init(
        state: PullRequest.State, isDraft: Bool, headOid: String, mergeable: Mergeable, mergeStateStatus: StateStatus,
        reviewDecision: PullRequestSummary.ReviewDecision?, viewerDidAuthor: Bool, viewerCanUpdate: Bool, viewerCanMerge: Bool,
        viewerCanMergeAsAdmin: Bool, viewerCanEnableAutoMerge: Bool, viewerCanDisableAutoMerge: Bool, viewerReviewState: Review.State?,
        allowedMethods: [MergeMethod], defaultMethod: MergeMethod, autoMergeAllowed: Bool, isMergeQueueEnabled: Bool,
        queueEntry: QueueEntry?, mergeQueueURL: URL?, autoMerge: AutoMerge?
    ) {
        self.state = state
        self.isDraft = isDraft
        self.headOid = headOid
        self.mergeable = mergeable
        self.mergeStateStatus = mergeStateStatus
        self.reviewDecision = reviewDecision
        self.viewerDidAuthor = viewerDidAuthor
        self.viewerCanUpdate = viewerCanUpdate
        self.viewerCanMerge = viewerCanMerge
        self.viewerCanMergeAsAdmin = viewerCanMergeAsAdmin
        self.viewerCanEnableAutoMerge = viewerCanEnableAutoMerge
        self.viewerCanDisableAutoMerge = viewerCanDisableAutoMerge
        self.viewerReviewState = viewerReviewState
        self.allowedMethods = allowedMethods
        self.defaultMethod = defaultMethod
        self.autoMergeAllowed = autoMergeAllowed
        self.isMergeQueueEnabled = isMergeQueueEnabled
        self.queueEntry = queueEntry
        self.mergeQueueURL = mergeQueueURL
        self.autoMerge = autoMerge
    }
}
