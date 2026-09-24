import DiffEngine
import Foundation
import GitHubKit
import Observation
import PRFixtures
import PRList
import PRModels
import ReviewRules
import SignIn
import SyntaxHighlight

@MainActor
@Observable
final class AppServices {
    let options = LaunchOptions.current
    let auth = AuthSession()
    let rulesStore: ReviewRulesStore
    let recents = RecentPullRequests()
    @ObservationIgnored let highlighter: any SyntaxHighlighting = TreeSitterHighlighter()
    @ObservationIgnored private var prefetched: [PRRef: Prefetch] = [:]
    private static let prefetchLifetime: Duration = .seconds(60)
    @ObservationIgnored private var fixtureService: FixturePullRequestService?
    @ObservationIgnored private var listStore: PRListStore?
    @ObservationIgnored private var launchRefTaken = false
    @ObservationIgnored private var authBootstrapped = false
    let windows = PullRequestWindows()

    init() {
        if options.isHarness || options.rules != nil {
            let scratch = UserDefaults(suiteName: "dev.khoitran.yuzu.harness")!
            scratch.removePersistentDomain(forName: "dev.khoitran.yuzu.harness")
            rulesStore = ReviewRulesStore(storage: scratch)
            rulesStore.rules = options.rules ?? (options.settings ? .defaults : ReviewRules())
        } else {
            rulesStore = ReviewRulesStore()
        }
        if let fixture = options.fixture {
            fixtureService = FixturePullRequestService(
                directory: fixture, latency: options.latency, emptyPullRequestLists: options.emptyPullRequestLists,
                mergeStatus: options.mergeStatus
            )
        }
    }

    /// Every window asks, but the session loads once: a second load would sign out all windows while it runs.
    func bootstrapAuth() async {
        guard !authBootstrapped else { return }
        authBootstrapped = true
        await auth.bootstrap()
    }

    var isSignedIn: Bool {
        if case .signedIn = auth.state { return true }
        return false
    }

    var service: (any PullRequestService)? {
        if let fixtureService { return fixtureService }
        if case let .signedIn(token, _) = auth.state { return GitHubClient(token: token) }
        return nil
    }

    /// The pull request of `--open` or the fixture, for the first window only.
    func takeLaunchRef() async -> PRRef? {
        guard !launchRefTaken else { return nil }
        launchRefTaken = true
        if let ref = options.open { return ref }
        return try? await fixtureService?.pullRequestRef()
    }

    func pullRequestLists(for service: any PullRequestService) -> PRListStore {
        if let listStore { return listStore }
        let store = PRListStore(service: service)
        listStore = store
        return store
    }

    /// Starts loading a pull request before the user opens it. The result stays in memory for 60 seconds.
    func prefetch(_ ref: PRRef) {
        guard fixtureService == nil, let service else { return }
        if let existing = prefetched[ref], ContinuousClock.now - existing.started < Self.prefetchLifetime { return }
        prefetched[ref] = Prefetch(started: .now, snapshot: Task { try await service.snapshot(of: ref) })
    }

    /// The service to open `ref` with; it uses a recent prefetch when one exists.
    func service(for ref: PRRef) -> (any PullRequestService)? {
        guard let service else { return nil }
        guard let prefetch = prefetched.removeValue(forKey: ref), ContinuousClock.now - prefetch.started < Self.prefetchLifetime else {
            return service
        }
        return PrefetchedService(base: service, ref: ref, snapshot: prefetch.snapshot)
    }

    func signOut() {
        listStore = nil
        auth.signOut()
    }
}
