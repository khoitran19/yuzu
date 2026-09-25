import AppKit
import DiffEngine

/// GitHub Primer diff colors, resolved to `CGColor` for Core Text.
struct DiffTheme {
    let isDark: Bool
    let background: CGColor
    let cardHeader: CGColor
    let border: CGColor
    let text: CGColor
    let mutedText: CGColor
    let emptyCell: CGColor
    let additionLine: CGColor
    let additionNumber: CGColor
    let additionWord: CGColor
    let deletionLine: CGColor
    let deletionNumber: CGColor
    let deletionWord: CGColor
    let hunkLine: CGColor
    let hunkGutter: CGColor
    let additionStat: CGColor
    let deletionStat: CGColor
    let neutralStat: CGColor
    let accent: CGColor
    /// The Pending label of a comment in the viewer's unsubmitted review.
    let pending: CGColor
    let tokens: [TokenKind: CGColor]

    static func resolve(for appearance: NSAppearance) -> DiffTheme {
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
    }

    static let dark = DiffTheme(
        isDark: true,
        background: hex(0x0D1117),
        cardHeader: hex(0x151B23),
        border: hex(0x3D444D),
        text: hex(0xE6EDF3),
        mutedText: hex(0x9198A1),
        emptyCell: hex(0x151B23),
        additionLine: hex(0x12261E),
        additionNumber: hex(0x1C4428),
        additionWord: hex(0x1F5A30),
        deletionLine: hex(0x25171C),
        deletionNumber: hex(0x542426),
        deletionWord: hex(0x7A2C2E),
        hunkLine: hex(0x111D2E),
        hunkGutter: hex(0x182F50),
        additionStat: hex(0x3FB950),
        deletionStat: hex(0xF85149),
        neutralStat: hex(0x3D444D),
        accent: hex(0x4493F8),
        pending: hex(0xD29922),
        tokens: [
            .keyword: hex(0xFF7B72), .operator: hex(0xFF7B72),
            .string: hex(0xA5D6FF),
            .number: hex(0x79C0FF), .constant: hex(0x79C0FF), .property: hex(0x79C0FF), .attribute: hex(0x79C0FF),
            .comment: hex(0x9198A1),
            .function: hex(0xD2A8FF),
            .type: hex(0xFFA657), .variable: hex(0xFFA657),
            .tag: hex(0x7EE787),
        ]
    )

    static let light = DiffTheme(
        isDark: false,
        background: hex(0xFFFFFF),
        cardHeader: hex(0xF6F8FA),
        border: hex(0xD1D9E0),
        text: hex(0x1F2328),
        mutedText: hex(0x59636E),
        emptyCell: hex(0xF6F8FA),
        additionLine: hex(0xDAFBE1),
        additionNumber: hex(0xACEEBB),
        additionWord: hex(0x9AE8AD),
        deletionLine: hex(0xFFEBE9),
        deletionNumber: hex(0xFFCECB),
        deletionWord: hex(0xFFB8B4),
        hunkLine: hex(0xDDF4FF),
        hunkGutter: hex(0xB6E3FF),
        additionStat: hex(0x1A7F37),
        deletionStat: hex(0xD1242F),
        neutralStat: hex(0xD1D9E0),
        accent: hex(0x0969DA),
        pending: hex(0x9A6700),
        tokens: [
            .keyword: hex(0xCF222E), .operator: hex(0xCF222E),
            .string: hex(0x0A3069),
            .number: hex(0x0550AE), .constant: hex(0x0550AE), .property: hex(0x0550AE), .attribute: hex(0x0550AE),
            .comment: hex(0x59636E),
            .function: hex(0x8250DF),
            .type: hex(0x953800), .variable: hex(0x953800),
            .tag: hex(0x116329),
        ]
    )

    private static func hex(_ value: UInt32) -> CGColor {
        CGColor(
            srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}
