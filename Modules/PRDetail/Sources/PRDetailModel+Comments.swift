import DiffView
import Foundation
import GitHubKit
import PRModels

extension PRDetailModel {
    /// Posts a comment box. The box closes when GitHub stores the comment, or shows GitHub's error.
    func submitComment(_ key: CommentComposer, body: String, submit: CommentSubmit) {
        let diff = filesController.diff
        guard let id = pullRequestNodeID else { return diff.composerDidFinish(key, error: "The pull request has not loaded yet.") }
        guard !isFinishingReview else { return diff.composerDidFinish(key, error: "The review is being submitted. Post again when it is done.") }
        commentsInFlight += 1
        Task {
            defer { commentsInFlight -= 1 }
            do {
                let review = submit == .review ? try await ensurePendingReview(pullRequestID: id) : nil
                switch key {
                case let .newThread(target):
                    let result = try await service.comment(.addThread(target, body: body, review: review), pullRequestID: id)
                    guard case let .thread(thread) = result else { throw CommentError.unexpectedResult }
                    updateThreads { $0.append(thread) }
                case let .reply(threadID):
                    let result = try await service.comment(.reply(thread: threadID, body: body, review: review), pullRequestID: id)
                    guard case let .comment(comment) = result else { throw CommentError.unexpectedResult }
                    updateThread(threadID) { $0 + [comment] }
                case let .edit(commentID):
                    let result = try await service.comment(.edit(comment: commentID, body: body), pullRequestID: id)
                    guard case let .comment(comment) = result else { throw CommentError.unexpectedResult }
                    updateThread(containing: commentID) { comments in comments.map { $0.id == commentID ? comment : $0 } }
                }
                diff.composerDidFinish(key, error: nil)
            } catch {
                diff.composerDidFinish(key, error: "Could not post the comment: \(error.localizedDescription)")
            }
        }
    }

    func deleteComment(_ commentID: String) {
        guard !isFinishingReview, let id = pullRequestNodeID else { return }
        commentsInFlight += 1
        Task {
            defer { commentsInFlight -= 1 }
            do {
                _ = try await service.comment(.delete(comment: commentID), pullRequestID: id)
                updateThread(containing: commentID) { $0.filter { $0.id != commentID } }
            } catch {
                errorBanner = "Could not delete the comment: \(error.localizedDescription)"
            }
        }
    }

    /// Deletes the pending review and its comments.
    public func discardPendingReview() {
        sheet = nil
        guard commentsInFlight == 0, !isFinishingReview, let review = pendingReviewID, let id = pullRequestNodeID else { return }
        isFinishingReview = true
        Task {
            defer { isFinishingReview = false }
            do {
                _ = try await service.comment(.discardReview(review: review), pullRequestID: id)
                pendingReviewID = nil
                updateThreads { threads in
                    threads = threads.compactMap { thread in
                        let kept = thread.comments.filter { !$0.isPending }
                        return kept.isEmpty ? nil : thread.replacing(comments: kept)
                    }
                }
            } catch {
                errorBanner = "Could not discard the review: \(error.localizedDescription)"
            }
        }
    }

    /// The submitted review's comments are public now.
    func publishPendingComments() {
        pendingReviewID = nil
        updateThreads { threads in
            threads = threads.map { thread in thread.replacing(comments: thread.comments.map { $0.isPending ? $0.published() : $0 }) }
        }
    }

    private var pullRequestNodeID: String? { pullRequest?.nodeID ?? pullRequestID }

    private func ensurePendingReview(pullRequestID: String) async throws -> String {
        if let pendingReviewID { return pendingReviewID }
        if let startingReview { return try await startingReview.value }
        guard let commit = pullRequest?.headOid else { throw CommentError.unexpectedResult }
        let task = Task { [service] in
            let result = try await service.comment(.startReview(commitOid: commit), pullRequestID: pullRequestID)
            guard case let .review(id) = result else { throw CommentError.unexpectedResult }
            return id
        }
        startingReview = task
        defer { startingReview = nil }
        let id = try await task.value
        pendingReviewID = id
        return id
    }

    private func updateThreads(_ change: (inout [ReviewThread]) -> Void) {
        var threads = threads ?? []
        change(&threads)
        receiveThreads(threads)
    }

    private func updateThread(_ threadID: String, _ change: ([ReviewComment]) -> [ReviewComment]) {
        updateThreads { threads in
            threads = threads.compactMap { thread in
                guard thread.id == threadID else { return thread }
                let comments = change(thread.comments)
                return comments.isEmpty ? nil : thread.replacing(comments: comments)
            }
        }
    }

    private func updateThread(containing commentID: String, _ change: ([ReviewComment]) -> [ReviewComment]) {
        guard let thread = threads?.first(where: { $0.comments.contains { $0.id == commentID } }) else { return }
        updateThread(thread.id, change)
    }
}

private enum CommentError: LocalizedError {
    case unexpectedResult

    var errorDescription: String? { "GitHub sent an unexpected answer." }
}

extension ReviewThread {
    func replacing(comments: [ReviewComment]) -> ReviewThread {
        ReviewThread(
            id: id, path: path, line: line, startLine: startLine, side: side, isResolved: isResolved, isOutdated: isOutdated,
            comments: comments
        )
    }
}

extension ReviewComment {
    func published() -> ReviewComment {
        ReviewComment(
            id: id, author: author, bodyText: bodyText, body: body, createdAt: createdAt, isPending: false,
            viewerCanUpdate: viewerCanUpdate, viewerCanDelete: viewerCanDelete, reviewID: reviewID
        )
    }
}
