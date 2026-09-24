import Foundation
import Observation
import PRModels

@MainActor
@Observable
final class RecentPullRequests {
    struct Entry: Codable, Hashable, Identifiable {
        let ref: PRRef
        let title: String
        let openedAt: Date
        var id: PRRef { ref }
    }

    private(set) var entries: [Entry]
    private let defaults: UserDefaults
    private static let key = "recentPullRequests"
    private static let limit = 20

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        entries = defaults.data(forKey: Self.key).flatMap { try? JSONDecoder().decode([Entry].self, from: $0) } ?? []
    }

    func record(_ ref: PRRef, title: String) {
        entries.removeAll { $0.ref == ref }
        entries.insert(Entry(ref: ref, title: title, openedAt: .now), at: 0)
        entries = Array(entries.prefix(Self.limit))
        save()
    }

    func remove(_ ref: PRRef) {
        entries.removeAll { $0.ref == ref }
        save()
    }

    private func save() {
        defaults.set(try? JSONEncoder().encode(entries), forKey: Self.key)
    }
}
