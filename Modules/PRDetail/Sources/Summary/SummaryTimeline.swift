import Foundation
import PRModels

/// The Conversation page entries in GitHub order, with inline replies moved under their first comment.
nonisolated enum SummaryTimeline {
    enum Entry: Equatable {
        case comment(IssueComment)
        case review(Review, threads: [InlineThread])
    }

    struct InlineThread: Equatable {
        let root: InlineComment
        let replies: [InlineComment]
        let isResolved: Bool
        let isOutdated: Bool
    }

    /// A review that only replies to other threads has no entry: GitHub shows the replies in those threads.
    static func entries(_ conversation: Conversation, threads: [ReviewThread]) -> [Entry] {
        let reviews = conversation.items.compactMap { if case let .review(review) = $0 { review } else { nil } }
        let replies = Dictionary(grouping: reviews.flatMap(\.comments).filter { $0.replyToID != nil }) { $0.replyToID! }
        let threadByRoot = Dictionary(threads.compactMap { thread in thread.comments.first.map { ($0.id, thread) } }) { first, _ in first }

        return conversation.items.compactMap { item in
            switch item {
            case let .comment(comment):
                return .comment(comment)
            case let .review(review):
                let inline = review.comments.filter { $0.replyToID == nil }.map { root in
                    let thread = threadByRoot[root.id]
                    return InlineThread(
                        root: root,
                        replies: (replies[root.id] ?? []).sorted { $0.createdAt < $1.createdAt },
                        isResolved: thread?.isResolved ?? false,
                        isOutdated: root.isOutdated || thread?.isOutdated == true
                    )
                }
                if review.state == .commented, review.bodyHTML.isEmpty, inline.isEmpty { return nil }
                return .review(review, threads: inline)
            }
        }
    }

    struct ChecksSummary: Equatable {
        enum Tone { case success, failure, pending }
        let tone: Tone
        let title: String
        let subtitle: String
    }

    static func checksSummary(_ checks: [Check]) -> ChecksSummary? {
        guard !checks.isEmpty else { return nil }
        let counts = Dictionary(grouping: checks, by: \.state).mapValues(\.count)
        let parts: [(Check.State, String)] = [
            (.failure, "failing"), (.cancelled, "cancelled"), (.pending, "in progress"),
            (.skipped, "skipped"), (.neutral, "neutral"), (.success, "successful"),
        ]
        let subtitle = parts.compactMap { state, word in counts[state].map { "\($0) \(word)" } }.joined(separator: ", ")
            + (checks.count == 1 ? " check" : " checks")
        if counts[.failure] != nil || counts[.cancelled] != nil {
            return ChecksSummary(tone: .failure, title: "Some checks were not successful", subtitle: subtitle)
        }
        if counts[.pending] != nil {
            return ChecksSummary(tone: .pending, title: "Some checks haven’t completed yet", subtitle: subtitle)
        }
        return ChecksSummary(tone: .success, title: "All checks have passed", subtitle: subtitle)
    }

    /// Failing first, then in progress, then the rest; by name inside each group.
    static func sortedChecks(_ checks: [Check]) -> [Check] {
        func rank(_ state: Check.State) -> Int {
            switch state {
            case .failure, .cancelled: 0
            case .pending: 1
            case .success, .neutral: 2
            case .skipped: 3
            }
        }
        return checks.sorted {
            (rank($0.state), displayName($0).localizedLowercase) < (rank($1.state), displayName($1).localizedLowercase)
        }
    }

    static func displayName(_ check: Check) -> String {
        let name = check.workflow.map { "\($0) / \(check.name)" } ?? check.name
        return check.event.map { "\(name) (\($0))" } ?? name
    }

    static func checkDescription(_ check: Check) -> String {
        if let summary = check.summary, !summary.isEmpty { return summary }
        var duration: String?
        if let started = check.startedAt, let completed = check.completedAt { duration = formatDuration(completed.timeIntervalSince(started)) }
        switch check.state {
        case .success: return duration.map { "Successful in \($0)" } ?? "Successful"
        case .failure: return duration.map { "Failing after \($0)" } ?? "Failing"
        case .cancelled: return duration.map { "Cancelled after \($0)" } ?? "Cancelled"
        case .neutral: return duration.map { "Completed in \($0)" } ?? "Completed"
        case .skipped: return "Skipped"
        case .pending: return check.startedAt == nil ? "Queued" : "In progress"
        }
    }

    static func formatDuration(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        if total < 60 { return "\(total)s" }
        if total < 3_600 { return "\(total / 60)m" }
        return "\(total / 3_600)h \(total % 3_600 / 60)m"
    }
}
