import Foundation
import PRModels

/// Open pull request rows for the list panel. The fixture pull request is the oldest row of `mine` when `repo` holds it.
public enum SyntheticPullRequestList {
    public static func make(repo: RepoRef, scope: PullRequestListScope, current: PullRequest, now: Date) -> PullRequestList {
        let rows = scope == .mine ? mine : others
        var pullRequests = rows.enumerated().map { index, row in
            PullRequestSummary(
                ref: PRRef(owner: repo.owner, repo: repo.name, number: row.number),
                title: row.title, isDraft: row.isDraft,
                author: row.author.map { Actor(login: $0, avatarURL: nil) },
                updatedAt: now.addingTimeInterval(-row.age),
                commentCount: row.comments, checks: row.checks, reviewDecision: row.review
            )
        }
        if scope == .mine, RepoRef(current.ref) == repo {
            pullRequests.append(
                PullRequestSummary(
                    ref: current.ref, title: current.title, isDraft: current.isDraft, author: current.author,
                    updatedAt: now.addingTimeInterval(-10 * day), commentCount: 3, checks: .success, reviewDecision: .reviewRequired
                )
            )
        }
        return PullRequestList(pullRequests: pullRequests, totalCount: pullRequests.count)
    }

    private struct Row {
        let number: Int
        let title: String
        let isDraft: Bool
        let author: String?
        let age: TimeInterval
        let comments: Int
        let checks: PullRequestSummary.ChecksState?
        let review: PullRequestSummary.ReviewDecision?
    }

    private static let hour: TimeInterval = 3_600
    private static let day: TimeInterval = 86_400

    private static let mine: [Row] = [
        Row(
            number: 6712, title: "feat(checkout): hold stock while a buyer pays", isDraft: false, author: "rik",
            age: 2 * hour, comments: 12, checks: .failure, review: .changesRequested),
        Row(
            number: 6698, title: "fix(auth): refresh the session before it expires on a sleeping laptop", isDraft: false,
            author: "rik", age: 7 * hour, comments: 0, checks: .pending, review: .reviewRequired),
        Row(
            number: 6641, title: "chore(deps): upgrade the Workers runtime types", isDraft: true, author: "rik",
            age: 3 * day, comments: 1, checks: nil, review: nil),
        Row(
            number: 6590, title: "perf(views): build the first view one model step sooner so the assistant answers before the page settles",
            isDraft: false, author: "rik", age: 9 * day, comments: 5, checks: .success, review: .approved),
        Row(
            number: 6575, title: "fix(images): keep the upload order when a retry finishes first", isDraft: false, author: "rik",
            age: 4 * day, comments: 2, checks: .success, review: .reviewRequired),
        Row(
            number: 6550, title: "feat(vault): sign in with a passkey", isDraft: true, author: "rik",
            age: 5 * day, comments: 0, checks: .pending, review: nil),
        Row(
            number: 6521, title: "chore(ci): cache the Tuist dependencies", isDraft: false, author: "rik",
            age: 6 * day, comments: 0, checks: .success, review: .approved),
    ]

    private static let others: [Row] = [
        Row(
            number: 6729, title: "fix(connection-provisioning): requeue a row whose Workflow instance stays queued", isDraft: false,
            author: "marvin", age: 20 * 60, comments: 4, checks: .success, review: .approved),
        Row(
            number: 6726, title: "feat(assistant): show usage per conversation", isDraft: false, author: "emmy",
            age: 1 * hour, comments: 0, checks: .pending, review: .reviewRequired),
        Row(
            number: 6720, title: "fix(dev-stack): keep a wrangler dev reload from exiting on a Hyperdrive socket reset", isDraft: false,
            author: "dependabot", age: 5 * hour, comments: 2, checks: .failure, review: nil),
        Row(
            number: 6703, title: "docs(platform): describe the Files retention rules", isDraft: true, author: "geoff",
            age: 1 * day, comments: 0, checks: nil, review: nil),
        Row(
            number: 6688, title: "feat(browser): solve a CAPTCHA in a frame and resume the task", isDraft: false, author: nil,
            age: 2 * day, comments: 27, checks: .success, review: .changesRequested),
        Row(
            number: 6660, title: "refactor(images): move the upload queue to one Durable Object per store", isDraft: false,
            author: "emmy", age: 4 * day, comments: 9, checks: .success, review: .reviewRequired),
        Row(
            number: 6612, title: "test(e2e): boot one database per run", isDraft: false, author: "marvin",
            age: 12 * day, comments: 1, checks: .failure, review: nil),
    ]
}
