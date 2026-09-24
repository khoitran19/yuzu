import Foundation

/// `.gitignore`-style pattern. Without a `/` it matches any path component; with one it matches from the root.
/// A match on a directory also matches everything inside it. A trailing `/` matches directories only.
public struct GlobPattern: Sendable, Hashable {
    public let source: String
    private let regex: NSRegularExpression
    private let anchored: Bool
    private let directoryOnly: Bool

    public init?(_ source: String) {
        var body = source.trimmingCharacters(in: .whitespaces)
        guard !body.isEmpty, !body.hasPrefix("#") else { return nil }
        directoryOnly = body.hasSuffix("/")
        if directoryOnly { body.removeLast() }
        anchored = body.contains("/")
        if body.hasPrefix("/") { body.removeFirst() }
        guard !body.isEmpty, let regex = try? NSRegularExpression(pattern: "^\(Self.translate(body))$") else {
            return nil
        }
        self.source = source
        self.regex = regex
    }

    public func matches(path: String, isDirectory: Bool = false) -> Bool {
        let components = path.split(separator: "/").map(String.init)
        let lastDirectoryIndex = isDirectory ? components.count - 1 : components.count - 2
        for index in components.indices {
            if directoryOnly, index > lastDirectoryIndex { break }
            let candidate = anchored ? components[...index].joined(separator: "/") : components[index]
            if test(candidate) { return true }
        }
        return false
    }

    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.source == rhs.source }
    public func hash(into hasher: inout Hasher) { hasher.combine(source) }

    private func test(_ candidate: String) -> Bool {
        regex.firstMatch(in: candidate, range: NSRange(candidate.startIndex..., in: candidate)) != nil
    }

    private static func translate(_ glob: String) -> String {
        var output = ""
        var characters = Array(glob)[...]
        while let character = characters.popFirst() {
            switch character {
            case "*" where characters.first == "*":
                characters.removeFirst()
                if characters.first == "/" {
                    characters.removeFirst()
                    output += "(?:.*/)?"
                } else {
                    output += ".*"
                }
            case "*": output += "[^/]*"
            case "?": output += "[^/]"
            default: output += NSRegularExpression.escapedPattern(for: String(character))
            }
        }
        return output
    }
}
