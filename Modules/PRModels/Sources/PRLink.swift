import Foundation

/// A clicked link that points to a GitHub pull request.
public struct PRLink: Equatable, Sendable {
    public let ref: PRRef
    /// The link points to the "Files changed" page.
    public let showsFiles: Bool

    public init?(url: URL) {
        guard url.scheme == "https" || url.scheme == "http", let ref = PRRef(string: url.absoluteString) else { return nil }
        self.ref = ref
        let parts = url.path().split(separator: "/")
        showsFiles = parts.count > 4 && (parts[4] == "files" || parts[4] == "changes")
    }
}
