import Foundation
@testable import PRDetail
import PRModels
import Testing

struct SummaryTimelineTests {
    private let start = Date(timeIntervalSince1970: 1_788_000_000)

    @Test func repliesMoveUnderTheirRootAndReplyOnlyReviewsHide() {
        let root = inline("C1", replyTo: nil, minutes: 0)
        let conversation = Conversation(items: [
            .review(review("R1", state: .commented, body: "", comments: [root])),
            .review(review("R2", state: .commented, body: "", comments: [inline("C3", replyTo: "C1", minutes: 9), inline("C2", replyTo: "C1", minutes: 5)])),
            .review(review("R3", state: .approved, body: "", comments: [])),
        ], checks: [])
        let thread = ReviewThread(id: "T1", path: "a.ts", line: 1, startLine: nil, side: .right, isResolved: true, isOutdated: false, comments: [
            ReviewComment(id: "C1", author: nil, bodyText: "", createdAt: start),
        ])

        let entries = SummaryTimeline.entries(conversation, threads: [thread])

        #expect(entries.count == 2)
        guard case let .review(first, threads) = entries.first else { Issue.record("Expected R1 first"); return }
        #expect(first.id == "R1")
        #expect(threads.map { $0.replies.map(\.id) } == [["C2", "C3"]])
        #expect(threads.first?.isResolved == true)
        guard case let .review(approved, _) = entries.last else { Issue.record("Expected R3 last"); return }
        #expect(approved.id == "R3")
    }

    @Test(arguments: [
        ([Check.State.success, .skipped], SummaryTimeline.ChecksSummary.Tone.success, "1 skipped, 1 successful checks"),
        ([.success, .pending], .pending, "1 in progress, 1 successful checks"),
        ([.pending, .cancelled], .failure, "1 cancelled, 1 in progress checks"),
        ([.failure], .failure, "1 failing check"),
    ])
    func checksSummaryPicksWorstState(states: [Check.State], tone: SummaryTimeline.ChecksSummary.Tone, subtitle: String) {
        let summary = SummaryTimeline.checksSummary(states.map { check("c", $0) })
        #expect(summary?.tone == tone)
        #expect(summary?.subtitle == subtitle)
    }

    @Test func checksSortFailingFirstThenPendingThenSkippedLast() {
        let sorted = SummaryTimeline.sortedChecks([check("a", .skipped), check("b", .success), check("c", .pending), check("d", .failure)])
        #expect(sorted.map(\.name) == ["d", "c", "b", "a"])
    }

    @Test func hunkShowsLastFourLinesWithBothLineNumbers() {
        let html = SummaryHTML.hunk("@@ -10,4 +20,5 @@ func x\n a\n-b\n+c\n+d\n e\n\\ No newline at end of file")
        #expect(!html.contains(">a<"))
        #expect(html.contains(#"<tr class="del"><td class="num">11</td><td class="num"></td>"#))
        #expect(html.contains(#"<tr class="ctx"><td class="num">12</td><td class="num">23</td>"#))
        #expect(!html.contains("No newline"))
    }

    @Test func textFromGitHubIsEscaped() {
        let conversation = Conversation(items: [], checks: [
            Check(name: "<script>", workflow: nil, event: nil, state: .success, summary: nil, url: nil, avatarURL: nil,
                  isRequired: false, startedAt: nil, completedAt: nil),
        ])
        let html = SummaryHTML.conversation(conversation, threads: [], pullRequestAuthor: nil, now: start)
        #expect(!html.contains("<script>"))
        #expect(html.contains("&lt;script&gt;"))
    }

    @Test(arguments: [(30.0, "now"), (7_200, "2 hours ago"), (100_000, "yesterday"), (259_200, "3 days ago")])
    func relativeTimeUsesGitHubWording(seconds: TimeInterval, expected: String) {
        #expect(SummaryHTML.relative(start, now: start + seconds) == expected)
    }

    private func review(_ id: String, state: Review.State, body: String, comments: [InlineComment]) -> Review {
        Review(id: id, author: nil, state: state, bodyHTML: body, createdAt: start, url: nil, comments: comments)
    }

    private func inline(_ id: String, replyTo: String?, minutes: Double) -> InlineComment {
        InlineComment(id: id, author: nil, bodyHTML: "", createdAt: start + minutes * 60, path: "a.ts", diffHunk: "", replyToID: replyTo, isOutdated: false)
    }

    private func check(_ name: String, _ state: Check.State) -> Check {
        Check(name: name, workflow: nil, event: nil, state: state, summary: nil, url: nil, avatarURL: nil,
              isRequired: false, startedAt: nil, completedAt: nil)
    }
}

struct AvatarCacheTests {
    private let url = URL(string: "https://avatars.githubusercontent.com/u/1?s=80")!

    @Test func diskCopyServesANewCacheWithoutNetwork() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "avatars-\(UUID().uuidString)")
        let first = AvatarCache(directory: directory) { _ in Data([0x89, 1]) }
        _ = try await first.data(for: url)

        let offline = AvatarCache(directory: directory) { _ in throw URLError(.notConnectedToInternet) }
        #expect(try await offline.data(for: url) == Data([0x89, 1]))
    }

    @Test func concurrentRequestsShareOneDownload() async throws {
        let counter = Counter()
        let cache = AvatarCache(directory: FileManager.default.temporaryDirectory.appending(path: "avatars-\(UUID().uuidString)")) { _ in
            await counter.increment()
            try await Task.sleep(for: .milliseconds(50))
            return Data([1])
        }
        async let a = cache.data(for: url)
        async let b = cache.data(for: url)
        _ = try await (a, b)
        #expect(await counter.value == 1)
    }

    @Test func staleCopyIsServedThenRefreshed() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: "avatars-\(UUID().uuidString)")
        _ = try await AvatarCache(directory: directory) { _ in Data([1]) }.data(for: url)

        let counter = Counter()
        let stale = AvatarCache(directory: directory, maxAge: -1) { _ in
            await counter.increment()
            return Data([2])
        }
        #expect(try await stale.data(for: url) == Data([1]))
        for _ in 0..<100 where await counter.value == 0 { try await Task.sleep(for: .milliseconds(10)) }
        #expect(await counter.value == 1)
    }
}

private actor Counter {
    private(set) var value = 0
    func increment() { value += 1 }
}
