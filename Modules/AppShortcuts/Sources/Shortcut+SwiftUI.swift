import SwiftUI

extension Shortcut {
    /// The first alternative, for `.keyboardShortcut` and `.onKeyPress`.
    public var keyEquivalent: KeyEquivalent {
        switch keys[0] {
        case let .character(character): KeyEquivalent(character)
        case .upArrow: .upArrow
        case .downArrow: .downArrow
        case .returnKey: .return
        case .escape: .escape
        }
    }

    public var eventModifiers: EventModifiers {
        var result: EventModifiers = []
        if modifiers.contains(.control) { result.insert(.control) }
        if modifiers.contains(.option) { result.insert(.option) }
        if modifiers.contains(.shift) { result.insert(.shift) }
        if modifiers.contains(.command) { result.insert(.command) }
        return result
    }

    /// Menus match the character the keyboard sends, so ⇧⌘[ must be `{` with ⌘.
    public var keyboardShortcut: KeyboardShortcut {
        if modifiers.contains(.shift), case let .character(character) = keys[0], let shifted = Self.shifted[character] {
            return KeyboardShortcut(KeyEquivalent(shifted), modifiers: eventModifiers.subtracting(.shift))
        }
        return KeyboardShortcut(keyEquivalent, modifiers: eventModifiers)
    }
}
