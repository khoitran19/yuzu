import DiffEngine
import Foundation
import GitHubKit
import Observation
import PRFixtures
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

    var isSignedIn: Bool {
        if case .signedIn = auth.state { return true }
        return false
    }

    var service: (any PullRequestService)? {
        if let fixtureService { return fixtureService }
        if case let .signedIn(token, _) = auth.state { return GitHubClient(token: token) }
        return nil
    }

    /// The pull request a fixture holds; `nil` outside fixture mode.
    func fixtureRef() async -> PRRef? {
        try? await fixtureService?.pullRequestRef()
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
        auth.signOut()
    }
}
