import PRModels

public struct Fixture: Sendable, Equatable {
    public var snapshot: PullRequestSnapshot
    /// Sorted by `oid`, then `path`.
    public var contents: [FixtureContent]
    /// Base contents are stored under this oid. `nil` means `snapshot.pullRequest.baseOid`.
    public var mergeBaseOid: String?

    public init(snapshot: PullRequestSnapshot, contents: [FixtureContent], mergeBaseOid: String? = nil) {
        self.snapshot = snapshot
        self.contents = contents.sorted()
        self.mergeBaseOid = mergeBaseOid
    }
}

public struct FixtureContent: Sendable, Hashable, Comparable {
    public let oid: String
    public let path: String
    public let text: String

    public init(oid: String, path: String, text: String) {
        self.oid = oid
        self.path = path
        self.text = text
    }

    public static func < (lhs: Self, rhs: Self) -> Bool {
        (lhs.oid, lhs.path) < (rhs.oid, rhs.path)
    }
}
