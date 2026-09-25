import AppKit
import QuartzCore

class DiffRowView: NSTableRowView {
    static let identifier = NSUserInterfaceItemIdentifier("DiffRow")
    static let traceDraw = ProcessInfo.processInfo.environment["YUZU_TRACE_DRAW"] != nil

    weak var renderer: DiffRenderer?
    var onHit: ((HitTarget, RowRef) -> Void)?
    var onSelect: ((NSEvent, _ phase: SelectPhase) -> Void)?

    enum SelectPhase { case begin, drag, end }
    var ref: RowRef? {
        didSet { if ref != oldValue { needsDisplay = true } }
    }

    override var isFlipped: Bool { true }
    override var isOpaque: Bool { true }
    override var wantsDefaultClipping: Bool { false }

    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        layer?.drawsAsynchronously = true
    }

    override var isFloating: Bool {
        didSet { if isFloating != oldValue { needsDisplay = true } }
    }

    override func drawBackground(in dirtyRect: NSRect) {}
    override func drawSelection(in dirtyRect: NSRect) {}
    override func drawSeparator(in dirtyRect: NSRect) {}

    override func draw(_ dirtyRect: NSRect) {
        guard let ref, let renderer, let context = NSGraphicsContext.current?.cgContext else { return }
        let begin = CACurrentMediaTime()
        renderer.draw(ref, in: bounds, dirty: dirtyRect, context: context, floating: isFloating)
        if Self.traceDraw { FileHandle.standardError.write(Data("[draw] \(ref.kind) h=\(Int(bounds.height)) dirty=\(Int(dirtyRect.minY))+\(Int(dirtyRect.height)) \(String(format: "%.2f", (CACurrentMediaTime() - begin) * 1000))ms\n".utf8)) }
    }

    override func mouseDown(with event: NSEvent) {
        guard let ref, let renderer else { return super.mouseDown(with: event) }
        let point = convert(event.locationInWindow, from: nil)
        if let target = renderer.hitTest(ref, point: point, bounds: bounds) {
            onHit?(target, ref)
        } else {
            onSelect?(event, .begin)
        }
    }

    override func mouseDragged(with event: NSEvent) {
        onSelect?(event, .drag)
    }

    override func mouseUp(with event: NSEvent) {
        onSelect?(event, .end)
    }

    override func resetCursorRects() {
        switch ref?.kind {
        case .header, .notice, .expandTail, .hunk:
            addCursorRect(bounds.insetBy(dx: Metrics.cardInset, dy: 0), cursor: .pointingHand)
        default:
            return
        }
    }
}

final class DiffTableView: NSTableView {
    var keyHandler: ((NSEvent) -> Bool)?
    var copyHandler: (() -> Bool)?
    /// The mouse position in table coordinates, or `nil` when it leaves.
    var hoverHandler: ((CGPoint?) -> Void)?
    private var hoverArea: NSTrackingArea?

    /// `.inVisibleRect` follows scrolling, so the area is made once.
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard hoverArea == nil else { return }
        let options: NSTrackingArea.Options = [.mouseMoved, .mouseEnteredAndExited, .activeInKeyWindow, .inVisibleRect]
        let area = NSTrackingArea(rect: .zero, options: options, owner: self)
        addTrackingArea(area)
        hoverArea = area
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        hoverHandler?(convert(event.locationInWindow, from: nil))
    }

    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        hoverHandler?(nil)
    }

    @objc func copy(_ sender: Any?) {
        _ = copyHandler?()
    }

    override func validateUserInterfaceItem(_ item: any NSValidatedUserInterfaceItem) -> Bool {
        item.action == #selector(copy(_:)) ? copyHandler != nil : super.validateUserInterfaceItem(item)
    }

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if keyHandler?(event) == true { return }
        super.keyDown(with: event)
    }

    override func validateProposedFirstResponder(_ responder: NSResponder, for event: NSEvent?) -> Bool { true }
}

/// Runs a closure for a menu item. The item keeps it as its represented object.
final class MenuAction: NSObject {
    private let handler: () -> Void

    init(_ handler: @escaping () -> Void) {
        self.handler = handler
    }

    @objc func run() { handler() }

    static func item(_ title: String, handler: @escaping () -> Void) -> NSMenuItem {
        let action = MenuAction(handler)
        let item = NSMenuItem(title: title, action: #selector(run), keyEquivalent: "")
        item.target = action
        item.representedObject = action
        return item
    }
}
