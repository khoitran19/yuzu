import Foundation
@testable import DiffView
import GitHubKit
@testable import PRDetail
import PRFixtures
import PRModels
import ReviewRules
import Testing

@MainActor
struct PRDetailModelTests {
    @Test func failedToggleRevertsToConfirmedState() async throws {
        let (model, path) = try await loadedModel(failing: true)
        #expect(!model.viewedPaths.contains(path))

        model.setViewed(true, paths: [path])
        model.setViewed(false, paths: [path])
        await model.settleViewedSync()

        #expect(!model.viewedPaths.contains(path))
        #expect(model.errorBanner != nil)
    }

    @Test func successfulToggleStaysViewed() async throws {
        let (model, path) = try await loadedModel(failing: false)
        model.setViewed(true, paths: [path])
        await model.settleViewedSync()
        #expect(model.viewedPaths.contains(path))
        #expect(model.errorBanner == nil)
    }

    @Test func autoViewedRulesMarkMatchingFiles() async throws {
        let directory = try fixtureDirectory()
        let service = FixturePullRequestService(directory: directory)
        let ref = try await service.pullRequestRef()
        let model = PRDetailModel(ref: ref, service: service, highlighter: nil, rules: ReviewRules(autoViewed: ["*.spec.ts"]))
        await model.load()
        await model.settleViewedSync()
        let snapshot = try await service.snapshot(of: ref)
        let specs = snapshot.files.filter { $0.path.hasSuffix(".spec.ts") }
        #expect(!specs.isEmpty)
        #expect(specs.allSatisfy { $0.viewedState == .viewed })
        #expect(specs.allSatisfy { model.viewedPaths.contains($0.path) })
    }

    private func loadedModel(failing: Bool) async throws -> (PRDetailModel, String) {
        let directory = try fixtureDirectory()
        let initial = FixturePullRequestService(directory: directory)
        let ref = try await initial.pullRequestRef()
        let path = try #require(try await initial.snapshot(of: ref).files.first { $0.viewedState != .viewed }?.path)
        let service = FixturePullRequestService(directory: directory, failingViewedPaths: failing ? [path] : [])
        let model = PRDetailModel(ref: ref, service: service, highlighter: nil, rules: ReviewRules())
        await model.load()
        return (model, path)
    }

    /// A private copy of the 50-file fixture, so viewed changes never touch the committed files.
    private func fixtureDirectory() throws -> URL {
        let source = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Fixtures/synthetic-50")
        let copy = FileManager.default.temporaryDirectory.appending(path: "prdetail-\(UUID().uuidString)")
        try FileManager.default.copyItem(at: source, to: copy)
        return copy
    }
}

@MainActor
struct ProgressiveLoadTests {
    @Test func diffShowsBeforeDetailAndThreadsArrive() async throws {
        let directory = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Fixtures/synthetic-50")
        let fixture = FixturePullRequestService(directory: directory)
        let snapshot = try await fixture.snapshot(of: try await fixture.pullRequestRef())
        let service = ManualPartsService()
        let model = PRDetailModel(ref: snapshot.pullRequest.ref, service: service, highlighter: nil, rules: ReviewRules())
        let loading = Task { await model.load() }

        service.continuation.yield(.files(pullRequestID: snapshot.pullRequest.nodeID, files: snapshot.files))
        try await waitUntil { model.phase == .loaded }
        #expect(model.pullRequest == nil)
        #expect(model.isRefreshing)
        #expect(threadRows(model) == 0)

        service.continuation.yield(.threads(snapshot.threads))
        service.continuation.yield(.detail(snapshot.pullRequest))
        service.continuation.finish()
        await loading.value

        #expect(model.pullRequest == snapshot.pullRequest)
        #expect(!model.isRefreshing)
        #expect(threadRows(model) > 0)
    }

    @Test func conversationReplacesOnlyTheConversationPart() async throws {
        let directory = URL(filePath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Fixtures/synthetic-50")
        let fixture = FixturePullRequestService(directory: directory)
        let snapshot = try await fixture.snapshot(of: try await fixture.pullRequestRef())
        let conversation = try #require(snapshot.conversation)
        let service = ManualPartsService()
        let model = PRDetailModel(ref: snapshot.pullRequest.ref, service: service, highlighter: nil, rules: ReviewRules())
        let loading = Task { await model.load() }

        service.continuation.yield(.detail(snapshot.pullRequest))
        try await waitUntil { model.summaryPage != nil }
        let first = try #require(model.summaryPage)
        #expect(first.conversation.contains("Loading conversation"))

        service.continuation.yield(.conversation(conversation))
        service.continuation.finish()
        await loading.value
        try await waitUntil { model.summaryPage?.conversation != first.conversation }
        #expect(model.summaryPage?.document == first.document)
        #expect(model.summaryPage?.conversation.contains("All checks") == false)
        #expect(model.summaryPage?.conversation.contains("Some checks were not successful") == true)
    }

    private func threadRows(_ model: PRDetailModel) -> Int {
        model.filesController.diff.rows.filter { if case .thread = $0.kind { $0.slice == 0 } else { false } }.count
    }

    private func waitUntil(_ condition: () -> Bool) async throws {
        for _ in 0..<200 where !condition() { try await Task.sleep(for: .milliseconds(10)) }
        #expect(condition())
    }
}

private final class ManualPartsService: PullRequestService, @unchecked Sendable {
    let stream: AsyncThrowingStream<PullRequestPart, Error>
    let continuation: AsyncThrowingStream<PullRequestPart, Error>.Continuation

    init() {
        (stream, continuation) = AsyncThrowingStream.makeStream()
    }

    func parts(of ref: PRRef) -> AsyncThrowingStream<PullRequestPart, Error> { stream }
    func snapshot(of ref: PRRef) async throws -> PullRequestSnapshot { throw GitHubError.notFound }
    func setViewed(_ viewed: Bool, paths: [String], pullRequestID: String) async throws {}
    func fileContents(of ref: PRRef, oid: String, path: String) async throws -> String? { nil }
    func mergeBaseOid(of ref: PRRef, base: String, head: String) async throws -> String { base }
}
