import Foundation
import PRModels

/// The parts of a pull request that change while it is open. One request, repeated while checks run.
public struct PullRequestStatus: Sendable, Equatable {
    public let checks: [Check]
    public let merge: MergeStatus?

    public init(checks: [Check], merge: MergeStatus?) {
        self.checks = checks
        self.merge = merge
    }
}

/// A change to a pull request that the viewer makes from the Summary sidebar.
public enum PullRequestAction: Sendable, Equatable {
    public enum ReviewEvent: String, Sendable {
        case approve = "APPROVE"
        case requestChanges = "REQUEST_CHANGES"
        case comment = "COMMENT"
    }

    case review(ReviewEvent, body: String)
    /// `nil` title or body lets GitHub use the repository default.
    case merge(MergeMethod, headOid: String, title: String?, body: String?)
    case enableAutoMerge(MergeMethod, headOid: String)
    case disableAutoMerge
    case enqueue(headOid: String)
    case dequeue
    case markReadyForReview
    case convertToDraft
}

/// A change to the review comments of a pull request.
public enum CommentAction: Sendable, Equatable {
    /// `review == nil` posts a single comment at once. Otherwise the thread goes into that pending review.
    case addThread(CommentTarget, body: String, review: String?)
    /// Starts an empty pending review of the viewer on `commitOid`, the head of the loaded diff.
    case startReview(commitOid: String)
    /// `review == nil` posts the reply at once. Otherwise the reply goes into that pending review.
    case reply(thread: String, body: String, review: String?)
    case edit(comment: String, body: String)
    case delete(comment: String)
    case submitReview(review: String, event: PullRequestAction.ReviewEvent, body: String)
    case discardReview(review: String)
}

public enum CommentResult: Sendable, Equatable {
    /// `addThread`: the new thread as GitHub stores it.
    case thread(ReviewThread)
    /// `reply` and `edit`: the new or changed comment.
    case comment(ReviewComment)
    /// `startReview`: the ID of the pending review.
    case review(id: String)
    /// `delete`, `submitReview`, and `discardReview`.
    case done
}
