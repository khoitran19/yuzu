import AppShortcuts
import Foundation
import PRModels

/// A button in the Summary sidebar. The page posts the raw value; Swift accepts only these names.
nonisolated enum SidebarAction: String, Sendable, CaseIterable {
    case approve, requestChanges, merge, bypassMerge, enqueue, dequeue, enableAutoMerge, disableAutoMerge, markReady, convertToDraft
    /// The caret of the split merge button; it opens the merge method menu.
    case chooseMethod
    /// Links that open GitHub in the browser; a plain link to the pull request would open in the app.
    case resolveConflicts, viewMergeQueue
    /// Loads the pull request again after new commits were pushed.
    case reload
    /// Submits the viewer's pending review from the Files changed tab. It has no sidebar button.
    case submitReview

    /// Actions that merge the head; they need the head the viewer reviewed.
    static let merging: Set<SidebarAction> = [.merge, .bypassMerge, .enqueue, .enableAutoMerge, .chooseMethod]

    /// The button text while the action runs.
    var progressTitle: String {
        switch self {
        case .approve: "Approving…"
        case .requestChanges: "Requesting changes…"
        case .merge, .bypassMerge: "Merging…"
        case .enqueue: "Adding to the queue…"
        case .dequeue: "Removing from the queue…"
        case .enableAutoMerge: "Enabling auto-merge…"
        case .disableAutoMerge: "Disabling auto-merge…"
        case .markReady: "Marking as ready…"
        case .convertToDraft: "Converting to draft…"
        case .reload: "Reloading…"
        case .submitReview: "Submitting review…"
        case .chooseMethod, .resolveConflicts, .viewMergeQueue: ""
        }
    }

    /// Completes "Could not …" in the error banner.
    var failureTitle: String {
        switch self {
        case .approve: "approve"
        case .requestChanges: "request changes"
        case .merge, .bypassMerge: "merge"
        case .enqueue: "add the pull request to the merge queue"
        case .dequeue: "remove the pull request from the merge queue"
        case .enableAutoMerge: "enable auto-merge"
        case .disableAutoMerge: "disable auto-merge"
        case .markReady: "mark the pull request as ready for review"
        case .convertToDraft: "convert the pull request to a draft"
        case .chooseMethod: "change the merge method"
        case .resolveConflicts, .viewMergeQueue: "open GitHub"
        case .reload: "reload the pull request"
        case .submitReview: "submit the review"
        }
    }

    var shortcut: Shortcut? {
        switch self {
        case .approve: .approve
        case .requestChanges: .requestChanges
        case .merge, .enqueue, .enableAutoMerge: .merge
        default: nil
        }
    }
}

/// The action row of the merge box, in GitHub's order of precedence.
nonisolated struct MergeBoxState: Equatable {
    enum Action: Equatable {
        case merged
        case closed
        case draft(canMarkReady: Bool)
        case queued(canDequeue: Bool)
        case autoMerge(canDisable: Bool)
        case noPermission
        case conflicts
        case enqueue
        case merge
        case enableAutoMerge
        case blocked
    }

    let action: Action
    /// Shows "Bypass rules and merge now" under the action row.
    let canBypass: Bool

    init(_ status: MergeStatus) {
        action = Self.action(status)
        canBypass = status.viewerCanMergeAsAdmin && [.enqueue, .enableAutoMerge, .blocked].contains(action)
    }

    private static func action(_ status: MergeStatus) -> Action {
        switch status.state {
        case .merged: return .merged
        case .closed: return .closed
        case .open: break
        }
        if status.isDraft { return .draft(canMarkReady: status.viewerCanUpdate) }
        if status.queueEntry != nil { return .queued(canDequeue: status.viewerCanMerge || status.viewerDidAuthor) }
        if status.autoMerge != nil { return .autoMerge(canDisable: status.viewerCanDisableAutoMerge) }
        if !status.viewerCanMerge { return .noPermission }
        if status.mergeable == .conflicting || status.mergeStateStatus == .dirty { return .conflicts }
        if status.isMergeQueueEnabled { return .enqueue }
        switch status.mergeStateStatus {
        case .clean, .hasHooks, .unstable: return .merge
        case .blocked, .behind, .unknown:
            return status.autoMergeAllowed && status.viewerCanEnableAutoMerge ? .enableAutoMerge : .blocked
        case .dirty: return .conflicts
        }
    }

    /// The action that ⇧⌘↩ and the primary button run.
    var primary: SidebarAction? {
        switch action {
        case .merge: .merge
        case .enqueue: .enqueue
        case .enableAutoMerge: .enableAutoMerge
        default: nil
        }
    }
}

/// What the sidebar offers. Without a merge status (older fixtures), only the review buttons and the checks show.
nonisolated struct SidebarState: Equatable {
    let canReview: Bool
    let box: MergeBoxState?
    let canConvertToDraft: Bool
    /// GitHub reports a head other than the one the viewer reviewed; merging waits for a reload.
    let headChanged: Bool

    /// `reviewedHead` is the head of the loaded diff.
    init(status: MergeStatus?, state: PullRequest.State, isDraft: Bool, reviewedHead: String? = nil) {
        let state = status?.state ?? state
        canReview = state == .open && status?.viewerDidAuthor != true
        box = status.map(MergeBoxState.init)
        canConvertToDraft = state == .open && !(status?.isDraft ?? isDraft) && status?.viewerCanUpdate == true
        headChanged = state == .open && reviewedHead != nil && status.map { $0.headOid != reviewedHead } == true
    }

    /// The action that ⇧⌘↩ runs; `nil` while the head changed.
    var primary: SidebarAction? {
        headChanged ? nil : box?.primary
    }

    /// The buttons the sidebar shows; a message for any other action is ignored.
    var actions: Set<SidebarAction> {
        var actions: Set<SidebarAction> = canReview ? [.approve, .requestChanges] : []
        if canConvertToDraft { actions.insert(.convertToDraft) }
        guard let box else { return actions }
        if box.canBypass { actions.insert(.bypassMerge) }
        switch box.action {
        case .draft(canMarkReady: true): actions.insert(.markReady)
        case let .queued(canDequeue):
            if canDequeue { actions.insert(.dequeue) }
            actions.insert(.viewMergeQueue)
        case .autoMerge(canDisable: true): actions.insert(.disableAutoMerge)
        case .conflicts: actions.insert(.resolveConflicts)
        case .enqueue: actions.insert(.enqueue)
        case .merge: actions.formUnion([.merge, .chooseMethod])
        case .enableAutoMerge: actions.formUnion([.enableAutoMerge, .chooseMethod])
        default: break
        }
        if headChanged {
            actions.subtract(SidebarAction.merging)
            actions.insert(.reload)
        }
        return actions
    }
}

nonisolated extension MergeMethod {
    /// The split button title, as GitHub words it.
    var buttonTitle: String {
        switch self {
        case .merge: "Create a merge commit"
        case .squash: "Squash and merge"
        case .rebase: "Rebase and merge"
        }
    }

    /// Completes "Will … when all requirements are met."
    var verb: String {
        switch self {
        case .merge: "merge"
        case .squash: "squash and merge"
        case .rebase: "rebase and merge"
        }
    }

    var shortName: String {
        switch self {
        case .merge: "merge"
        case .squash: "squash"
        case .rebase: "rebase"
        }
    }
}
