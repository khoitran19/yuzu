import Foundation
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
