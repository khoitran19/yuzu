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

    private struct State {
        var snapshot: PullRequestSnapshot?
        var setViewedCalls: [SetViewedCall] = []
    }

    public let store: FixtureStore
    private let latency: Duration
    private let failingViewedPaths: Set<String>
    private let state = Mutex(State())

    /// `setViewed` leaves `failingViewedPaths` unchanged and throws `GitHubError.partialFailure` with them.
    public init(directory: URL, latency: Duration = .zero, failingViewedPaths: Set<String> = []) {
        store = FixtureStore(directory: directory)
        self.latency = latency
        self.failingViewedPaths = failingViewedPaths
    }

    public var setViewedCalls: [SetViewedCall] {
        state.withLock { $0.setViewedCalls }
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

    private func loadedSnapshot() throws -> PullRequestSnapshot {
        if let snapshot = state.withLock({ $0.snapshot }) { return snapshot }
        let loaded = try store.readSnapshot()
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
