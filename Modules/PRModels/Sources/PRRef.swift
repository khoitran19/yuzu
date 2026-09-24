import Foundation

public struct PRRef: Hashable, Sendable, Codable {
    public let owner: String
    public let repo: String
    public let number: Int

    public init(owner: String, repo: String, number: Int) {
        self.owner = owner
        self.repo = repo
        self.number = number
    }

    /// Accepts `https://github.com/o/r/pull/1[/changes|/files|…]`, the same without a scheme, and `o/r#1`.
    public init?(string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if let shorthand = Self.parseShorthand(trimmed) {
            self = shorthand
            return
        }
        let withScheme = trimmed.contains("://") ? trimmed : "https://\(trimmed)"
        guard
            let url = URL(string: withScheme),
            let host = url.host(), host == "github.com" || host == "www.github.com"
        else { return nil }
        let parts = url.path().split(separator: "/").map(String.init)
        guard
            parts.count >= 4,
            parts[2] == "pull",
            let number = Int(parts[3]), number > 0
        else { return nil }
        self.init(owner: parts[0], repo: parts[1], number: number)
    }

    /// Also accepts `123` and `#123` for a pull request in `repository`.
    public init?(string: String, in repository: RepoRef?) {
        if let ref = PRRef(string: string) {
            self = ref
            return
        }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let repository, let number = Int(trimmed.hasPrefix("#") ? String(trimmed.dropFirst()) : trimmed), number > 0 else {
            return nil
        }
        self.init(owner: repository.owner, repo: repository.name, number: number)
    }

    public var displayName: String { "\(owner)/\(repo)#\(number)" }

    public var webURL: URL {
        URL(string: "https://github.com/\(owner)/\(repo)/pull/\(number)")!
    }

    private static func parseShorthand(_ text: String) -> PRRef? {
        let halves = text.split(separator: "#")
        guard halves.count == 2, let number = Int(halves[1]), number > 0 else { return nil }
        let names = halves[0].split(separator: "/")
        guard names.count == 2 else { return nil }
        return PRRef(owner: String(names[0]), repo: String(names[1]), number: number)
    }
}
