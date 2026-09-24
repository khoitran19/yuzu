import Foundation
import PRModels

/// Merge box states for screenshots and tests. `--merge-status <preset>` applies one to a fixture.
public enum MergeStatusPreset: String, Sendable, CaseIterable {
    case clean, blocked, queued, draft, conflicts, merged, author
    case autoMerge = "auto-merge"
    case queueEnabled = "queue-enabled"
    case noPermission = "no-permission"
    /// GitHub reports a head other than the fixture's diff, as after a push.
    case newCommits = "new-commits"

    /// Open, blocked by a failing required check, admin viewer, all methods, squash by default, no merge queue.
    public static func base(for pullRequest: PullRequest) -> MergeStatus {
        MergeStatus(
            state: .open, isDraft: false, headOid: pullRequest.headOid, mergeable: .mergeable, mergeStateStatus: .blocked,
            reviewDecision: .approved, viewerDidAuthor: false, viewerCanUpdate: true, viewerCanMerge: true, viewerCanMergeAsAdmin: true,
            viewerCanEnableAutoMerge: true, viewerCanDisableAutoMerge: true, viewerReviewState: nil,
            allowedMethods: [.merge, .squash, .rebase], defaultMethod: .squash, autoMergeAllowed: true, isMergeQueueEnabled: false,
            queueEntry: nil, mergeQueueURL: nil, autoMerge: nil
        )
    }

    /// Changes `conversation` and the pull request state to match the preset.
    public func apply(to snapshot: inout PullRequestSnapshot) {
        var conversation = snapshot.conversation ?? Conversation(items: [], checks: [])
        var status = conversation.merge ?? Self.base(for: snapshot.pullRequest)
        let ref = snapshot.pullRequest.ref
        switch self {
        case .blocked:
            break
        case .clean:
            status.mergeStateStatus = .clean
            conversation.checks = conversation.checks.map(Self.passing)
        case .queued:
            status.isMergeQueueEnabled = true
            status.queueEntry = MergeStatus.QueueEntry(
                position: 2, totalCount: 3, state: .awaitingChecks, estimatedSecondsToMerge: 780,
                enqueuedAt: snapshot.pullRequest.createdAt.addingTimeInterval(7_200)
            )
            status.mergeQueueURL = URL(string: "https://github.com/\(ref.owner)/\(ref.repo)/queue/\(snapshot.pullRequest.baseRefName)")
        case .autoMerge:
            status.autoMerge = MergeStatus.AutoMerge(method: .squash, enabledBy: FixturePullRequestService.viewerLogin)
        case .draft:
            status.isDraft = true
        case .conflicts:
            status.mergeable = .conflicting
            status.mergeStateStatus = .dirty
        case .merged:
            status.state = .merged
            status.mergeStateStatus = .unknown
        case .author:
            status.viewerDidAuthor = true
            status.viewerCanMergeAsAdmin = false
        case .queueEnabled:
            status.isMergeQueueEnabled = true
            status.mergeQueueURL = URL(string: "https://github.com/\(ref.owner)/\(ref.repo)/queue/\(snapshot.pullRequest.baseRefName)")
        case .newCommits:
            status.headOid = String(status.headOid.reversed())
        case .noPermission:
            status.viewerCanMerge = false
            status.viewerCanMergeAsAdmin = false
            status.viewerCanUpdate = false
            status.viewerCanEnableAutoMerge = false
            status.viewerCanDisableAutoMerge = false
        }
        conversation.merge = status
        snapshot.conversation = conversation
        snapshot.pullRequest.state = status.state
        snapshot.pullRequest.isDraft = status.isDraft
    }

    private static func passing(_ check: Check) -> Check {
        guard check.state == .failure || check.state == .pending else { return check }
        return Check(
            name: check.name, workflow: check.workflow, event: check.event, state: .success, summary: check.summary, url: check.url,
            avatarURL: check.avatarURL, isRequired: check.isRequired, startedAt: check.startedAt,
            completedAt: check.completedAt ?? check.startedAt.map { $0.addingTimeInterval(95) }
        )
    }
}
