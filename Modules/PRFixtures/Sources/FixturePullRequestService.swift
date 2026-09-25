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

    public struct CommentCall: Sendable, Equatable {
        public let action: CommentAction
        public let pullRequestID: String
    }

    private struct State {
        var snapshot: PullRequestSnapshot?
        var setViewedCalls: [SetViewedCall] = []
        var performCalls: [PerformCall] = []
        var commentCalls: [CommentCall] = []
        var pendingReview: String?
        var lastID = 0
        var statusCalls = 0
        var conversationCalls = 0
    }

    /// The signed-in user in fixture mode: it makes reviews and comments, and can edit its own comments.
    public static let viewerLogin = "octocat"

    public let store: FixtureStore
    private let latency: Duration
    private let failingViewedPaths: Set<String>
    private let emptyPullRequestLists: Bool
    private let mergeStatus: MergeStatusPreset?
    private let rejection: String?
    private let state = Mutex(State())

    /// `setViewed` leaves `failingViewedPaths` unchanged and throws `GitHubError.partialFailure` with them.
    /// `emptyPullRequestLists` makes `openPullRequests` return no rows. `mergeStatus` replaces the fixture's merge box state.
    /// With `rejection`, `perform` and `comment` change nothing and throw `GitHubError.rejected` with it.
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

    public var commentCalls: [CommentCall] {
        state.withLock { $0.commentCalls }
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
            try Self.apply(action, to: &snapshot, reviewID: "PRR_fixture_\(state.performCalls.count)")
            state.snapshot = snapshot
        }
    }

    private static func apply(_ action: PullRequestAction, to snapshot: inout PullRequestSnapshot, reviewID: String) throws {
        var conversation = snapshot.conversation ?? Conversation(items: [], checks: [])
        var status = conversation.merge ?? MergeStatusPreset.base(for: snapshot.pullRequest)
        guard status.state == .open else { throw GitHubError.rejected("Pull request is not open") }
        switch action {
        case let .review(event, body):
            let state: Review.State = switch event {
            case .approve: .approved
            case .requestChanges: .changesRequested
            case .comment: .commented
            }
            let escaped = body.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
            conversation.items.append(
                .review(
                    Review(
                        id: reviewID,
                        author: Author(actor: Actor(login: viewerLogin, avatarURL: nil), isBot: false, association: "MEMBER"),
                        state: state, bodyHTML: body.isEmpty ? "" : "<p>\(escaped)</p>", createdAt: .now, url: nil, comments: []
                    )))
            status.viewerReviewState = state
            if event != .comment { status.reviewDecision = event == .approve ? .approved : .changesRequested }
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

    /// Applies the change GitHub would make to the stored threads, so later reads show it.
    @concurrent public func comment(_ action: CommentAction, pullRequestID: String) async throws -> CommentResult {
        try await simulateLatency()
        _ = try loadedSnapshot()
        return try state.withLock { state in
            state.commentCalls.append(CommentCall(action: action, pullRequestID: pullRequestID))
            if let rejection { throw GitHubError.rejected(rejection) }
            guard state.snapshot?.pullRequest.nodeID == pullRequestID else {
                throw GitHubError.rejected("Could not resolve to a node with the global id of '\(pullRequestID)'")
            }
            return try Self.apply(action, to: &state)
        }
    }

    /// Changes `state` only when GitHub would accept the action.
    private static func apply(_ action: CommentAction, to state: inout State) throws -> CommentResult {
        guard var snapshot = state.snapshot else { throw GitHubError.malformedResponse }
        var threads = snapshot.threads
        var pendingReview = state.pendingReview
        var lastID = state.lastID
        func newID(_ prefix: String) -> String {
            lastID += 1
            return "\(prefix)_fixture_\(lastID)"
        }
        func newComment(_ body: String, review: String, isPending: Bool) -> ReviewComment {
            ReviewComment(
                id: newID("PRRC"), author: Actor(login: viewerLogin, avatarURL: nil), bodyText: body, body: body, createdAt: .now,
                isPending: isPending, viewerCanUpdate: true, viewerCanDelete: true, reviewID: review
            )
        }
        func requirePending(_ review: String) throws {
            guard review == pendingReview else {
                throw GitHubError.rejected("Could not resolve to a PullRequestReview with the id of '\(review)'.")
            }
        }
        func location(of comment: String) throws -> (thread: Int, comment: Int) {
            for (index, thread) in threads.enumerated() {
                if let position = thread.comments.firstIndex(where: { $0.id == comment }) { return (index, position) }
            }
            throw GitHubError.rejected("Could not resolve to a PullRequestReviewComment with the id of '\(comment)'.")
        }

        let result: CommentResult
        switch action {
        case let .addThread(target, body, review):
            guard snapshot.files.contains(where: { $0.path == target.path }) else {
                throw GitHubError.rejected("Path could not be resolved")
            }
            if let startLine = target.startLine, startLine >= target.line {
                throw GitHubError.rejected("The start line must be before the line")
            }
            if let review {
                try requirePending(review)
            } else if pendingReview != nil {
                throw GitHubError.rejected("User can only have one pending review per pull request")
            }
            let comment = newComment(body, review: review ?? newID("PRR"), isPending: review != nil)
            let thread = ReviewThread(
                id: newID("PRRT"), path: target.path, line: target.line, startLine: target.startLine, side: target.side,
                isResolved: false, isOutdated: false, comments: [comment]
            )
            threads.append(thread)
            result = .thread(thread)
        case .startReview:
            let id = pendingReview ?? newID("PRR")
            pendingReview = id
            result = .review(id: id)
        case let .reply(threadID, body, review):
            guard let index = threads.firstIndex(where: { $0.id == threadID }) else {
                throw GitHubError.rejected("Could not resolve to a PullRequestReviewThread with the id of '\(threadID)'.")
            }
            if let review { try requirePending(review) }
            let comment = newComment(body, review: review ?? newID("PRR"), isPending: review != nil)
            threads[index] = threads[index].replacing(comments: threads[index].comments + [comment])
            result = .comment(comment)
        case let .edit(id, body):
            let (thread, position) = try location(of: id)
            guard threads[thread].comments[position].viewerCanUpdate else { throw GitHubError.rejected("You cannot update this comment") }
            let comment = threads[thread].comments[position].replacing(body: body)
            var comments = threads[thread].comments
            comments[position] = comment
            threads[thread] = threads[thread].replacing(comments: comments)
            result = .comment(comment)
        case let .delete(id):
            let (thread, position) = try location(of: id)
            guard threads[thread].comments[position].viewerCanDelete else { throw GitHubError.rejected("You cannot delete this comment") }
            var comments = threads[thread].comments
            comments.remove(at: position)
            if comments.isEmpty {
                threads.remove(at: thread)
            } else {
                threads[thread] = threads[thread].replacing(comments: comments)
            }
            result = .done
        case let .submitReview(review, event, body):
            try requirePending(review)
            try apply(.review(event, body: body), to: &snapshot, reviewID: review)
            threads = threads.map { thread in
                thread.replacing(comments: thread.comments.map { $0.reviewID == review ? $0.replacing(isPending: false) : $0 })
            }
            pendingReview = nil
            result = .done
        case let .discardReview(review):
            try requirePending(review)
            threads = threads.compactMap { thread in
                let comments = thread.comments.filter { $0.reviewID != review }
                return comments.isEmpty ? nil : thread.replacing(comments: comments)
            }
            pendingReview = nil
            result = .done
        }
        state.lastID = lastID
        state.pendingReview = pendingReview
        state.snapshot = snapshot.replacing(threads: threads)
        return result
    }

    /// `@me` is the Mine list. Other logins match the authors of both lists.
    @concurrent public func openPullRequests(in repo: RepoRef, author: AuthorQuery) async throws -> PullRequestList {
        let mine = try await openPullRequests(in: repo, scope: .mine).pullRequests
        if author.login == "@me" { return PullRequestList(pullRequests: mine, totalCount: mine.count) }
        let others = try await openPullRequests(in: repo, scope: .others).pullRequests
        let matches = (mine + others).filter { $0.author?.login == author.login }
        return PullRequestList(pullRequests: matches, totalCount: matches.count)
    }

    private func loadedSnapshot() throws -> PullRequestSnapshot {
        if let snapshot = state.withLock({ $0.snapshot }) { return snapshot }
        var loaded = try store.readSnapshot()
        mergeStatus?.apply(to: &loaded)
        loaded = loaded.replacing(threads: loaded.threads.map { thread in
            thread.replacing(comments: thread.comments.map { $0.author?.login == Self.viewerLogin ? $0.replacing(editable: true) : $0 })
        })
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

private extension PullRequestSnapshot {
    func replacing(threads: [ReviewThread]) -> PullRequestSnapshot {
        PullRequestSnapshot(pullRequest: pullRequest, files: files, threads: threads, conversation: conversation)
    }
}

private extension ReviewThread {
    func replacing(comments: [ReviewComment]) -> ReviewThread {
        ReviewThread(
            id: id, path: path, line: line, startLine: startLine, side: side, isResolved: isResolved, isOutdated: isOutdated,
            comments: comments
        )
    }
}

private extension ReviewComment {
    func replacing(body: String? = nil, isPending: Bool? = nil, editable: Bool? = nil) -> ReviewComment {
        ReviewComment(
            id: id, author: author, bodyText: body ?? bodyText, body: body ?? self.body, createdAt: createdAt,
            isPending: isPending ?? self.isPending, viewerCanUpdate: editable ?? viewerCanUpdate,
            viewerCanDelete: editable ?? viewerCanDelete, reviewID: reviewID
        )
    }
}
