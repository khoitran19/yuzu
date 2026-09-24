import Foundation
import GitHubKit
import PRFixtures
import PRModels
import ReviewRules
import Testing

@testable import PRDetail

nonisolated private func status(_ change: (inout MergeStatus) -> Void = { _ in }) -> MergeStatus {
    var status = MergeStatus(
        state: .open, isDraft: false, headOid: "h3ad", mergeable: .mergeable, mergeStateStatus: .clean, reviewDecision: nil,
        viewerDidAuthor: false, viewerCanUpdate: true, viewerCanMerge: true, viewerCanMergeAsAdmin: false,
        viewerCanEnableAutoMerge: true, viewerCanDisableAutoMerge: true, viewerReviewState: nil,
        allowedMethods: [.merge, .squash, .rebase], defaultMethod: .squash, autoMergeAllowed: true, isMergeQueueEnabled: false,
        queueEntry: nil, mergeQueueURL: nil, autoMerge: nil
    )
    change(&status)
    return status
}

nonisolated private let queueEntry = MergeStatus.QueueEntry(
    position: 2, totalCount: 5, state: .queued, estimatedSecondsToMerge: 600, enqueuedAt: nil)

struct MergeBoxStateTests {
    @Test(arguments: [
        (
            status {
                $0.state = .merged; $0.isDraft = true
            }, MergeBoxState.Action.merged
        ),
        (status { $0.state = .closed }, .closed),
        (
            status {
                $0.isDraft = true; $0.queueEntry = queueEntry
            }, .draft(canMarkReady: true)
        ),
        (
            status {
                $0.isDraft = true; $0.viewerCanUpdate = false
            }, .draft(canMarkReady: false)
        ),
        (
            status {
                $0.queueEntry = queueEntry; $0.autoMerge = .init(method: .merge, enabledBy: nil)
            }, .queued(canDequeue: true)
        ),
        (
            status {
                $0.queueEntry = queueEntry; $0.viewerCanMerge = false
            }, .queued(canDequeue: false)
        ),
        (
            status {
                $0.queueEntry = queueEntry; $0.viewerCanMerge = false; $0.viewerDidAuthor = true
            }, .queued(canDequeue: true)
        ),
        (
            status {
                $0.autoMerge = .init(method: .squash, enabledBy: "rik"); $0.viewerCanMerge = false
            }, .autoMerge(canDisable: true)
        ),
        (
            status {
                $0.autoMerge = .init(method: .squash, enabledBy: "rik"); $0.viewerCanDisableAutoMerge = false
            }, .autoMerge(canDisable: false)
        ),
        (
            status {
                $0.viewerCanMerge = false; $0.mergeable = .conflicting
            }, .noPermission
        ),
        (
            status {
                $0.mergeable = .conflicting; $0.isMergeQueueEnabled = true
            }, .conflicts
        ),
        (status { $0.mergeStateStatus = .dirty }, .conflicts),
        (status { $0.isMergeQueueEnabled = true }, .enqueue),
        (status { $0.mergeStateStatus = .hasHooks }, .merge),
        (status { $0.mergeStateStatus = .unstable }, .merge),
        (status { $0.mergeStateStatus = .blocked }, .enableAutoMerge),
        (status { $0.mergeStateStatus = .behind }, .enableAutoMerge),
        (
            status {
                $0.mergeStateStatus = .unknown; $0.mergeable = .unknown
            }, .enableAutoMerge
        ),
        (
            status {
                $0.mergeStateStatus = .blocked; $0.autoMergeAllowed = false
            }, .blocked
        ),
        (
            status {
                $0.mergeStateStatus = .blocked; $0.viewerCanEnableAutoMerge = false
            }, .blocked
        ),
    ])
    func actionFollowsGitHubPrecedence(status: MergeStatus, expected: MergeBoxState.Action) {
        #expect(MergeBoxState(status).action == expected)
    }

    @Test func adminsCanBypassOnlyWhenTheNormalMergeIsNotAvailable() {
        let admin = { (change: (inout MergeStatus) -> Void) in
            MergeBoxState(
                status {
                    $0.viewerCanMergeAsAdmin = true; change(&$0)
                })
        }
        #expect(!admin { _ in }.canBypass)
        #expect(admin { $0.mergeStateStatus = .blocked }.canBypass)
        #expect(
            admin {
                $0.mergeStateStatus = .blocked; $0.autoMergeAllowed = false
            }.canBypass)
        #expect(admin { $0.isMergeQueueEnabled = true }.canBypass)
        #expect(!admin { $0.mergeable = .conflicting }.canBypass)
        #expect(!admin { $0.queueEntry = queueEntry }.canBypass)
        #expect(!MergeBoxState(status { $0.mergeStateStatus = .blocked }).canBypass)
    }

    @Test func primaryActionIsTheMergeButton() {
        #expect(MergeBoxState(status()).primary == .merge)
        #expect(MergeBoxState(status { $0.isMergeQueueEnabled = true }).primary == .enqueue)
        #expect(MergeBoxState(status { $0.mergeStateStatus = .blocked }).primary == .enableAutoMerge)
        #expect(MergeBoxState(status { $0.isDraft = true }).primary == nil)
    }

    @Test func sidebarOffersOnlyWhatTheViewerCanDo() {
        let author = SidebarState(status: status { $0.viewerDidAuthor = true }, state: .open, isDraft: false)
        #expect(!author.actions.contains(.approve))
        #expect(author.actions.isSuperset(of: [.merge, .chooseMethod, .convertToDraft]))
        let merged = SidebarState(status: status { $0.state = .merged }, state: .open, isDraft: false)
        #expect(merged.actions.isEmpty)
        let noStatus = SidebarState(status: nil, state: .open, isDraft: false)
        #expect(noStatus.actions == [.approve, .requestChanges])
        let draft = SidebarState(status: status { $0.isDraft = true }, state: .open, isDraft: true)
        #expect(draft.actions == [.approve, .requestChanges, .markReady])
    }
}

struct SidebarHTMLTests {
    private func content(_ status: MergeStatus?, checks: [Check] = [], running: SidebarAction? = nil) -> SidebarContent {
        SidebarContent(
            checks: checks, status: status, state: .open, isDraft: false, method: .squash, running: running, reviewedHead: "h3ad"
        )
    }

    @Test func textFromGitHubIsEscaped() {
        let check = Check(
            name: "<img src=x>", workflow: nil, event: nil, state: .failure, summary: nil, url: nil, avatarURL: nil,
            isRequired: true, startedAt: nil, completedAt: nil
        )
        let html = SummaryHTML.sidebar(
            content(status { $0.autoMerge = .init(method: .squash, enabledBy: "<script>x</script>") }, checks: [check]))
        #expect(!html.contains("<script>") && !html.contains("<img src=x>"))
        #expect(html.contains("&lt;script&gt;x&lt;/script&gt;"))
        #expect(html.contains("&lt;img src=x&gt;"))
    }

    @Test func runningActionShowsItsVerbAndDisablesEveryButton() {
        let html = SummaryHTML.sidebar(
            content(
                status {
                    $0.mergeStateStatus = .blocked; $0.viewerCanMergeAsAdmin = true
                }, running: .enableAutoMerge))
        #expect(html.contains("Enabling auto-merge…"))
        #expect(html.contains("spinner"))
        let buttons = html.components(separatedBy: "<button").dropFirst()
        #expect(buttons.count >= 5)
        #expect(buttons.allSatisfy { $0.prefix(while: { $0 != ">" }).contains(" disabled") })
    }

    @Test func buttonsCarryTheirShortcutInTheTooltip() {
        let html = SummaryHTML.sidebar(content(status()))
        #expect(html.contains(#"data-action="approve" title="Approve (⇧⌘A)""#))
        #expect(html.contains(#"data-action="merge" title="Squash and merge (⇧⌘↩)""#))
        #expect(html.contains(#"data-action="chooseMethod""#))
    }

    @Test func queuedRowShowsPositionAndEstimate() {
        let html = SummaryHTML.sidebar(
            content(
                status {
                    $0.queueEntry = queueEntry; $0.mergeQueueURL = URL(string: "https://github.com/o/r/queue/main")
                }))
        #expect(html.contains("Queued to merge"))
        #expect(html.contains("Position 2 of 5 · about 10 min"))
        #expect(html.contains(#"data-action="dequeue""#))
        #expect(html.contains(#"data-action="viewMergeQueue""#))
        #expect(!html.contains(#"data-action="merge""#))
    }

    @Test func withoutMergeStatusOnlyReviewAndChecksShow() {
        let check = Check(
            name: "ci", workflow: nil, event: nil, state: .success, summary: nil, url: nil, avatarURL: nil,
            isRequired: false, startedAt: nil, completedAt: nil
        )
        let html = SummaryHTML.sidebar(content(nil, checks: [check]))
        #expect(html.contains(#"data-action="approve""#))
        #expect(html.contains("All checks have passed"))
        #expect(!html.contains(#"data-action="merge"#))
        #expect(!html.contains("Convert to draft"))
    }
}

@MainActor
struct PullRequestActionTests {
    @Test func approveRunsThroughTheSheetAndReloadsTheTimeline() async throws {
        let (model, service) = try await loadedModel(latency: .milliseconds(150))
        model.handle(.approve)
        #expect(model.sheet == .review(.approve))

        model.submitReview(.approve, body: "Ship it")
        #expect(model.sheet == nil)
        #expect(model.runningAction == .approve)
        #expect(!model.canReview && !model.canMerge)
        try await waitUntil { model.summaryPage?.sidebar.contains("Approving…") == true }

        await model.settleAction()
        #expect(service.performCalls.map(\.action) == [.review(.approve, body: "Ship it")])
        #expect(service.conversationCalls == 1)
        #expect(model.runningAction == nil)
        #expect(model.mergeStatus?.viewerReviewState == .approved)
        try await waitUntil { model.summaryPage?.timeline.contains("Ship it") == true }
        #expect(model.summaryPage?.sidebar.contains("You approved these changes") == true)
    }

    @Test func requestChangesNeedsAComment() async throws {
        let (model, service) = try await loadedModel()
        model.submitReview(.requestChanges, body: "  \n")
        await model.settleAction()
        #expect(service.performCalls.isEmpty)
    }

    @Test func mergeUpdatesTheHeaderAndStopsPolling() async throws {
        let (model, service) = try await loadedModel(preset: .clean)
        let head = try #require(model.pullRequest?.headOid)
        model.runPrimaryMergeAction()
        #expect(model.sheet == .merge(bypass: false, headOid: head))

        model.confirmMerge(method: .squash, title: "Title", body: nil, bypass: false, headOid: head)
        await model.settleAction()
        #expect(service.performCalls.map(\.action) == [.merge(.squash, headOid: head, title: "Title", body: nil)])
        #expect(model.pullRequest?.state == .merged)
        try await waitUntil { model.summaryPage?.sidebar.contains("Pull request successfully merged") == true }
        let calls = service.statusCalls
        try await Task.sleep(for: .milliseconds(100))
        #expect(service.statusCalls == calls)
    }

    @Test func enqueueRunsAtOnceAndShowsQueued() async throws {
        let (model, service) = try await loadedModel(preset: .queueEnabled)
        model.handle(.enqueue)
        #expect(model.sheet == nil)
        await model.settleAction()
        #expect(service.performCalls.map(\.action) == [.enqueue(headOid: try #require(model.pullRequest?.headOid))])
        #expect(model.isQueued)
        try await waitUntil { model.summaryPage?.sidebar.contains("Queued to merge") == true }
    }

    @Test func rejectedActionShowsTheBannerAndRestoresTheSidebar() async throws {
        let (model, service) = try await loadedModel(preset: .queueEnabled, rejection: "Merge queue is full.")
        try await waitUntil { model.summaryPage?.sidebar.contains("Merge when ready") == true }
        let before = try #require(model.summaryPage?.sidebar)
        model.handle(.enqueue)
        await model.settleAction()
        #expect(service.performCalls.count == 1)
        #expect(model.errorBanner == "Could not add the pull request to the merge queue: Merge queue is full.")
        #expect(model.runningAction == nil)
        #expect(!model.isQueued)
        try await waitUntil { model.summaryPage?.sidebar == before }
    }

    @Test func actionsTheSidebarDoesNotOfferAreIgnored() async throws {
        let (model, service) = try await loadedModel(preset: .author)
        model.handle(.approve)
        model.handle(.dequeue)
        model.handle(.markReady)
        await model.settleAction()
        #expect(model.sheet == nil)
        #expect(service.performCalls.isEmpty)
    }

    @Test func newCommitsBlockMergingUntilReload() async throws {
        let (model, service) = try await loadedModel(preset: .newCommits)
        let reviewed = try #require(model.pullRequest?.headOid)
        #expect(model.mergeStatus?.headOid != reviewed)
        let sidebar = try #require(model.summaryPage?.sidebar)
        #expect(sidebar.contains("New commits were pushed."))
        #expect(sidebar.contains(#"data-action="reload""#))
        #expect(sidebar.contains(#"data-action="enableAutoMerge" title="Enable auto-merge (squash) (⇧⌘↩)" disabled"#))
        #expect(!model.canMerge)

        model.runPrimaryMergeAction()
        model.handle(.enableAutoMerge)
        model.handle(.bypassMerge)
        model.confirmMerge(method: .squash, title: nil, body: nil, bypass: true, headOid: reviewed)
        #expect(model.sheet == nil)
        await model.settleAction()
        #expect(service.performCalls.isEmpty)

        #expect(model.canReview)
        #expect(model.draftToggleTitle == "Convert to Draft")
        model.handle(.approve)
        #expect(model.sheet == .review(.approve))
    }

    @Test func mergeSendsTheHeadCapturedWhenTheSheetOpened() async throws {
        let (model, service) = try await loadedModel(preset: .clean)
        model.handle(.merge)
        guard case let .merge(_, captured) = model.sheet else { Issue.record("Expected the merge sheet"); return }
        #expect(captured == model.pullRequest?.headOid)
        model.confirmMerge(method: .merge, title: nil, body: nil, bypass: false, headOid: captured)
        await model.settleAction()
        #expect(service.performCalls.map(\.action) == [.merge(.merge, headOid: captured, title: nil, body: nil)])
    }

    @Test func failedRefreshAfterAnActionShowsABannerAndRetries() async throws {
        let directory = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Fixtures/synthetic-50")
        let service = FlakyStatusService(base: FixturePullRequestService(directory: directory, mergeStatus: .clean))
        let model = PRDetailModel(
            ref: try await service.base.pullRequestRef(), service: service, highlighter: nil, rules: ReviewRules(),
            refreshRetryInterval: .milliseconds(20)
        )
        await model.load()
        let head = try #require(model.pullRequest?.headOid)
        service.failures = 1
        model.confirmMerge(method: .squash, title: nil, body: nil, bypass: false, headOid: head)
        await model.settleAction()
        #expect(model.errorBanner?.hasPrefix("Done, but could not refresh from GitHub:") == true)
        #expect(model.pullRequest?.state == .open)

        try await waitUntil { model.pullRequest?.state == .merged }
        #expect(service.statusCalls == 2)
        #expect(model.errorBanner == nil)
        #expect(!model.canMerge)
    }

    @Test func draftToggleMarksReady() async throws {
        let (model, service) = try await loadedModel(preset: .draft)
        #expect(model.draftToggleTitle == "Mark as Ready for Review")
        #expect(model.pullRequest?.isDraft == true)
        model.toggleDraft()
        await model.settleAction()
        #expect(service.performCalls.map(\.action) == [.markReadyForReview])
        #expect(model.pullRequest?.isDraft == false)
        #expect(model.draftToggleTitle == "Convert to Draft")
    }

    @Test func selectedMethodStaysAndIsSent() async throws {
        let (model, service) = try await loadedModel()
        #expect(model.mergeMethod == .squash)
        model.selectMethod(.rebase)
        model.handle(.enableAutoMerge)
        await model.settleAction()
        #expect(service.performCalls.map(\.action) == [.enableAutoMerge(.rebase, headOid: try #require(model.pullRequest?.headOid))])
        #expect(model.mergeMethod == .rebase)
    }

    private func loadedModel(
        preset: MergeStatusPreset? = nil, rejection: String? = nil, latency: Duration = .zero
    ) async throws -> (PRDetailModel, FixturePullRequestService) {
        let directory = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Fixtures/synthetic-50")
        let service = FixturePullRequestService(directory: directory, latency: latency, mergeStatus: preset, rejection: rejection)
        let model = PRDetailModel(
            ref: try await service.pullRequestRef(), service: service, highlighter: nil, rules: ReviewRules(),
            statusRefreshInterval: .milliseconds(10), mergeableRefreshInterval: .milliseconds(10)
        )
        model.openExternal = { _ in Issue.record("No test opens the browser") }
        await model.load()
        try await waitUntil { model.summaryPage?.sidebar.isEmpty == false }
        return (model, service)
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<200 where !condition() { try await Task.sleep(for: .milliseconds(10)) }
        #expect(condition())
    }
}

@MainActor
struct StatusPollingTests {
    @Test func unknownMergeabilityRetriesFiveTimesThenStops() async throws {
        let service = ScriptedStatusService()
        let unknown = status {
            $0.mergeable = .unknown; $0.mergeStateStatus = .unknown
        }
        service.responses = Array(repeating: PullRequestStatus(checks: [], merge: unknown), count: 10)
        let model = PRDetailModel(
            ref: PRRef(owner: "o", repo: "r", number: 1), service: service, highlighter: nil, rules: ReviewRules(),
            statusRefreshInterval: .seconds(60), mergeableRefreshInterval: .milliseconds(5)
        )
        let loading = Task { await model.load() }
        service.continuation.yield(.conversation(Conversation(items: [], checks: [], merge: unknown)))
        service.continuation.finish()
        await loading.value
        try await Task.sleep(for: .milliseconds(300))
        #expect(service.calls == 5)
    }

    @Test func successfulActionResetsTheUnknownMergeabilityBudget() async throws {
        let service = ScriptedStatusService()
        let unknown = status { $0.mergeable = .unknown; $0.mergeStateStatus = .unknown }
        service.responses = Array(repeating: PullRequestStatus(checks: [], merge: unknown), count: 20)
        let model = PRDetailModel(
            ref: PRRef(owner: "o", repo: "r", number: 1), service: service, highlighter: nil, rules: ReviewRules(),
            statusRefreshInterval: .seconds(60), mergeableRefreshInterval: .milliseconds(5)
        )
        let loading = Task { await model.load() }
        service.continuation.yield(.detail(pullRequest(head: "h3ad")))
        service.continuation.yield(.conversation(Conversation(items: [], checks: [], merge: unknown)))
        service.continuation.finish()
        await loading.value
        try await Task.sleep(for: .milliseconds(200))
        #expect(service.calls == 5)

        model.toggleDraft()
        await model.settleAction()
        #expect(service.performed == [.convertToDraft])
        try await Task.sleep(for: .milliseconds(200))
        #expect(service.calls == 11)
    }

    @Test func newHeadResetsTheUnknownMergeabilityBudget() async throws {
        let service = ScriptedStatusService()
        let unknown = status { $0.mergeable = .unknown; $0.mergeStateStatus = .unknown }
        let pushed = status { $0.mergeable = .unknown; $0.mergeStateStatus = .unknown; $0.headOid = "n3w" }
        service.responses = Array(repeating: PullRequestStatus(checks: [], merge: unknown), count: 4)
            + Array(repeating: PullRequestStatus(checks: [], merge: pushed), count: 20)
        let model = PRDetailModel(
            ref: PRRef(owner: "o", repo: "r", number: 1), service: service, highlighter: nil, rules: ReviewRules(),
            statusRefreshInterval: .seconds(60), mergeableRefreshInterval: .milliseconds(5)
        )
        let loading = Task { await model.load() }
        service.continuation.yield(.conversation(Conversation(items: [], checks: [], merge: unknown)))
        service.continuation.finish()
        await loading.value
        try await Task.sleep(for: .milliseconds(300))
        #expect(service.calls == 10)
    }

    @Test func queuedPullRequestPollsUntilMerged() async throws {
        let service = ScriptedStatusService()
        let queued = status { $0.queueEntry = queueEntry }
        service.responses = [
            PullRequestStatus(checks: [], merge: queued),
            PullRequestStatus(checks: [], merge: status { $0.state = .merged }),
            PullRequestStatus(checks: [], merge: queued),
        ]
        let model = PRDetailModel(
            ref: PRRef(owner: "o", repo: "r", number: 1), service: service, highlighter: nil, rules: ReviewRules(),
            statusRefreshInterval: .milliseconds(5)
        )
        let loading = Task { await model.load() }
        service.continuation.yield(.conversation(Conversation(items: [], checks: [], merge: queued)))
        service.continuation.finish()
        await loading.value
        #expect(model.isQueued)
        try await Task.sleep(for: .milliseconds(300))
        #expect(service.calls == 2)
        #expect(model.mergeStatus?.state == .merged)
        #expect(!model.isQueued)
    }
}

private final class ScriptedStatusService: PullRequestService, @unchecked Sendable {
    let stream: AsyncThrowingStream<PullRequestPart, Error>
    let continuation: AsyncThrowingStream<PullRequestPart, Error>.Continuation
    var responses: [PullRequestStatus] = []
    private(set) var calls = 0
    private(set) var performed: [PullRequestAction] = []

    init() {
        (stream, continuation) = AsyncThrowingStream.makeStream()
    }

    func parts(of ref: PRRef) -> AsyncThrowingStream<PullRequestPart, Error> { stream }
    func snapshot(of ref: PRRef) async throws -> PullRequestSnapshot { throw GitHubError.notFound }
    func setViewed(_ viewed: Bool, paths: [String], pullRequestID: String) async throws {}
    func fileContents(of ref: PRRef, oid: String, path: String) async throws -> String? { nil }
    func mergeBaseOid(of ref: PRRef, base: String, head: String) async throws -> String { base }
    func openPullRequests(in repo: RepoRef, scope: PullRequestListScope) async throws -> PullRequestList { throw GitHubError.notFound }
    @MainActor func perform(_ action: PullRequestAction, pullRequestID: String) async throws {
        performed.append(action)
    }

    @MainActor func status(of ref: PRRef) async throws -> PullRequestStatus {
        calls += 1
        return responses.isEmpty ? PullRequestStatus(checks: [], merge: nil) : responses.removeFirst()
    }
}

nonisolated private func pullRequest(head: String) -> PullRequest {
    PullRequest(
        nodeID: "PR_1", ref: PRRef(owner: "o", repo: "r", number: 1), title: "t", state: .open, isDraft: false, author: nil,
        bodyHTML: "", baseRefName: "main", headRefName: "feature", baseOid: "b4se", headOid: head,
        additions: 0, deletions: 0, changedFiles: 0, commitCount: 1, createdAt: Date(timeIntervalSince1970: 0)
    )
}

/// Forwards to a fixture service; the next `failures` status calls throw.
private final class FlakyStatusService: PullRequestService, @unchecked Sendable {
    let base: FixturePullRequestService
    var failures = 0
    private(set) var statusCalls = 0

    init(base: FixturePullRequestService) {
        self.base = base
    }

    func snapshot(of ref: PRRef) async throws -> PullRequestSnapshot { try await base.snapshot(of: ref) }
    func setViewed(_ viewed: Bool, paths: [String], pullRequestID: String) async throws {}
    func fileContents(of ref: PRRef, oid: String, path: String) async throws -> String? { nil }
    func mergeBaseOid(of ref: PRRef, base: String, head: String) async throws -> String { base }
    func openPullRequests(in repo: RepoRef, scope: PullRequestListScope) async throws -> PullRequestList { throw GitHubError.notFound }
    func perform(_ action: PullRequestAction, pullRequestID: String) async throws {
        try await base.perform(action, pullRequestID: pullRequestID)
    }

    @MainActor func status(of ref: PRRef) async throws -> PullRequestStatus {
        statusCalls += 1
        if failures > 0 {
            failures -= 1
            throw URLError(.timedOut)
        }
        return try await base.status(of: ref)
    }
}
