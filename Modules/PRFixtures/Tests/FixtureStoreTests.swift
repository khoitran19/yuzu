import Foundation
import GitHubKit
import PRModels
import Testing
@testable import PRFixtures

struct FixtureStoreTests {
    let fixture = SyntheticPullRequest.make(fileCount: 30, changedLines: 400, seed: 3)

    @Test func roundTripsFixture() throws {
        let store = FixtureStore(directory: temporaryDirectory())
        defer { try? FileManager.default.removeItem(at: store.directory) }
        try store.write(fixture)
        #expect(try store.read() == fixture)
        let json = try String(contentsOf: store.snapshotURL, encoding: .utf8)
        #expect(json.contains("\"createdAt\" : \"2026-"))
        #expect(try store.contents(oid: "0000", path: "missing.ts") == nil)
    }

    @Test func rejectsPathsOutsideContents() {
        let store = FixtureStore(directory: temporaryDirectory())
        #expect(throws: FixtureError.self) { try store.writeContents("x", oid: "abc", path: "../escape.txt") }
        #expect(throws: FixtureError.self) { try store.writeContents("x", oid: "abc", path: "/etc/passwd") }
    }

    @Test func serviceAppliesViewedChanges() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FixtureStore(directory: directory).write(fixture)
        let service = FixturePullRequestService(directory: directory)
        let ref = try await service.pullRequestRef()
        let before = try await service.snapshot(of: ref)
        let unviewed = before.files.filter { $0.viewedState != .viewed }.prefix(2).map(\.path)
        let viewed = try #require(before.files.first { $0.viewedState == .viewed }?.path)

        try await service.setViewed(true, paths: unviewed, pullRequestID: before.pullRequest.nodeID)
        try await service.setViewed(false, paths: [viewed], pullRequestID: before.pullRequest.nodeID)
        let after = try await service.snapshot(of: ref)
        let states = Dictionary(uniqueKeysWithValues: after.files.map { ($0.path, $0.viewedState) })
        #expect(unviewed.allSatisfy { states[$0] == .viewed })
        #expect(states[viewed] == .unviewed)
        #expect(after.files.count { $0.viewedState == .viewed } == before.files.count { $0.viewedState == .viewed } + unviewed.count - 1)
        #expect(service.setViewedCalls == [
            .init(viewed: true, paths: unviewed, pullRequestID: before.pullRequest.nodeID),
            .init(viewed: false, paths: [viewed], pullRequestID: before.pullRequest.nodeID),
        ])
    }

    @Test func serviceRejectsUnknownPullRequestAndPath() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FixtureStore(directory: directory).write(fixture)
        let service = FixturePullRequestService(directory: directory)
        let ref = try await service.pullRequestRef()
        let before = try await service.snapshot(of: ref)
        let path = try #require(before.files.first { $0.viewedState != .viewed }?.path)

        await #expect(throws: GitHubError.self) { try await service.setViewed(true, paths: [path], pullRequestID: "PR_other") }
        await #expect(throws: GitHubError.self) {
            try await service.setViewed(true, paths: [path, "missing.ts"], pullRequestID: before.pullRequest.nodeID)
        }
        await #expect(throws: GitHubError.notFound) {
            try await service.snapshot(of: PRRef(owner: "other", repo: "repo", number: 1))
        }
        #expect(try await service.snapshot(of: ref) == before)
        #expect(service.setViewedCalls.count == 2)
    }

    @Test func recorderCopiesEveryTextFile() async throws {
        let source = temporaryDirectory()
        let target = temporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: source)
            try? FileManager.default.removeItem(at: target)
        }
        try FixtureStore(directory: source).write(fixture)
        let service = FixturePullRequestService(directory: source)
        let summary = try await FixtureRecorder.record(
            fixture.snapshot.pullRequest.ref, from: service, to: FixtureStore(directory: target), concurrency: 3
        )
        let baseOid = fixture.snapshot.pullRequest.baseOid
        let expected = Fixture(snapshot: fixture.snapshot, contents: fixture.contents, mergeBaseOid: baseOid)
        #expect(try FixtureStore(directory: target).read() == expected)
        #expect(summary.mergeBaseOid == baseOid)
        #expect(summary.contentCount == fixture.contents.count)
        #expect(summary.skipped.count == fixture.snapshot.files.count(where: FixtureRecorder.isBinary))
    }

    @Test func recorderStoresBaseContentsAtMergeBase() async throws {
        let source = temporaryDirectory()
        let target = temporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: source)
            try? FileManager.default.removeItem(at: target)
        }
        let mergeBase = String(repeating: "e", count: 40)
        let baseOid = fixture.snapshot.pullRequest.baseOid
        let moved = Fixture(
            snapshot: fixture.snapshot,
            contents: fixture.contents.map { FixtureContent(oid: $0.oid == baseOid ? mergeBase : $0.oid, path: $0.path, text: $0.text) },
            mergeBaseOid: mergeBase
        )
        try FixtureStore(directory: source).write(moved)
        let service = FixturePullRequestService(directory: source)
        let pullRequest = moved.snapshot.pullRequest
        #expect(try await service.mergeBaseOid(of: pullRequest.ref, base: pullRequest.baseOid, head: pullRequest.headOid) == mergeBase)

        let summary = try await FixtureRecorder.record(pullRequest.ref, from: service, to: FixtureStore(directory: target))
        #expect(try FixtureStore(directory: target).read() == moved)
        #expect(summary.contentCount == moved.contents.count)
    }

    @Test func serviceSimulatesPartialViewedFailure() async throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FixtureStore(directory: directory).write(fixture)
        let paths = fixture.snapshot.files.filter { $0.viewedState != .viewed }.prefix(3).map(\.path)
        try #require(paths.count == 3)
        let service = FixturePullRequestService(directory: directory, failingViewedPaths: [paths[1]])
        let ref = try await service.pullRequestRef()

        await #expect(throws: GitHubError.partialFailure(paths: [paths[1]])) {
            try await service.setViewed(true, paths: paths, pullRequestID: fixture.snapshot.pullRequest.nodeID)
        }
        let states = Dictionary(uniqueKeysWithValues: try await service.snapshot(of: ref).files.map { ($0.path, $0.viewedState) })
        #expect(states[paths[0]] == .viewed && states[paths[2]] == .viewed)
        #expect(states[paths[1]] != .viewed)
    }

    @Test func recorderSkipsLargeFiles() async throws {
        let source = temporaryDirectory()
        let target = temporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: source)
            try? FileManager.default.removeItem(at: target)
        }
        try FixtureStore(directory: source).write(fixture)
        let limit = 2_000
        let summary = try await FixtureRecorder.record(
            fixture.snapshot.pullRequest.ref, from: FixturePullRequestService(directory: source),
            to: FixtureStore(directory: target), maxFileBytes: limit
        )
        let expected = fixture.contents.filter { $0.text.utf8.count <= limit }
        #expect(!expected.isEmpty && expected.count < fixture.contents.count)
        #expect(try FixtureStore(directory: target).read().contents == expected)
        #expect(summary.contentCount == expected.count)
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appending(path: "prfixtures-\(UUID().uuidString)", directoryHint: .isDirectory)
    }
}
