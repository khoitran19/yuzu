import AppKit
import WebKit

public struct MarkdownPreviewPage: Equatable, Sendable {
    let path: String
    let html: String
    let context: MarkdownHTML.Context
    let status: String
    let changedBlocks: Int
}

/// The rendered Markdown file next to the diff. Page JavaScript is off; only the gutter script runs.
final class MarkdownPreviewViewController: NSViewController, WKNavigationDelegate {
    var onClose: (() -> Void)?
    /// New-side lines of a changed block that the user clicked.
    var onReveal: ((ClosedRange<Int>) -> Void)?
    /// A link to a file at the same commit. Returns `false` when the pull request does not change that file.
    var onOpenPath: ((String) -> Bool)?

    private(set) var page: MarkdownPreviewPage?
    private let world = WKContentWorld.world(name: "markdownPreview")
    private let pathLabel = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(labelWithString: "")
    private let previousButton = NSButton()
    private let nextButton = NSButton()
    private let githubButton = NSButton()
    private let closeButton = NSButton()
    private let spinner = NSProgressIndicator()
    private let messageLabel = NSTextField(wrappingLabelWithString: "")
    private var webView: PreviewWebView!
    private var loadedURL: URL?

    override func loadView() {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        let scripts = configuration.userContentController
        scripts.addUserScript(WKUserScript(source: Self.gutterScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true, in: world))
        scripts.add(MessageProxy(self), contentWorld: world, name: "reveal")
        webView = PreviewWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = self
        webView.setValue(false, forKey: "drawsBackground")
        webView.setAccessibilityIdentifier("markdownPreview.web")
        webView.keyHandler = { [weak self] key in self?.handleKey(key) ?? false }

        let header = NSVisualEffectView()
        header.material = .headerView
        header.blendingMode = .withinWindow
        let icon = NSImageView(image: NSImage(systemSymbolName: "doc.richtext", accessibilityDescription: nil)!)
        icon.contentTintColor = .secondaryLabelColor
        pathLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        pathLabel.lineBreakMode = .byTruncatingHead
        pathLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        statusLabel.font = .systemFont(ofSize: 11)
        statusLabel.textColor = .secondaryLabelColor
        statusLabel.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        configure(previousButton, symbol: "chevron.up", help: "Previous change (p)", action: #selector(previousChange))
        configure(nextButton, symbol: "chevron.down", help: "Next change (n)", action: #selector(nextChange))
        configure(githubButton, symbol: "safari", help: "Open on GitHub", action: #selector(openOnGitHub))
        configure(closeButton, symbol: "xmark", help: "Close preview (Esc)", action: #selector(close))
        closeButton.setAccessibilityIdentifier("markdownPreview.close")
        let spacer = NSView()
        spacer.setContentHuggingPriority(.init(1), for: .horizontal)
        let stack = NSStackView(views: [icon, pathLabel, statusLabel, spacer, previousButton, nextButton, githubButton, closeButton])
        stack.spacing = 6
        stack.setCustomSpacing(10, after: statusLabel)
        stack.edgeInsets = NSEdgeInsets(top: 0, left: 12, bottom: 0, right: 8)
        stack.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(stack)
        let separator = NSBox()
        separator.boxType = .separator

        spinner.style = .spinning
        spinner.controlSize = .small
        messageLabel.alignment = .center
        messageLabel.textColor = .secondaryLabelColor

        let root = NSView(frame: NSRect(x: 0, y: 0, width: 560, height: 600))
        root.setAccessibilityIdentifier("markdownPreview")
        for view in [header, separator, webView!, spinner, messageLabel] as [NSView] {
            view.translatesAutoresizingMaskIntoConstraints = false
            root.addSubview(view)
        }
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: root.topAnchor),
            header.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 36),
            stack.leadingAnchor.constraint(equalTo: header.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: header.trailingAnchor),
            stack.topAnchor.constraint(equalTo: header.topAnchor),
            stack.bottomAnchor.constraint(equalTo: header.bottomAnchor),
            separator.topAnchor.constraint(equalTo: header.bottomAnchor),
            separator.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            webView.topAnchor.constraint(equalTo: separator.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: root.bottomAnchor),
            spinner.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: webView.centerYAnchor),
            messageLabel.centerXAnchor.constraint(equalTo: webView.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: webView.centerYAnchor),
            messageLabel.widthAnchor.constraint(lessThanOrEqualTo: webView.widthAnchor, constant: -48),
        ])
        view = root
    }

    private func configure(_ button: NSButton, symbol: String, help: String, action: Selector) {
        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: help)
        button.bezelStyle = .accessoryBarAction
        button.isBordered = false
        button.imagePosition = .imageOnly
        button.toolTip = help
        button.target = self
        button.action = action
    }

    // MARK: Content

    func showLoading(path: String) {
        loadViewIfNeeded()
        page = nil
        setHeader(path: path, status: "")
        webView.isHidden = true
        messageLabel.isHidden = true
        spinner.isHidden = false
        spinner.startAnimation(nil)
    }

    func show(_ page: MarkdownPreviewPage) {
        loadViewIfNeeded()
        self.page = page
        setHeader(path: page.path, status: page.status)
        previousButton.isEnabled = page.changedBlocks > 0
        nextButton.isEnabled = page.changedBlocks > 0
        githubButton.isEnabled = true
        spinner.stopAnimation(nil)
        spinner.isHidden = true
        messageLabel.isHidden = true
        webView.isHidden = false
        loadedURL = page.context.baseURL
        webView.loadHTMLString(page.html, baseURL: page.context.baseURL)
    }

    func showError(path: String, message: String) {
        loadViewIfNeeded()
        setHeader(path: path, status: "")
        spinner.stopAnimation(nil)
        spinner.isHidden = true
        webView.isHidden = true
        messageLabel.stringValue = "Could not load the preview.\n\(message)"
        messageLabel.isHidden = false
    }

    func clear() {
        page = nil
        loadedURL = nil
        webView?.loadHTMLString("", baseURL: nil)
    }

    private func setHeader(path: String, status: String) {
        pathLabel.stringValue = path
        pathLabel.toolTip = path
        statusLabel.stringValue = status
        previousButton.isEnabled = false
        nextButton.isEnabled = false
        githubButton.isEnabled = false
    }

    // MARK: Actions

    @objc private func previousChange() { step(-1) }
    @objc private func nextChange() { step(1) }
    @objc private func close() { onClose?() }

    @objc private func openOnGitHub() {
        guard let page, let url = URL(string: page.path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? "", relativeTo: page.context.blobRoot)
        else { return }
        NSWorkspace.shared.open(url.absoluteURL)
    }

    private func step(_ delta: Int) {
        guard let page, page.changedBlocks > 0 else { return }
        Task {
            let result = try? await webView.callAsyncJavaScript("return step(delta)", arguments: ["delta": delta], in: nil, contentWorld: world)
            guard let position = result as? [Int], position.count == 2, self.page == page else { return }
            statusLabel.stringValue = "Change \(position[0]) of \(position[1])"
        }
    }

    private func handleKey(_ key: String) -> Bool {
        switch key {
        case "n", "j": step(1)
        case "p", "k": step(-1)
        case "\u{1b}": onClose?()
        default: return false
        }
        return true
    }

    /// Runs `source` in the gutter script's world; the QA harness uses it.
    func evaluate(_ source: String) async -> Any? {
        try? await webView.callAsyncJavaScript(source, arguments: [:], in: nil, contentWorld: world)
    }

    fileprivate func receive(_ message: WKScriptMessage) {
        guard let lines = message.body as? [Int], lines.count == 2, lines[0] <= lines[1] else { return }
        onReveal?(lines[0]...lines[1])
    }

    // MARK: Navigation

    func webView(_ webView: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
        guard action.targetFrame?.isMainFrame == true, let url = action.request.url else { return .cancel }
        if action.navigationType == .other, url == loadedURL || url.absoluteString == "about:blank" { return .allow }
        guard action.navigationType == .linkActivated else { return .cancel }
        if url.fragment != nil, Self.withoutFragment(url) == loadedURL.map(Self.withoutFragment) { return .allow }
        if let path = page?.context.repositoryPath(of: url), onOpenPath?(path) == true { return .cancel }
        if ["http", "https", "mailto"].contains(url.scheme?.lowercased()) { NSWorkspace.shared.open(Self.browserURL(url, context: page?.context)) }
        return .cancel
    }

    private static func withoutFragment(_ url: URL) -> String {
        url.absoluteString.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false).first.map(String.init) ?? ""
    }

    /// Raw links from HTML blocks open as the GitHub file page.
    private static func browserURL(_ url: URL, context: MarkdownHTML.Context?) -> URL {
        guard let context, url.absoluteString.hasPrefix(context.rawRoot.absoluteString) else { return url }
        let rest = url.absoluteString.dropFirst(context.rawRoot.absoluteString.count)
        return URL(string: String(rest), relativeTo: context.blobRoot)?.absoluteURL ?? url
    }

    /// Draws the change bars in a left gutter and steps through changed blocks.
    private static let gutterScript = """
    const marks = () => [...document.querySelectorAll('[data-add],[data-del]')]
    const shown = element => element.classList.contains('html-marker') && element.nextElementSibling || element
    function layout() {
      let gutter = document.getElementById('prv-gutter')
      if (!gutter) { gutter = document.createElement('div'); gutter.id = 'prv-gutter'; document.body.appendChild(gutter) }
      gutter.replaceChildren()
      const origin = document.body.getBoundingClientRect().top
      for (const element of marks()) {
        const rect = shown(element).getBoundingClientRect()
        const added = element.hasAttribute('data-add')
        const bar = document.createElement('div')
        bar.className = added ? 'bar add' : 'bar del'
        bar.style.top = (rect.top - origin - (added ? 0 : 6)) + 'px'
        if (added) bar.style.height = Math.max(rect.height, 4) + 'px'
        bar.title = 'Show in diff'
        bar.addEventListener('click', () => {
          window.webkit.messageHandlers.reveal.postMessage([Number(element.dataset.start), Number(element.dataset.end)])
        })
        bar.addEventListener('mouseenter', () => shown(element).classList.add('prv-hover'))
        bar.addEventListener('mouseleave', () => shown(element).classList.remove('prv-hover'))
        gutter.appendChild(bar)
      }
    }
    let current = -1
    let expectedScroll = -1
    function step(delta) {
      const list = marks().map(shown)
      if (!list.length) return null
      const tops = list.map(element => element.getBoundingClientRect().top + window.scrollY)
      let index
      if (current >= 0 && Math.abs(window.scrollY - expectedScroll) < 2) {
        index = (current + delta + list.length) % list.length
      } else {
        const y = window.scrollY + 24
        index = delta > 0 ? tops.findIndex(top => top > y + 1) : tops.findLastIndex(top => top < y - 1)
        if (index < 0) index = delta > 0 ? 0 : list.length - 1
      }
      current = index
      window.scrollTo(0, tops[index] - 24)
      expectedScroll = window.scrollY
      const element = list[index]
      element.classList.remove('prv-flash')
      void element.offsetWidth
      element.classList.add('prv-flash')
      return [index + 1, list.length]
    }
    new ResizeObserver(layout).observe(document.body)
    layout()
    """
}

private final class MessageProxy: NSObject, WKScriptMessageHandler {
    weak var owner: MarkdownPreviewViewController?

    init(_ owner: MarkdownPreviewViewController) {
        self.owner = owner
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        owner?.receive(message)
    }
}

private final class PreviewWebView: WKWebView {
    var keyHandler: ((String) -> Bool)?

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.intersection([.command, .control, .option]).isEmpty,
           let key = event.charactersIgnoringModifiers, keyHandler?(key) == true {
            return
        }
        super.keyDown(with: event)
    }
}
