import Foundation
import GitHubKit
import PRModels
import Synchronization
import Testing

@testable import PRList

struct PRListModelTests {
    private let district = RepoRef(owner: "isoapp", name: "district")
    private let graph = RepoRef(owner: "isoapp", name: "graph")

    @Test func shortcutClosesTheShownTabAndSwitchesToTheOther() {
        var state = PRListPanelState()
        state.request(.mine)
        #expect(state == open(.mine))
        state.request(.others)
        #expect(state == open(.others))
        state.request(.others)
        #expect(!state.isOpen)
        state.request(.others)
        #expect(state == open(.others))
        state.toggle()
        state.toggle()
        #expect(state == open(.others))
    }

    @Test func activeRepositoryPrefersTheOpenPullRequest() {
        let open = PRRef(owner: "isoapp", repo: "graph", number: 3080)
        let recent = [PRRef(owner: "isoapp", repo: "district", number: 1), PRRef(owner: "octo", repo: "app", number: 2)]
        #expect(PRListModel.activeRepository(openPullRequest: open, recent: recent) == graph)
        #expect(PRListModel.activeRepository(openPullRequest: nil, recent: recent) == district)
        #expect(PRListModel.activeRepository(openPullRequest: nil, recent: []) == nil)
    }

    @Test func noRepositoryKeepsThePanelClosed() {
        let model = PRListModel(service: GatedListService())
        model.request(.mine)
        model.toggle()
        #expect(!model.panel.isOpen)
    }

    @Test func everyRequestThatShowsThePanelAsksForFocus() {
        let model = PRListModel(service: GatedListService())
        model.setRepository(district)
        model.request(.mine)
        model.request(.others)
        #expect(model.focusRequests == 2)
        model.request(.others)
        #expect(!model.panel.isOpen)
        #expect(model.focusRequests == 2)
    }

    @Test func rowsAreSortedByLastUpdateAndSelectTheCurrentPullRequest() async {
        let service = GatedListService()
        service.release(district)
        let model = PRListModel(service: service)
        model.setRepository(district)
        model.current = PRRef(owner: "isoapp", repo: "district", number: 2)
        model.request(.mine)
        await model.load(of: district, scope: .mine)?.value
        #expect(model.rows.map(\.ref.number) == [2, 3, 1])
        #expect(model.selection?.number == 2)
        model.moveSelection(by: 1)
        model.moveSelection(by: 1)
        model.moveSelection(by: 1)
        #expect(model.selection?.number == 1)
    }

    @Test func aRepositorySwitchNeverShowsTheOtherRepositoryRows() async {
        let service = GatedListService()
        let model = PRListModel(service: service)
        model.setRepository(district)
        model.request(.mine)
        let districtLoad = model.load(of: district, scope: .mine)
        #expect(model.content(.mine).isLoading)

        model.setRepository(graph)
        #expect(model.content(.mine).list == nil)
        #expect(model.content(.mine).isLoading)

        service.release(graph)
        await model.load(of: graph, scope: .mine)?.value
        service.release(district)
        await districtLoad?.value
        #expect(model.rows.map(\.ref.repo) == ["graph", "graph", "graph"])

        model.setRepository(district)
        #expect(model.rows.map(\.ref.repo) == ["district", "district", "district"])
    }

    @Test func aFailedLoadKeepsTheLastList() async {
        let service = GatedListService()
        service.release(district)
        let model = PRListModel(service: service)
        model.setRepository(district)
        model.request(.others)
        await model.load(of: district, scope: .others)?.value
        service.fail(district)
        model.close()
        model.request(.others)
        await model.load(of: district, scope: .others)?.value
        #expect(model.content(.others).list?.pullRequests.count == 3)
        #expect(model.content(.others).error != nil)
    }

    private func open(_ tab: PullRequestListScope) -> PRListPanelState {
        var state = PRListPanelState()
        state.isOpen = true
        state.tab = tab
        return state
    }
}

/// Each repository's requests wait until the test releases that repository.
private nonisolated final class GatedListService: PullRequestService, Sendable {
    private struct State {
        var released: Set<RepoRef> = []
        var failing: Set<RepoRef> = []
        var waiting: [RepoRef: [CheckedContinuation<Void, Never>]] = [:]
    }

    private let state = Mutex(State())

    func release(_ repo: RepoRef) {
        let waiting = state.withLock { state in
            state.released.insert(repo)
            return state.waiting.removeValue(forKey: repo) ?? []
        }
        for continuation in waiting { continuation.resume() }
    }

    func fail(_ repo: RepoRef) {
        state.withLock { _ = $0.failing.insert(repo) }
    }

    func openPullRequests(in repo: RepoRef, scope: PullRequestListScope) async throws -> PullRequestList {
        await withCheckedContinuation { continuation in
            let released = state.withLock { state in
                if state.released.contains(repo) { return true }
                state.waiting[repo, default: []].append(continuation)
                return false
            }
            if released { continuation.resume() }
        }
        if state.withLock({ $0.failing.contains(repo) }) { throw GitHubError.http(status: 502, message: "Bad gateway") }
        let hoursAgo = [3, 1, 2]
        let pullRequests = hoursAgo.enumerated().map { index, hours in
            PullRequestSummary(
                ref: PRRef(owner: repo.owner, repo: repo.name, number: index + 1), title: "\(scope) \(index + 1)",
                isDraft: false, author: nil, updatedAt: Date(timeIntervalSince1970: 1_000_000 - Double(hours) * 3_600),
                commentCount: 0, checks: nil, reviewDecision: nil
            )
        }
        return PullRequestList(pullRequests: pullRequests, totalCount: pullRequests.count)
    }

    func snapshot(of ref: PRRef) async throws -> PullRequestSnapshot { throw GitHubError.notFound }
    func setViewed(_ viewed: Bool, paths: [String], pullRequestID: String) async throws { throw GitHubError.notFound }
    func fileContents(of ref: PRRef, oid: String, path: String) async throws -> String? { nil }
    func mergeBaseOid(of ref: PRRef, base: String, head: String) async throws -> String { base }
    func status(of ref: PRRef) async throws -> PullRequestStatus { PullRequestStatus(checks: [], merge: nil) }
    func perform(_ action: PullRequestAction, pullRequestID: String) async throws { throw GitHubError.notFound }
}
