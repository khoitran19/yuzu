import Foundation
import GitHubKit
import PRModels
import Synchronization

/// Serves a fixture directory with no network. Loads `snapshot.json` on first use, off the caller's actor.
public final class FixturePullRequestService: PullRequestService {
    public struct SetViewedCall: Sendable, Equatable {
        public let viewed: Bool
        public let paths: [String]
        public let pullRequestID: String
    }

    public struct PerformCall: Sendable, Equatable {
        public let action: PullRequestAction
        public let pullRequestID: String
    }

    private struct State {
        var snapshot: PullRequestSnapshot?
        var setViewedCalls: [SetViewedCall] = []
        var performCalls: [PerformCall] = []
        var statusCalls = 0
        var conversationCalls = 0
    }

    /// The signed-in user in fixture mode; reviews and auto-merge from `perform` use it.
    public static let viewerLogin = "yuzu-reviewer"

    public let store: FixtureStore
    private let latency: Duration
    private let failingViewedPaths: Set<String>
    private let emptyPullRequestLists: Bool
    private let mergeStatus: MergeStatusPreset?
    private let rejection: String?
    private let state = Mutex(State())

    /// `setViewed` leaves `failingViewedPaths` unchanged and throws `GitHubError.partialFailure` with them.
    /// `emptyPullRequestLists` makes `openPullRequests` return no rows. `mergeStatus` replaces the fixture's merge box state.
    /// With `rejection`, `perform` changes nothing and throws `GitHubError.rejected` with it.
    public init(
        directory: URL, latency: Duration = .zero, failingViewedPaths: Set<String> = [], emptyPullRequestLists: Bool = false,
        mergeStatus: MergeStatusPreset? = nil, rejection: String? = nil
    ) {
        store = FixtureStore(directory: directory)
        self.latency = latency
        self.failingViewedPaths = failingViewedPaths
        self.emptyPullRequestLists = emptyPullRequestLists
        self.mergeStatus = mergeStatus
        self.rejection = rejection
    }

    public var setViewedCalls: [SetViewedCall] {
        state.withLock { $0.setViewedCalls }
    }

    public var performCalls: [PerformCall] {
        state.withLock { $0.performCalls }
    }

    public var statusCalls: Int {
        state.withLock { $0.statusCalls }
    }

    public var conversationCalls: Int {
        state.withLock { $0.conversationCalls }
    }

    @concurrent public func pullRequestRef() async throws -> PRRef {
        try loadedSnapshot().pullRequest.ref
    }

    @concurrent public func snapshot(of ref: PRRef) async throws -> PullRequestSnapshot {
        try await simulateLatency()
        let snapshot = try loadedSnapshot()
        guard snapshot.pullRequest.ref == ref else { throw GitHubError.notFound }
        return snapshot
    }

    @concurrent public func setViewed(_ viewed: Bool, paths: [String], pullRequestID: String) async throws {
        try await simulateLatency()
        _ = try loadedSnapshot()
        try state.withLock { state in
            state.setViewedCalls.append(SetViewedCall(viewed: viewed, paths: paths, pullRequestID: pullRequestID))
            guard var snapshot = state.snapshot, snapshot.pullRequest.nodeID == pullRequestID else {
                throw GitHubError.graphQL("Could not resolve to a node with the global id of '\(pullRequestID)'")
            }
            let indices = Dictionary(snapshot.files.indices.map { (snapshot.files[$0].path, $0) }) { first, _ in first }
            if let unknown = paths.first(where: { indices[$0] == nil }) {
                throw GitHubError.graphQL("The pull request has no file at '\(unknown)'")
            }
            for path in paths where !failingViewedPaths.contains(path) {
                if let index = indices[path] { snapshot.files[index].viewedState = viewed ? .viewed : .unviewed }
            }
            state.snapshot = snapshot
        }
        let failed = paths.filter(failingViewedPaths.contains)
        if !failed.isEmpty { throw GitHubError.partialFailure(paths: failed) }
    }

    @concurrent public func status(of ref: PRRef) async throws -> PullRequestStatus {
        let conversation = try await snapshot(of: ref).conversation
        state.withLock { $0.statusCalls += 1 }
        return PullRequestStatus(checks: conversation?.checks ?? [], merge: conversation?.merge)
    }

    @concurrent public func conversation(of ref: PRRef) async throws -> Conversation {
        let conversation = try await snapshot(of: ref).conversation
        state.withLock { $0.conversationCalls += 1 }
        return conversation ?? Conversation(items: [], checks: [])
    }

    /// Applies the change GitHub would make to the stored snapshot, so later reads show it.
    @concurrent public func perform(_ action: PullRequestAction, pullRequestID: String) async throws {
        try await simulateLatency()
        _ = try loadedSnapshot()
        try state.withLock { state in
            state.performCalls.append(PerformCall(action: action, pullRequestID: pullRequestID))
            if let rejection { throw GitHubError.rejected(rejection) }
            guard var snapshot = state.snapshot, snapshot.pullRequest.nodeID == pullRequestID else {
                throw GitHubError.rejected("Could not resolve to a node with the global id of '\(pullRequestID)'")
            }
            try Self.apply(action, to: &snapshot, number: state.performCalls.count)
            state.snapshot = snapshot
        }
    }

    private static func apply(_ action: PullRequestAction, to snapshot: inout PullRequestSnapshot, number: Int) throws {
        var conversation = snapshot.conversation ?? Conversation(items: [], checks: [])
        var status = conversation.merge ?? MergeStatusPreset.base(for: snapshot.pullRequest)
        guard status.state == .open else { throw GitHubError.rejected("Pull request is not open") }
        switch action {
        case let .review(event, body):
            let state: Review.State = event == .approve ? .approved : .changesRequested
            let escaped = body.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
            conversation.items.append(
                .review(
                    Review(
                        id: "PRR_fixture_\(number)",
                        author: Author(actor: Actor(login: viewerLogin, avatarURL: nil), isBot: false, association: "MEMBER"),
                        state: state, bodyHTML: body.isEmpty ? "" : "<p>\(escaped)</p>", createdAt: .now, url: nil, comments: []
                    )))
            status.viewerReviewState = state
            status.reviewDecision = event == .approve ? .approved : .changesRequested
        case let .merge(_, headOid, _, _):
            guard headOid == status.headOid else { throw GitHubError.rejected("Head branch was modified. Review and try the merge again.") }
            guard !status.isDraft else { throw GitHubError.rejected("Pull request is still a draft") }
            status.state = .merged
            status.queueEntry = nil
            status.autoMerge = nil
        case let .enableAutoMerge(method, _):
            status.autoMerge = MergeStatus.AutoMerge(method: method, enabledBy: viewerLogin)
        case .disableAutoMerge:
            status.autoMerge = nil
        case .enqueue:
            status.queueEntry = MergeStatus.QueueEntry(
                position: 1, totalCount: 1, state: .queued, estimatedSecondsToMerge: nil, enqueuedAt: .now)
        case .dequeue:
            status.queueEntry = nil
        case .markReadyForReview:
            status.isDraft = false
        case .convertToDraft:
            status.isDraft = true
        }
        conversation.merge = status
        snapshot.conversation = conversation
        snapshot.pullRequest.state = status.state
        snapshot.pullRequest.isDraft = status.isDraft
    }

    @concurrent public func mergeBaseOid(of ref: PRRef, base: String, head: String) async throws -> String {
        try await simulateLatency()
        let snapshot = try loadedSnapshot()
        guard snapshot.pullRequest.ref == ref else { throw GitHubError.notFound }
        return try store.readMergeBaseOid() ?? snapshot.pullRequest.baseOid
    }

    @concurrent public func fileContents(of ref: PRRef, oid: String, path: String) async throws -> String? {
        try await simulateLatency()
        return try store.contents(oid: oid, path: path)
    }

    @concurrent public func openPullRequests(in repo: RepoRef, scope: PullRequestListScope) async throws -> PullRequestList {
        try await simulateLatency()
        if emptyPullRequestLists { return PullRequestList(pullRequests: [], totalCount: 0) }
        return SyntheticPullRequestList.make(repo: repo, scope: scope, current: try loadedSnapshot().pullRequest, now: .now)
    }

    private func loadedSnapshot() throws -> PullRequestSnapshot {
        if let snapshot = state.withLock({ $0.snapshot }) { return snapshot }
        var loaded = try store.readSnapshot()
        mergeStatus?.apply(to: &loaded)
        return state.withLock { state in
            if let snapshot = state.snapshot { return snapshot }
            state.snapshot = loaded
            return loaded
        }
    }

    private func simulateLatency() async throws {
        if latency > .zero { try await Task.sleep(for: latency) }
    }
}
