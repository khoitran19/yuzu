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
    @ObservationIgnored private var fixtureService: FixturePullRequestService?

    init() {
        if let rules = options.rules {
            let scratch = UserDefaults(suiteName: "dev.khoitran.prviewer.harness")!
            scratch.removePersistentDomain(forName: "dev.khoitran.prviewer.harness")
            rulesStore = ReviewRulesStore(defaults: scratch)
            rulesStore.rules = rules
        } else {
            rulesStore = ReviewRulesStore()
        }
        if let fixture = options.fixture { fixtureService = FixturePullRequestService(directory: fixture) }
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

    func signOut() {
        auth.signOut()
    }
}
