import AppKit
import AppShortcuts
import Testing

struct ShortcutTests {
    @Test func menuShortcutsAreUniqueAcrossTheApp() {
        let menu = Shortcut.all.filter { !$0.modifiers.isDisjoint(with: [.command, .control]) }
        let combos = menu.flatMap { shortcut in shortcut.keyCaps.map { $0.joined() } }
        #expect(Set(combos).count == combos.count, "Duplicate: \(combos.sorted())")
    }

    @Test func shortcutsInOneAreaAreUnique() {
        for area in Shortcut.Area.allCases {
            let combos = Shortcut.all.filter { $0.area == area }.flatMap { $0.keyCaps.map { $0.joined() } }
            #expect(Set(combos).count == combos.count, "Duplicate in \(area.rawValue): \(combos.sorted())")
        }
    }

    @Test func everyShortcutIsListedOnce() {
        #expect(Set(Shortcut.all.map(\.id)).count == Shortcut.all.count)
    }

    @Test func matchesAlternativesAndRejectsOtherModifiers() {
        #expect(Shortcut.nextFile.matches(key("j")))
        #expect(Shortcut.nextFile.matches(key("n")))
        #expect(!Shortcut.nextFile.matches(key("j", [.command])))
        #expect(!Shortcut.nextFile.matches(key("J", [.shift])))
        #expect(Shortcut.otherPullRequests.matches(key("D", [.command, .shift])))
        #expect(!Shortcut.myPullRequests.matches(key("D", [.command, .shift])))
    }

    @Test func matchesReturnAndEnter() {
        #expect(Shortcut.openTreeItem.matches(key("\r", keyCode: 36)))
        #expect(Shortcut.openTreeItem.matches(key("\u{03}", keyCode: 76)))
        #expect(!Shortcut.openTreeItem.matches(key("r")))
    }

    @Test func keyCapsListModifiersInMacOSOrder() {
        #expect(Shortcut.collapseAll.keyCaps == [["⌥", "⌘", "["]])
        #expect(Shortcut.otherPullRequests.symbols == "⇧⌘D")
        #expect(Shortcut.toggleCollapse.keyCaps == [["X"], ["O"]])
    }

    private func key(_ characters: String, _ flags: NSEvent.ModifierFlags = [], keyCode: UInt16 = 0) -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0, windowNumber: 0, context: nil,
            characters: characters, charactersIgnoringModifiers: characters, isARepeat: false, keyCode: keyCode
        )!
    }
}
