import AppKit
import PRDetail

/// Drives a loaded pull request for QA: applies launch actions, then writes a screenshot or a scroll report and quits.
@MainActor
final class HarnessRunner {
    private let options: LaunchOptions
    private let model: PRDetailModel
    private let window: NSWindow?
    private let loadDuration: Duration
    private var perf: ScrollPerfHarness?

    init(options: LaunchOptions, model: PRDetailModel, window: NSWindow?, loadDuration: Duration) {
        self.options = options
        self.model = model
        self.window = window
        self.loadDuration = loadDuration
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
            try? await Task.sleep(for: .seconds(options.settleSeconds / 2))
            let loadMs = Double(loadDuration.components.attoseconds) / 1e15 + Double(loadDuration.components.seconds) * 1_000
            log(["event": "loaded", "loadMs": String(format: "%.1f", loadMs), "files": "\(model.fileCount)", "rows": "\(model.filesController.diff.rowCount)"])

            let window = window ?? NSApp.windows.first { $0.isVisible && $0.canBecomeMain }
            if let url = options.screenshot, let window {
                do {
                    try WindowSnapshot.write(window, to: url)
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

    private func log(_ fields: [String: String]) {
        let data = (try? JSONSerialization.data(withJSONObject: fields, options: [.sortedKeys])) ?? Data()
        FileHandle.standardError.write(Data("[harness] \(String(decoding: data, as: UTF8.self))\n".utf8))
    }
}
