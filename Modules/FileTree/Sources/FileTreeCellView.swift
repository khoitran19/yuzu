import AppKit
import CoreText
import PRModels

/// Draws icon, name, and viewed mark directly. Subviews made row creation the largest cost of the first display.
final class FileTreeCellView: NSTableCellView {
    static let reuseIdentifier = NSUserInterfaceItemIdentifier("FileTreeCell")

    private var node: FileTreeNode?
    private var line: CTLine?
    private var lineWidth: CGFloat = 0
    private var truncated: (width: CGFloat, line: CTLine)?

    init() {
        super.init(frame: .zero)
        identifier = Self.reuseIdentifier
        setAccessibilityElement(true)
        setAccessibilityRole(.cell)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not available") }

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet { if backgroundStyle != oldValue { needsDisplay = true } }
    }

    func configure(_ node: FileTreeNode) {
        if self.node?.name != node.name || line == nil {
            let line = CTLineCreateWithAttributedString(NSAttributedString(string: node.name, attributes: Metrics.textAttributes))
            self.line = line
            lineWidth = CTLineGetTypographicBounds(line, nil, nil, nil)
            truncated = nil
        }
        self.node = node
        setAccessibilityIdentifier("fileTree.row.\(node.path)")
        setAccessibilityLabel(Self.accessibilityLabel(for: node))
        needsDisplay = true
    }

    override func draw(_: NSRect) {
        guard let node, let line, let context = NSGraphicsContext.current?.cgContext else { return }
        let emphasized = backgroundStyle == .emphasized
        let height = bounds.height

        if let icon = Symbols.icon(for: node.kind, emphasized: emphasized) {
            let size = icon.size
            icon.draw(in: NSRect(
                x: ((Metrics.iconBox - size.width) / 2).rounded(), y: ((height - size.height) / 2).rounded(),
                width: size.width, height: size.height
            ))
        }

        let isViewedFile = node.isViewed && !node.isDirectory
        var trailing = bounds.width - 4
        if isViewedFile, let checkmark = Symbols.checkmark(emphasized: emphasized) {
            let size = checkmark.size
            trailing = bounds.width - 6 - size.width
            checkmark.draw(in: NSRect(x: trailing, y: ((height - size.height) / 2).rounded(), width: size.width, height: size.height))
            trailing -= 6
        }

        let textX = Metrics.iconBox + 6
        let available = max(0, trailing - textX)
        let drawn = lineWidth <= available ? line : truncatedLine(line, width: available)
        let color: NSColor = emphasized ? .alternateSelectedControlTextColor : (isViewedFile ? .secondaryLabelColor : .labelColor)
        context.saveGState()
        context.setFillColor(color.cgColor)
        context.textMatrix = .identity
        context.textPosition = CGPoint(x: textX, y: ((height - Metrics.lineHeight) / 2 + Metrics.descent).rounded())
        CTLineDraw(drawn, context)
        context.restoreGState()
    }

    private func truncatedLine(_ line: CTLine, width: CGFloat) -> CTLine {
        if let truncated, truncated.width == width { return truncated.line }
        let result = CTLineCreateTruncatedLine(line, width, .middle, Metrics.ellipsis) ?? line
        truncated = (width, result)
        return result
    }

    private static func accessibilityLabel(for node: FileTreeNode) -> String {
        switch node.kind {
        case .directory: node.name
        case let .file(status):
            node.isViewed ? "\(node.name), \(Symbols.statusName(status)), viewed" : "\(node.name), \(Symbols.statusName(status))"
        }
    }
}

private enum Metrics {
    static let font = NSFont.systemFont(ofSize: 13)
    static let iconBox: CGFloat = 16
    static let textAttributes: [NSAttributedString.Key: Any] = [
        .font: font,
        NSAttributedString.Key(kCTForegroundColorFromContextAttributeName as String): true,
    ]
    static let descent = -font.descender
    static let lineHeight = font.ascender + descent
    static let ellipsis = CTLineCreateWithAttributedString(NSAttributedString(string: "…", attributes: textAttributes))
}

private enum Symbols {
    private static let folder = pair("folder.fill", color: .secondaryLabelColor)
    private static let added = pair("plus.square", color: .systemGreen)
    private static let removed = pair("minus.square", color: .systemRed)
    private static let renamed = pair("arrow.right.square", color: .secondaryLabelColor)
    private static let modified = pair("doc", color: .secondaryLabelColor)
    private static let check = pair("checkmark", color: .secondaryLabelColor, pointSize: 11)

    static func icon(for kind: FileTreeNode.Kind, emphasized: Bool) -> NSImage? {
        let pair = switch kind {
        case .directory: folder
        case .file(.added), .file(.copied): added
        case .file(.removed): removed
        case .file(.renamed): renamed
        case .file(.modified), .file(.changed), .file(.unchanged): modified
        }
        return emphasized ? pair.emphasized : pair.normal
    }

    static func checkmark(emphasized: Bool) -> NSImage? {
        emphasized ? check.emphasized : check.normal
    }

    static func statusName(_ status: ChangedFile.Status) -> String {
        switch status {
        case .added: "added"
        case .copied: "copied"
        case .removed: "removed"
        case .renamed: "renamed"
        case .modified, .changed, .unchanged: "modified"
        }
    }

    private static func pair(_ name: String, color: NSColor, pointSize: CGFloat = 13) -> (normal: NSImage?, emphasized: NSImage?) {
        let base = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
            .withSymbolConfiguration(.init(pointSize: pointSize, weight: .regular))
        return (
            base?.withSymbolConfiguration(.init(paletteColors: [color])),
            base?.withSymbolConfiguration(.init(paletteColors: [.alternateSelectedControlTextColor]))
        )
    }
}
