import AppKit

/// One keyboard shortcut. Menus, key handlers, and the Shortcuts settings read the same value.
public struct Shortcut: Sendable, Hashable, Identifiable {
    public enum Key: Sendable, Hashable {
        case character(Character)
        case upArrow
        case downArrow
        case returnKey
        case escape
    }

    public struct Modifiers: OptionSet, Sendable, Hashable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let control = Modifiers(rawValue: 1 << 0)
        public static let option = Modifiers(rawValue: 1 << 1)
        public static let shift = Modifiers(rawValue: 1 << 2)
        public static let command = Modifiers(rawValue: 1 << 3)
    }

    /// The part of the app where the shortcut works, in the order the settings list shows them.
    public enum Area: String, Sendable, CaseIterable, Identifiable {
        case general = "General"
        case pullRequest = "Pull request"
        case sheet = "Review and merge sheets"
        case diff = "Diff"
        case fileTree = "File tree"
        case fileFilter = "File filter"
        case panel = "Pull request panel"

        public var id: Self { self }
    }

    public let id: String
    public let title: String
    public let area: Area
    /// Alternative keys with the same action. Menus use the first.
    public let keys: [Key]
    public let modifiers: Modifiers

    public init(_ id: String, _ title: String, area: Area, keys: [Key], modifiers: Modifiers = []) {
        precondition(!keys.isEmpty, "A shortcut needs a key.")
        self.id = id
        self.title = title
        self.area = area
        self.keys = keys
        self.modifiers = modifiers
    }

    /// Key cap labels for each alternative, modifiers first in the macOS order ⌃⌥⇧⌘.
    public var keyCaps: [[String]] {
        keys.map { modifierSymbols + [Self.symbol(for: $0)] }
    }

    /// The first alternative as one string, for example `⇧⌘P`.
    public var symbols: String { keyCaps[0].joined() }

    public func matches(_ event: NSEvent) -> Bool {
        guard Modifiers(event.modifierFlags) == modifiers else { return false }
        return keys.contains { key in
            switch key {
            case let .character(character):
                [String(character).lowercased(), Self.shifted[character].map(String.init)]
                    .contains(event.charactersIgnoringModifiers?.lowercased())
            case .upArrow: event.specialKey == .upArrow
            case .downArrow: event.specialKey == .downArrow
            case .returnKey: event.specialKey == .carriageReturn || event.specialKey == .enter
            case .escape: event.keyCode == 53
            }
        }
    }

    /// The US-layout character that ⇧ gives for a key, where it is not the uppercase letter.
    static let shifted: [Character: Character] = ["[": "{", "]": "}"]

    private var modifierSymbols: [String] {
        [(Modifiers.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘")].compactMap { modifiers.contains($0) ? $1 : nil }
    }

    private static func symbol(for key: Key) -> String {
        switch key {
        case let .character(character): String(character).uppercased()
        case .upArrow: "↑"
        case .downArrow: "↓"
        case .returnKey: "↩"
        case .escape: "esc"
        }
    }
}

extension Shortcut.Modifiers {
    init(_ flags: NSEvent.ModifierFlags) {
        self = []
        if flags.contains(.control) { insert(.control) }
        if flags.contains(.option) { insert(.option) }
        if flags.contains(.shift) { insert(.shift) }
        if flags.contains(.command) { insert(.command) }
    }
}
