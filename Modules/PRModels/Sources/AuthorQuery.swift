import Foundation

/// `@login` in the address field: the open pull requests of one author. `@me` is the viewer.
public struct AuthorQuery: Hashable, Sendable {
    /// The value of the GitHub search `author:` qualifier.
    public let login: String

    public init?(string: String) {
        let text = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard text.hasPrefix("@") else { return nil }
        let name = text.dropFirst()
        if name == "me" {
            login = "@me"
            return
        }
        let allowed = name.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-") }
        guard allowed, (1...39).contains(name.count), name.first != "-" else { return nil }
        login = String(name)
    }
}
