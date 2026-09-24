import Foundation
import Observation

public struct ReviewRules: Codable, Sendable, Equatable {
    /// Files the app marks as viewed on GitHub when a pull request opens.
    public var autoViewed: [String]

    public init(autoViewed: [String] = []) {
        self.autoViewed = autoViewed
    }

    public var matcher: ReviewRuleMatcher { ReviewRuleMatcher(rules: self) }

    public static let defaults = ReviewRules(autoViewed: [
        "# Tests",
        "*.spec.*",
        "*.test.*",
        "*.e2e.*",
        "__tests__/",
        "__integration__/",
        "__snapshots__/",
        "*.snap",
        "# Test doubles and fixtures",
        "__mocks__/",
        "testing/",
        "fixtures/",
        "fake*",
        "mock*",
        "setup-tests.*",
        "vitest*.config.*",
        "# Generated files and lockfiles",
        "*.gen.*",
        "__generated__/",
        "__generated/",
        "worker-configuration.d.ts",
        "pnpm-lock.yaml",
        "*.lock",
    ])
}

public struct ReviewRuleMatcher: Sendable {
    private let viewed: [GlobPattern]

    public init(rules: ReviewRules) {
        viewed = rules.autoViewed.compactMap(GlobPattern.init)
    }

    public func isAutoViewed(file path: String) -> Bool {
        autoViewedPattern(file: path) != nil
    }

    /// The first pattern that matches the file.
    public func autoViewedPattern(file path: String) -> String? {
        viewed.first { $0.matches(path: path) }?.source
    }
}

@MainActor
@Observable
public final class ReviewRulesStore {
    public var rules: ReviewRules {
        didSet { save() }
    }

    private let storage: UserDefaults
    private static let key = "reviewRules"

    public init(storage: UserDefaults = .standard) {
        self.storage = storage
        rules =
            storage.data(forKey: Self.key)
            .flatMap { try? JSONDecoder().decode(ReviewRules.self, from: $0) } ?? .defaults
    }

    private func save() {
        storage.set(try? JSONEncoder().encode(rules), forKey: Self.key)
    }
}
