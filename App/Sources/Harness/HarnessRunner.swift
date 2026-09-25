import AppKit
import WebKit
import PRDetail
import PRList
import PRModels

/// Drives a loaded pull request for QA: applies launch actions, then writes a screenshot or a scroll report and quits.
@MainActor
final class HarnessRunner {
    private let options: LaunchOptions
    private let model: PRDetailModel
    private let pullRequestList: PRListModel
    private let window: NSWindow?
    private let openTab: (PRRef) -> Void
    private let submit: (String) -> Void
    private var perf: ScrollPerfHarness?

    init(
        options: LaunchOptions, model: PRDetailModel, pullRequestList: PRListModel, window: NSWindow?,
        openTab: @escaping (PRRef) -> Void, submit: @escaping (String) -> Void
    ) {
        self.options = options
        self.model = model
        self.pullRequestList = pullRequestList
        self.window = window
        self.openTab = openTab
        self.submit = submit
    }

    func run() {
        Task {
            if options.collapseAll { model.setAllCollapsed(true) }
            for path in options.toggleViewed {
                model.setViewed(!model.viewedPaths.contains(path), paths: [path])
            }
            for (path, hunk) in options.expand { model.expand(path, hunk: hunk) }
            if let scope = options.pullRequestList { pullRequestList.request(scope) }
            try? await Task.sleep(for: .seconds(options.settleSeconds / 2))
            if let path = options.scrollToFile { model.filesController.diff.scrollToFile(path) }
            if let path = options.preview { model.filesController.togglePreview(path) }
            if let script = options.previewScript {
                try? await Task.sleep(for: .seconds(options.settleSeconds / 2))
                let result = await model.filesController.evaluatePreviewScript(script)
                log(["event": "previewScript", "result": String(describing: result ?? "nil")])
            }
            if let scroll = options.summaryScroll { await scrollSummary(to: scroll) }
            if let selector = options.summaryClick { await clickSummary(selector) }
            await openTabsAndSendKeys()
            try? await Task.sleep(for: .seconds(options.settleSeconds / 2))
            let loadMs = Self.milliseconds(model.liveLoad)
            log([
                "event": "loaded", "firstPaintMs": String(format: "%.1f", Self.milliseconds(model.firstPaint)),
                "loadMs": String(format: "%.1f", loadMs), "files": "\(model.fileCount)", "rows": "\(model.filesController.diff.rowCount)",
            ])

            let window = window?.tabGroup?.selectedWindow ?? window ?? NSApp.windows.first { $0.isVisible && $0.canBecomeMain }
            if let url = options.screenshot, let window {
                do {
                    try await WindowSnapshot.write(window, to: url)
                    log(["event": "screenshot", "path": url.path])
                } catch {
                    log(["event": "error", "message": error.localizedDescription])
                }
            }
            guard let output = options.perfOutput else { return NSApp.terminate(nil) }
            let harness = ScrollPerfHarness(
                scrollView: model.filesController.diff.scrollView,
                pixelsPerSecond: options.perfPixelsPerSecond,
                loadMs: loadMs
            ) { report in
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                if let data = try? encoder.encode(report) {
                    try? data.write(to: output)
                }
                NSApp.terminate(nil)
            }
            harness.describeSlowFrame = { [diff = model.filesController.diff] in diff.visibleRowSummary }
            perf = harness
            NSApp.activate()
            window?.makeKeyAndOrderFront(nil)
            log(["event": "perf-start"])
            harness.start()
        }
    }

    private func openTabsAndSendKeys() async {
        guard !options.openTabs.isEmpty || !options.keys.isEmpty || !options.submits.isEmpty else { return }
        NSApp.activate()
        window?.makeKeyAndOrderFront(nil)
        for ref in options.openTabs {
            openTab(ref)
            try? await Task.sleep(for: .milliseconds(500))
        }
        for text in options.submits {
            submit(text)
            try? await Task.sleep(for: .milliseconds(50))
        }
        if !options.submits.isEmpty { try? await Task.sleep(for: .seconds(options.settleSeconds)) }
        for key in options.keys {
            let handled = Self.keyEvent(key).map { NSApp.mainMenu?.performKeyEquivalent(with: $0) == true } ?? false
            try? await Task.sleep(for: .milliseconds(300))
            log(["event": "key", "key": key, "handled": "\(handled)", "selected": window?.tabGroup?.selectedWindow?.title ?? ""])
        }
        let group = window?.tabGroup
        log([
            "event": "tabs", "titles": (group?.windows ?? []).map(\.title).joined(separator: " | "),
            "selected": group?.selectedWindow?.title ?? "",
        ])
    }

    /// A US-layout key event, for example `shift+cmd+]`.
    private static func keyEvent(_ combo: String) -> NSEvent? {
        let parts = combo.split(separator: "+").map(String.init)
        guard let key = parts.last else { return nil }
        var flags: NSEvent.ModifierFlags = []
        for part in parts.dropLast() {
            switch part {
            case "cmd": flags.insert(.command)
            case "shift": flags.insert(.shift)
            case "option": flags.insert(.option)
            case "ctrl": flags.insert(.control)
            default: return nil
            }
        }
        let shifted = ["[": "{", "]": "}"]
        let characters = flags.contains(.shift) ? shifted[key] ?? key.uppercased() : key
        let keyCodes: [String: UInt16] = ["[": 33, "]": 30, "p": 35, "d": 2]
        return NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0, windowNumber: NSApp.keyWindow?.windowNumber ?? 0,
            context: nil, characters: characters, charactersIgnoringModifiers: characters, isARepeat: false,
            keyCode: keyCodes[key] ?? 0
        )
    }

    private func scrollSummary(to value: String) async {
        let y = value == "bottom" ? "document.body.scrollHeight" : String(Double(value) ?? 0)
        let window = window ?? NSApp.windows.first { $0.isVisible && $0.canBecomeMain }
        guard let root = window?.contentView, let webView = Self.webView(in: root) else { return }
        // Items with `content-visibility: auto` change the page height after they render, so scroll until it is stable.
        for _ in 0..<6 {
            _ = try? await webView.evaluateJavaScript("window.scrollTo(0, \(y))")
            try? await Task.sleep(for: .milliseconds(200))
        }
    }

    private func clickSummary(_ selector: String) async {
        let window = window ?? NSApp.windows.first { $0.isVisible && $0.canBecomeMain }
        guard let root = window?.contentView, let webView = Self.webView(in: root) else { return }
        let result = try? await webView.callAsyncJavaScript(
            "return activate(selector)", arguments: ["selector": selector], contentWorld: .summarySidebar
        )
        log(["event": "summaryClick", "selector": selector, "found": String(describing: result ?? "nil")])
    }

    private static func webView(in view: NSView) -> WKWebView? {
        if let webView = view as? WKWebView { return webView }
        return view.subviews.lazy.compactMap(webView(in:)).first
    }

    private static func milliseconds(_ duration: Duration?) -> Double {
        guard let duration else { return -1 }
        return Double(duration.components.seconds) * 1_000 + Double(duration.components.attoseconds) / 1e15
    }

    private func log(_ fields: [String: String]) {
        let data = (try? JSONSerialization.data(withJSONObject: fields, options: [.sortedKeys])) ?? Data()
        FileHandle.standardError.write(Data("[harness] \(String(decoding: data, as: UTF8.self))\n".utf8))
    }
}
