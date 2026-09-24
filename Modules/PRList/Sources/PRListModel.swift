import Foundation
import GitHubKit
import Observation
import PRModels

/// A request for the tab the panel already shows closes the panel; a request for the other tab switches to it.
public struct PRListPanelState: Equatable, Sendable {
    public var isOpen = false
    public var tab: PullRequestListScope = .mine

    public init() {}

    public mutating func request(_ scope: PullRequestListScope) {
        if isOpen, tab == scope {
            isOpen = false
        } else {
            isOpen = true
            tab = scope
        }
    }

    public mutating func toggle() {
        isOpen.toggle()
    }
}

/// The open pull requests of the active repository. Lists are kept per repository, so a switch shows the cached list at once.
@Observable
public final class PRListModel {
    public struct TabContent: Equatable {
        public var list: PullRequestList?
        public var error: String?
        public var isLoading = false
    }

    public private(set) var panel = PRListPanelState()
    public private(set) var repo: RepoRef?
    /// The pull request open in the window.
    public var current: PRRef? {
        didSet { if current != oldValue { resetSelection() } }
    }
    public private(set) var selection: PRRef?
    /// Increments on each request that leaves the panel open, so the panel takes keyboard focus again.
    public private(set) var focusRequests = 0

    private var contents: [Key: TabContent] = [:]
    @ObservationIgnored private var loads: [Key: Task<Void, Never>] = [:]
    @ObservationIgnored private let service: any PullRequestService

    public init(service: any PullRequestService) {
        self.service = service
    }

    /// The open pull request's repository, else the repository of the most recent pull request.
    public static func activeRepository(openPullRequest: PRRef?, recent: [PRRef]) -> RepoRef? {
        (openPullRequest ?? recent.first).map(RepoRef.init)
    }

    public var tab: PullRequestListScope {
        get { panel.tab }
        set {
            panel.tab = newValue
            resetSelection()
        }
    }

    public var rows: [PullRequestSummary] { content(panel.tab).list?.pullRequests ?? [] }

    public func content(_ scope: PullRequestListScope) -> TabContent {
        repo.flatMap { contents[Key(repo: $0, scope: scope)] } ?? TabContent()
    }

    public func request(_ scope: PullRequestListScope) {
        guard repo != nil else { return }
        let wasOpen = panel.isOpen
        panel.request(scope)
        didChangePanel(wasOpen: wasOpen)
    }

    public func toggle() {
        guard repo != nil else { return }
        let wasOpen = panel.isOpen
        panel.toggle()
        didChangePanel(wasOpen: wasOpen)
    }

    public func close() {
        panel.isOpen = false
    }

    public func setRepository(_ repo: RepoRef?) {
        guard repo != self.repo else { return }
        self.repo = repo
        if repo == nil { panel.isOpen = false }
        resetSelection()
        if panel.isOpen { refresh() }
    }

    /// Loads both tabs in parallel. A tab that is loading already is not requested again.
    public func refresh() {
        guard let repo else { return }
        for scope in PullRequestListScope.allCases {
            let key = Key(repo: repo, scope: scope)
            guard loads[key] == nil else { continue }
            contents[key, default: TabContent()].isLoading = true
            loads[key] = Task { [weak self, service] in
                let result: Result<PullRequestList, Error>
                do {
                    result = .success(try await service.openPullRequests(in: repo, scope: scope))
                } catch {
                    result = .failure(error)
                }
                self?.finish(key, result)
            }
        }
    }

    public func moveSelection(by delta: Int) {
        let rows = rows
        guard !rows.isEmpty else { return }
        let index = selection.flatMap { selected in rows.firstIndex { $0.ref == selected } } ?? (delta > 0 ? -1 : rows.count)
        selection = rows[min(max(index + delta, 0), rows.count - 1)].ref
    }

    func load(of repo: RepoRef, scope: PullRequestListScope) -> Task<Void, Never>? {
        loads[Key(repo: repo, scope: scope)]
    }

    private func didChangePanel(wasOpen: Bool) {
        guard panel.isOpen else { return }
        focusRequests += 1
        resetSelection()
        if !wasOpen { refresh() }
    }

    private func finish(_ key: Key, _ result: Result<PullRequestList, Error>) {
        loads[key] = nil
        var content = contents[key] ?? TabContent()
        content.isLoading = false
        switch result {
        case let .success(list):
            content.list = PullRequestList(
                pullRequests: list.pullRequests.sorted { $0.updatedAt > $1.updatedAt }, totalCount: list.totalCount)
            content.error = nil
        case let .failure(error):
            content.error = error.localizedDescription
        }
        contents[key] = content
        if key.repo == repo, key.scope == panel.tab, !rows.contains(where: { $0.ref == selection }) { resetSelection() }
    }

    private func resetSelection() {
        let rows = rows
        selection = rows.first { $0.ref == current }?.ref ?? rows.first?.ref
    }

    private struct Key: Hashable {
        let repo: RepoRef
        let scope: PullRequestListScope
    }
}
