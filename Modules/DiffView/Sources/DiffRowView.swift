import AppKit
import QuartzCore

final class DiffRowView: NSTableRowView {
    static let identifier = NSUserInterfaceItemIdentifier("DiffRow")
    static let traceDraw = ProcessInfo.processInfo.environment["PRVIEWER_TRACE_DRAW"] != nil

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
