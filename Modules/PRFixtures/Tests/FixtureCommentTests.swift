import Foundation
import GitHubKit
import PRModels
import Testing
@testable import PRFixtures

struct FixtureCommentTests {
    let fixture = SyntheticPullRequest.make(fileCount: 30, changedLines: 400, seed: 3)

    @Test func startAddSubmitPublishesThePendingThread() async throws {
        let (service, directory) = try makeService()
        defer { try? FileManager.default.removeItem(at: directory) }
        let (ref, id) = (fixture.snapshot.pullRequest.ref, fixture.snapshot.pullRequest.nodeID)
        let target = try target()

        let headOid = fixture.snapshot.pullRequest.headOid
        let review = try reviewID(try await service.comment(.startReview(commitOid: headOid), pullRequestID: id))
        #expect(try await service.comment(.startReview(commitOid: "other"), pullRequestID: id) == .review(id: review))
        let added = try thread(try await service.comment(.addThread(target, body: "Pending", review: review), pullRequestID: id))
        #expect(added.comments.map(\.isPending) == [true])
        #expect(added.comments.first?.reviewID == review)
        #expect(try await service.snapshot(of: ref).threads.last == added)
        await #expect(throws: GitHubError.rejected("User can only have one pending review per pull request")) {
            try await service.comment(.addThread(target, body: "Single", review: nil), pullRequestID: id)
        }

        #expect(try await service.comment(.submitReview(review: review, event: .comment, body: "Looks fine"), pullRequestID: id) == .done)
        let after = try await service.snapshot(of: ref)
        let published = try #require(after.threads.first { $0.id == added.id })
        #expect(published.comments.map(\.isPending) == [false])
        #expect(published.comments.first?.reviewID == review)
        let items = try #require(after.conversation?.items)
        guard case let .review(submitted) = items.last else { Issue.record("Expected the submitted review last"); return }
        #expect(submitted.id == review && submitted.state == .commented)
        await #expect(throws: GitHubError.self) {
            try await service.comment(.submitReview(review: review, event: .comment, body: ""), pullRequestID: id)
        }
        #expect(try await service.comment(.startReview(commitOid: "h"), pullRequestID: id) != .review(id: review))
    }

    @Test func startAddDiscardRemovesOnlyPendingComments() async throws {
        let (service, directory) = try makeService()
        defer { try? FileManager.default.removeItem(at: directory) }
        let (ref, id) = (fixture.snapshot.pullRequest.ref, fixture.snapshot.pullRequest.nodeID)
        let before = try await service.snapshot(of: ref)
        let existing = try #require(before.threads.first)

        let review = try reviewID(try await service.comment(.startReview(commitOid: "h"), pullRequestID: id))
        _ = try await service.comment(.addThread(try target(), body: "Pending", review: review), pullRequestID: id)
        let reply = try comment(
            try await service.comment(.reply(thread: existing.id, body: "Pending reply", review: review), pullRequestID: id)
        )
        #expect(reply.isPending && reply.reviewID == review)
        #expect(try await service.snapshot(of: ref).threads.count == before.threads.count + 1)

        #expect(try await service.comment(.discardReview(review: review), pullRequestID: id) == .done)
        #expect(try await service.snapshot(of: ref).threads == before.threads)
        await #expect(throws: GitHubError.self) {
            try await service.comment(.addThread(try target(), body: "Late", review: review), pullRequestID: id)
        }
    }

    @Test func singleCommentAndReplyPublishAtOnce() async throws {
        let (service, directory) = try makeService()
        defer { try? FileManager.default.removeItem(at: directory) }
        let (ref, id) = (fixture.snapshot.pullRequest.ref, fixture.snapshot.pullRequest.nodeID)
        let target = try target(startLine: true)

        let added = try thread(try await service.comment(.addThread(target, body: "Single", review: nil), pullRequestID: id))
        #expect(added.path == target.path && added.line == target.line && added.startLine == target.startLine && added.side == target.side)
        let first = try #require(added.comments.first)
        #expect(!first.isPending && first.reviewID != nil)
        #expect(first.author?.login == FixturePullRequestService.viewerLogin && first.viewerCanUpdate && first.viewerCanDelete)

        let reply = try comment(try await service.comment(.reply(thread: added.id, body: "Reply", review: nil), pullRequestID: id))
        #expect(!reply.isPending && reply.body == "Reply")
        let stored = try #require(try await service.snapshot(of: ref).threads.first { $0.id == added.id })
        #expect(stored.comments == [first, reply])
        #expect(service.commentCalls.count == 2)

        let backwards = CommentTarget(path: target.path, side: target.side, line: target.line, startLine: target.line)
        await #expect(throws: GitHubError.self) {
            try await service.comment(.addThread(backwards, body: "x", review: nil), pullRequestID: id)
        }
    }

    @Test func editChangesOnlyTheViewersComments() async throws {
        let (service, directory) = try makeService()
        defer { try? FileManager.default.removeItem(at: directory) }
        let (ref, id) = (fixture.snapshot.pullRequest.ref, fixture.snapshot.pullRequest.nodeID)
        let comments = try await service.snapshot(of: ref).threads.flatMap(\.comments)
        let own = try #require(comments.first { $0.author?.login == FixturePullRequestService.viewerLogin })
        let other = try #require(comments.first { $0.author?.login != FixturePullRequestService.viewerLogin })
        #expect(own.viewerCanUpdate && own.viewerCanDelete)
        #expect(!other.viewerCanUpdate && !other.viewerCanDelete)

        let edited = try comment(try await service.comment(.edit(comment: own.id, body: "Edited"), pullRequestID: id))
        #expect(edited.body == "Edited" && edited.bodyText == "Edited" && edited.id == own.id && edited.createdAt == own.createdAt)
        #expect(try await service.snapshot(of: ref).threads.flatMap(\.comments).first { $0.id == own.id } == edited)
        await #expect(throws: GitHubError.self) {
            try await service.comment(.edit(comment: other.id, body: "Nope"), pullRequestID: id)
        }
    }

    @Test func deleteRemovesTheCommentAndAnEmptyThread() async throws {
        let (service, directory) = try makeService()
        defer { try? FileManager.default.removeItem(at: directory) }
        let (ref, id) = (fixture.snapshot.pullRequest.ref, fixture.snapshot.pullRequest.nodeID)
        let added = try thread(try await service.comment(.addThread(try target(), body: "One", review: nil), pullRequestID: id))
        let reply = try comment(try await service.comment(.reply(thread: added.id, body: "Two", review: nil), pullRequestID: id))

        #expect(try await service.comment(.delete(comment: reply.id), pullRequestID: id) == .done)
        #expect(try await service.snapshot(of: ref).threads.first { $0.id == added.id }?.comments == added.comments)
        #expect(try await service.comment(.delete(comment: added.comments[0].id), pullRequestID: id) == .done)
        #expect(try await service.snapshot(of: ref).threads.map(\.id) == fixture.snapshot.threads.map(\.id))
        await #expect(throws: GitHubError.self) {
            try await service.comment(.delete(comment: reply.id), pullRequestID: id)
        }
    }

    @Test func rejectionChangesNothing() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FixtureStore(directory: directory).write(fixture)
        let service = FixturePullRequestService(directory: directory, rejection: "Nope")
        let id = fixture.snapshot.pullRequest.nodeID
        let before = try await service.snapshot(of: fixture.snapshot.pullRequest.ref)
        await #expect(throws: GitHubError.rejected("Nope")) {
            try await service.comment(.addThread(try target(), body: "x", review: nil), pullRequestID: id)
        }
        #expect(try await service.snapshot(of: fixture.snapshot.pullRequest.ref) == before)
    }

    private func makeService() throws -> (FixturePullRequestService, URL) {
        let directory = temporaryDirectory()
        try FixtureStore(directory: directory).write(fixture)
        return (FixturePullRequestService(directory: directory), directory)
    }

    private func target(startLine: Bool = false) throws -> CommentTarget {
        let thread = try #require(fixture.snapshot.threads.first { $0.line != nil && $0.line! > 1 })
        let line = try #require(thread.line)
        return CommentTarget(path: thread.path, side: thread.side, line: line, startLine: startLine ? line - 1 : nil)
    }

    private func thread(_ result: CommentResult) throws -> ReviewThread {
        guard case let .thread(thread) = result else { throw FixtureCommentError.unexpected(result) }
        return thread
    }

    private func comment(_ result: CommentResult) throws -> ReviewComment {
        guard case let .comment(comment) = result else { throw FixtureCommentError.unexpected(result) }
        return comment
    }

    private func reviewID(_ result: CommentResult) throws -> String {
        guard case let .review(id) = result else { throw FixtureCommentError.unexpected(result) }
        return id
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "prfixtures-\(UUID().uuidString)", directoryHint: .isDirectory)
    }
}

private enum FixtureCommentError: Error {
    case unexpected(CommentResult)
}
