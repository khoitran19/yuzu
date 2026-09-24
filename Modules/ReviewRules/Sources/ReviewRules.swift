import Foundation
import Observation

public struct ReviewRules: Codable, Sendable, Equatable {
    /// Tree folders that start collapsed.
    public var collapsedInTree: [String]
    /// Files the app marks as viewed on GitHub when a pull request opens.
    public var autoViewed: [String]

    public init(collapsedInTree: [String] = [], autoViewed: [String] = []) {
        self.collapsedInTree = collapsedInTree
        self.autoViewed = autoViewed
    }

    public var matcher: ReviewRuleMatcher { ReviewRuleMatcher(rules: self) }
}

public struct ReviewRuleMatcher: Sendable {
    private let collapsed: [GlobPattern]
    private let viewed: [GlobPattern]

    public init(rules: ReviewRules) {
        collapsed = rules.collapsedInTree.compactMap(GlobPattern.init)
        viewed = rules.autoViewed.compactMap(GlobPattern.init)
    }

    public func isCollapsedInTree(directory path: String) -> Bool {
        collapsed.contains { $0.matches(path: path, isDirectory: true) }
    }

    public func isAutoViewed(file path: String) -> Bool {
        viewed.contains { $0.matches(path: path) }
    }
}

@MainActor
@Observable
public final class ReviewRulesStore {
    public var rules: ReviewRules {
        didSet { save() }
    }

    private let defaults: UserDefaults
    private static let key = "reviewRules"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        rules = defaults.data(forKey: Self.key)
            .flatMap { try? JSONDecoder().decode(ReviewRules.self, from: $0) } ?? ReviewRules()
    }

    private func save() {
        defaults.set(try? JSONEncoder().encode(rules), forKey: Self.key)
    }
}
