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
