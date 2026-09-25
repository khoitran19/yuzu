import AppKit
import AppShortcuts
import PRModels

/// What a comment box writes.
public enum CommentComposer: Hashable, Sendable {
    case newThread(CommentTarget)
    case reply(thread: String)
    case edit(comment: String)
}

/// How a comment box posts its text.
public enum CommentSubmit: Sendable, Equatable {
    /// A published comment, at once.
    case single
    /// Into the viewer's pending review; the model starts one when there is none.
    case review
    /// A changed comment.
    case update
}

/// One open comment box. It keeps its text view, so the text stays while the row is off screen.
final class Composer {
    enum Anchor: Equatable {
        case line(side: DiffSide, number: Int)
        case thread(id: String)
    }

    static let outerPadding: CGFloat = 8
    static let innerPadding: CGFloat = 10
    static let minTextHeight: CGFloat = 64
    static let maxTextHeight: CGFloat = 320
    static let buttonRowHeight: CGFloat = 28
    static let errorHeight: CGFloat = 18

    let key: CommentComposer
    let path: String
    let anchor: Anchor
    let side: DiffSide
    let view: ComposerRowView
    var textHeight = Composer.minTextHeight
    var busy = false { didSet { view.update() } }
    var error: String? { didSet { view.update() } }

    init(key: CommentComposer, path: String, anchor: Anchor, side: DiffSide, text: String) {
        self.key = key
        self.path = path
        self.anchor = anchor
        self.side = side
        view = ComposerRowView()
        view.composer = self
        view.setText(text)
    }

    var height: CGFloat {
        Self.outerPadding * 2 + Self.innerPadding * 3 + textHeight + Self.buttonRowHeight + (error == nil ? 0 : Self.errorHeight)
    }
}

/// The only diff row with subviews: a text view and buttons. Other rows draw.
final class ComposerRowView: DiffRowView {
    static let composerIdentifier = NSUserInterfaceItemIdentifier("ComposerRow")

    weak var composer: Composer?
    var hasPendingReview = false { didSet { if hasPendingReview != oldValue { update() } } }
    var onSubmit: ((CommentSubmit) -> Void)?
    var onCancel: (() -> Void)?
    var onHeightChange: (() -> Void)?

    private let scroll = NSScrollView()
    private let textView = ComposerTextView()
    private let placeholder = NSTextField(labelWithString: "")
    private let errorLabel = NSTextField(labelWithString: "")
    private let spinner = NSProgressIndicator()
    private let cancelButton = NSButton(title: "Cancel", target: nil, action: nil)
    private let singleButton = NSButton(title: "Add single comment", target: nil, action: nil)
    private let primaryButton = NSButton(title: "Start a review", target: nil, action: nil)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        identifier = Self.composerIdentifier
        textView.isRichText = false
        textView.allowsUndo = true
        textView.font = Metrics.bodyFont
        textView.textContainerInset = NSSize(width: 4, height: 6)
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.drawsBackground = false
        textView.isVerticallyResizable = true
        textView.autoresizingMask = .width
        textView.textContainer?.widthTracksTextView = true
        textView.delegate = self
        textView.onSubmit = { [weak self] single in self?.submit(single: single) }
        textView.onCancel = { [weak self] in self?.onCancel?() }
        textView.setAccessibilityIdentifier("diff.composer.text")
        scroll.documentView = textView
        scroll.hasVerticalScroller = true
        scroll.autohidesScrollers = true
        scroll.drawsBackground = false
        scroll.borderType = .noBorder
        placeholder.textColor = .placeholderTextColor
        placeholder.font = Metrics.bodyFont
        errorLabel.textColor = .systemRed
        errorLabel.font = Metrics.uiFont
        errorLabel.lineBreakMode = .byTruncatingTail
        spinner.style = .spinning
        spinner.controlSize = .small
        spinner.isDisplayedWhenStopped = false
        for button in [cancelButton, singleButton, primaryButton] {
            button.bezelStyle = .push
            button.controlSize = .regular
            button.target = self
        }
        cancelButton.action = #selector(cancel)
        singleButton.action = #selector(single)
        primaryButton.action = #selector(primary)
        primaryButton.keyEquivalent = ""
        primaryButton.bezelColor = .controlAccentColor
        primaryButton.setAccessibilityIdentifier("diff.composer.primary")
        singleButton.setAccessibilityIdentifier("diff.composer.single")
        for view in [scroll, placeholder, errorLabel, spinner, cancelButton, singleButton, primaryButton] as [NSView] {
            addSubview(view)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    var text: String { textView.string }

    func setText(_ text: String) {
        textView.string = text
        update()
    }

    func focus() {
        window?.makeFirstResponder(textView)
    }

    func update() {
        guard let composer else { return }
        let editing = if case .edit = composer.key { true } else { false }
        let reply = if case .reply = composer.key { true } else { false }
        placeholder.stringValue = reply ? "Reply…" : "Leave a comment"
        placeholder.isHidden = !textView.string.isEmpty
        primaryButton.title = editing ? "Update comment" : hasPendingReview ? "Add review comment" : "Start a review"
        primaryButton.toolTip = "\(primaryButton.title) (\(Shortcut.submitSheet.symbols))"
        singleButton.isHidden = editing || hasPendingReview
        singleButton.toolTip = "Add single comment (\(Shortcut.addSingleComment.symbols))"
        let empty = textView.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        primaryButton.isEnabled = !composer.busy && !empty
        singleButton.isEnabled = !composer.busy && !empty
        cancelButton.isEnabled = !composer.busy
        textView.isEditable = !composer.busy
        composer.busy ? spinner.startAnimation(nil) : spinner.stopAnimation(nil)
        errorLabel.stringValue = composer.error ?? ""
        errorLabel.isHidden = composer.error == nil
        needsLayout = true
    }

    override func layout() {
        super.layout()
        guard let composer, let renderer, let ref else { return }
        let box = renderer.composerBox(ref, composer: composer, bounds: bounds)
        let inner = box.insetBy(dx: Composer.innerPadding, dy: Composer.innerPadding)
        scroll.frame = CGRect(x: inner.minX, y: inner.minY, width: inner.width, height: composer.textHeight)
        placeholder.sizeToFit()
        placeholder.frame.origin = CGPoint(x: inner.minX + 9, y: inner.minY + 6)
        var y = scroll.frame.maxY + Composer.innerPadding
        if composer.error != nil {
            errorLabel.frame = CGRect(x: inner.minX, y: y, width: inner.width, height: Composer.errorHeight)
            y += Composer.errorHeight
        }
        var x = inner.maxX
        for button in [primaryButton, singleButton, cancelButton] where !button.isHidden {
            button.sizeToFit()
            let width = max(button.frame.width, 72)
            x -= width
            button.frame = CGRect(x: x, y: y, width: width, height: Composer.buttonRowHeight)
            x -= 8
        }
        spinner.sizeToFit()
        spinner.frame.origin = CGPoint(x: x - spinner.frame.width, y: y + (Composer.buttonRowHeight - spinner.frame.height) / 2)
        measureText(width: inner.width)
    }

    /// Grows the box with the text, up to `Composer.maxTextHeight`; then the text scrolls.
    private func measureText(width: CGFloat) {
        guard let composer, let layoutManager = textView.layoutManager, let container = textView.textContainer else { return }
        layoutManager.ensureLayout(for: container)
        let used = layoutManager.usedRect(for: container).height + textView.textContainerInset.height * 2
        let height = min(Composer.maxTextHeight, max(Composer.minTextHeight, ceil(used)))
        guard height != composer.textHeight else { return }
        composer.textHeight = height
        onHeightChange?()
    }

    override func mouseDown(with event: NSEvent) {}
    override func mouseDragged(with event: NSEvent) {}
    override func mouseUp(with event: NSEvent) {}

    private func submit(single: Bool) {
        guard let composer, !composer.busy else { return }
        guard !textView.string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return NSSound.beep() }
        if case .edit = composer.key { return onSubmit?(.update) ?? () }
        if single, hasPendingReview { return NSSound.beep() }
        onSubmit?(single ? .single : .review)
    }

    @objc private func cancel() { onCancel?() }
    @objc private func single() { submit(single: true) }
    @objc private func primary() { submit(single: false) }
}

extension ComposerRowView: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        update()
    }
}

/// ⌘↩ posts with the main button, ⌥⌘↩ adds a single comment, and Esc cancels.
private final class ComposerTextView: NSTextView {
    var onSubmit: ((_ single: Bool) -> Void)?
    var onCancel: (() -> Void)?

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard window?.firstResponder === self else { return super.performKeyEquivalent(with: event) }
        if Shortcut.addSingleComment.matches(event) {
            onSubmit?(true)
            return true
        }
        if Shortcut.submitSheet.matches(event) {
            onSubmit?(false)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    override func cancelOperation(_ sender: Any?) {
        onCancel?()
    }
}
