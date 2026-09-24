import AppKit
import WebKit
import PRDetail

/// Drives a loaded pull request for QA: applies launch actions, then writes a screenshot or a scroll report and quits.
@MainActor
final class HarnessRunner {
    private let options: LaunchOptions
    private let model: PRDetailModel
    private let window: NSWindow?
    private var perf: ScrollPerfHarness?

    init(options: LaunchOptions, model: PRDetailModel, window: NSWindow?) {
        self.options = options
        self.model = model
        self.window = window
    }

    func run() {
        Task {
            if options.collapseAll { model.setAllCollapsed(true) }
            for path in options.toggleViewed {
                model.setViewed(!model.viewedPaths.contains(path), paths: [path])
            }
            for (path, hunk) in options.expand { model.expand(path, hunk: hunk) }
            try? await Task.sleep(for: .seconds(options.settleSeconds / 2))
            if let path = options.scrollToFile { model.filesController.diff.scrollToFile(path) }
            if let scroll = options.summaryScroll { await scrollSummary(to: scroll) }
            try? await Task.sleep(for: .seconds(options.settleSeconds / 2))
            let loadMs = Self.milliseconds(model.liveLoad)
            log([
                "event": "loaded", "firstPaintMs": String(format: "%.1f", Self.milliseconds(model.firstPaint)),
                "loadMs": String(format: "%.1f", loadMs), "files": "\(model.fileCount)", "rows": "\(model.filesController.diff.rowCount)",
            ])

            let window = window ?? NSApp.windows.first { $0.isVisible && $0.canBecomeMain }
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
