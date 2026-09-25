import DiffView
import Foundation
import GitHubKit
import PRFixtures
import PRModels
import ReviewRules
import Testing

@testable import PRDetail

@MainActor
struct ReviewCommentTests {
    private let path = ".github/workflows/stream-reconcile.yml"

    @Test func aSingleCommentShowsInTheDiffWithoutALoad() async throws {
        let (model, service) = try await loadedModel()
        let key = CommentComposer.newThread(CommentTarget(path: path, side: .right, line: 15))
        let before = try #require(model.threads).count
        model.filesController.diff.openComposer(key)
        model.submitComment(key, body: "Pin the image.", submit: .single)
        try await waitUntil { model.filesController.diff.openComposers.isEmpty }
        #expect(model.threads?.count == before + 1)
        #expect(model.pendingCommentCount == 0)
        #expect(model.pendingReviewID == nil)
        #expect(service.commentCalls.map(\.action) == [.addThread(CommentTarget(path: path, side: .right, line: 15), body: "Pin the image.", review: nil)])
    }

    @Test func reviewCommentsStartOneReviewAndStayPendingUntilSubmitted() async throws {
        let (model, service) = try await loadedModel(latency: .milliseconds(50))
        let first = CommentComposer.newThread(CommentTarget(path: path, side: .right, line: 15))
        let second = CommentComposer.newThread(CommentTarget(path: path, side: .right, line: 14))
        model.submitComment(first, body: "One", submit: .review)
        model.submitComment(second, body: "Two", submit: .review)
        try await waitUntil { model.pendingCommentCount == 2 }
        #expect(service.commentCalls.filter { if case .startReview = $0.action { true } else { false } }.count == 1)
        #expect(model.pendingReviewID != nil)
        #expect(model.filesController.diff.hasPendingReview)
        #expect(model.canSubmit(.comment, body: ""))

        model.submitReview(.comment, body: "")
        await model.settleAction()
        #expect(model.pendingCommentCount == 0)
        #expect(model.pendingReviewID == nil)
        #expect(!model.filesController.diff.hasPendingReview)
    }

    @Test func theReviewWaitsForCommentsInFlightAndGitHubResetsItsID() async throws {
        let (model, _) = try await loadedModel(latency: .milliseconds(100))
        model.submitComment(.newThread(CommentTarget(path: path, side: .right, line: 15)), body: "One", submit: .review)
        #expect(!model.canSubmit(.comment, body: "Done"))
        try await waitUntil { model.commentsInFlight == 0 }
        #expect(model.canSubmit(.comment, body: "Done"))

        let published = try #require(model.threads).map { $0.replacing(comments: $0.comments.map { $0.published() }) }
        model.receiveThreads(published, fromGitHub: true)
        #expect(model.pendingReviewID == nil)
    }

    @Test func discardRemovesOnlyThePendingComments() async throws {
        let (model, _) = try await loadedModel()
        let before = try #require(model.threads)
        model.submitComment(.newThread(CommentTarget(path: path, side: .right, line: 15)), body: "Draft", submit: .review)
        try await waitUntil { model.pendingCommentCount == 1 }
        model.discardPendingReview()
        try await waitUntil { model.pendingReviewID == nil }
        #expect(model.threads == before)
    }

    @Test func editAndDeleteChangeOnlyThatComment() async throws {
        let (model, _) = try await loadedModel()
        let own = try #require(model.threads?.flatMap(\.comments).first { $0.viewerCanUpdate })
        model.submitComment(.edit(comment: own.id), body: "Changed", submit: .update)
        try await waitUntil { model.threads?.flatMap(\.comments).first { $0.id == own.id }?.body == "Changed" }

        let count = try #require(model.threads).flatMap(\.comments).count
        model.deleteComment(own.id)
        try await waitUntil { model.threads?.flatMap(\.comments).count == count - 1 }
        #expect(model.threads?.flatMap(\.comments).contains { $0.id == own.id } == false)
    }

    @Test func aRefusedCommentKeepsTheBoxWithGitHubsMessage() async throws {
        let (model, _) = try await loadedModel(rejection: "Line is outside the diff.")
        let key = CommentComposer.newThread(CommentTarget(path: path, side: .right, line: 15))
        let before = model.threads
        model.filesController.diff.openComposer(key)
        model.submitComment(key, body: "Hi", submit: .single)
        try await waitUntil { model.filesController.diff.composerError(key) != nil }
        #expect(model.filesController.diff.openComposers == [key])
        #expect(model.filesController.diff.composerError(key)?.contains("Line is outside the diff.") == true)
        #expect(model.threads == before)
    }

    private func loadedModel(latency: Duration = .zero, rejection: String? = nil) async throws -> (PRDetailModel, FixturePullRequestService) {
        let directory = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Fixtures/synthetic-50")
        let service = FixturePullRequestService(directory: directory, latency: latency, rejection: rejection)
        let model = PRDetailModel(ref: try await service.pullRequestRef(), service: service, highlighter: nil, rules: ReviewRules())
        model.filesController.view.frame = NSRect(x: 0, y: 0, width: 1_400, height: 900)
        await model.load()
        return (model, service)
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<300 where !condition() { try await Task.sleep(for: .milliseconds(10)) }
        #expect(condition())
    }
}
