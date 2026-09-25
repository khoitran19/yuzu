import GitHubKit
import PRModels

struct Prefetch {
    let started: ContinuousClock.Instant
    let snapshot: Task<PullRequestSnapshot, Error>
}

/// Serves one pull request from a prefetch that is running or done; everything else goes to `base`.
struct PrefetchedService: PullRequestService {
    let base: any PullRequestService
    let ref: PRRef
    let snapshot: Task<PullRequestSnapshot, Error>

    func snapshot(of ref: PRRef) async throws -> PullRequestSnapshot {
        guard ref == self.ref, let snapshot = try? await snapshot.value else { return try await base.snapshot(of: ref) }
        return snapshot
    }

    func parts(of ref: PRRef) -> AsyncThrowingStream<PullRequestPart, Error> {
        guard ref == self.ref else { return base.parts(of: ref) }
        return AsyncThrowingStream { continuation in
            let task = Task {
                guard let snapshot = try? await snapshot.value else {
                    do {
                        for try await part in base.parts(of: ref) { continuation.yield(part) }
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                    return
                }
                continuation.yield(.files(pullRequestID: snapshot.pullRequest.nodeID, files: snapshot.files))
                continuation.yield(.detail(snapshot.pullRequest))
                continuation.yield(.threads(snapshot.threads))
                if let conversation = snapshot.conversation { continuation.yield(.conversation(conversation)) }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func setViewed(_ viewed: Bool, paths: [String], pullRequestID: String) async throws {
        try await base.setViewed(viewed, paths: paths, pullRequestID: pullRequestID)
    }

    func fileContents(of ref: PRRef, oid: String, path: String) async throws -> String? {
        try await base.fileContents(of: ref, oid: oid, path: path)
    }

    func status(of ref: PRRef) async throws -> PullRequestStatus {
        try await base.status(of: ref)
    }

    func conversation(of ref: PRRef) async throws -> Conversation {
        try await base.conversation(of: ref)
    }

    func perform(_ action: PullRequestAction, pullRequestID: String) async throws {
        try await base.perform(action, pullRequestID: pullRequestID)
    }

    func openPullRequests(in repo: RepoRef, scope: PullRequestListScope) async throws -> PullRequestList {
        try await base.openPullRequests(in: repo, scope: scope)
    }

    func comment(_ action: CommentAction, pullRequestID: String) async throws -> CommentResult {
        try await base.comment(action, pullRequestID: pullRequestID)
    }

    func openPullRequests(in repo: RepoRef, author: AuthorQuery) async throws -> PullRequestList {
        try await base.openPullRequests(in: repo, author: author)
    }

    func mergeBaseOid(of ref: PRRef, base: String, head: String) async throws -> String {
        try await self.base.mergeBaseOid(of: ref, base: base, head: head)
    }
}
