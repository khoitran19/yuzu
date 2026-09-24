import AppKit
import QuartzCore

/// Scrolls a view top to bottom at a fixed speed and reports frame pacing.
/// Uses the display link when the display is awake; otherwise it forces a redraw per step and times main-thread work.
@MainActor
final class ScrollPerfHarness: NSObject {
    enum Mode: String, Encodable {
        case displayLink
        /// Display asleep or headless: frame time is the main-thread time to scroll, lay out, and draw one step.
        case forcedDisplay
    }

    struct Report: Encodable {
        let mode: Mode
        let frames: Int
        let durationSeconds: Double
        let expectedFrameMs: Double
        let averageFrameMs: Double
        let p50FrameMs: Double
        let p95FrameMs: Double
        let p99FrameMs: Double
        let maxFrameMs: Double
        let hitches: Int
        /// Apple's metric: under 5 is good, over 10 is poor.
        let hitchTimeRatioMsPerSecond: Double
        let scrolledPixels: Double
        let loadMs: Double?
    }

    private static let maxDuration: Double = 30
    private static let forcedFrameBudget = 1.0 / 120

    private let scrollView: NSScrollView
    private let pixelsPerSecond: Double
    private let loadMs: Double?
    private let completion: (Report) -> Void
    var describeSlowFrame: (() -> String)?
    private var link: CADisplayLink?
    private var timer: Timer?
    private var mode = Mode.displayLink
    private var lastTimestamp: CFTimeInterval?
    private var startTimestamp: CFTimeInterval = 0
    private var deltas: [Double] = []
    private var budgets: [Double] = []
    private var offset: CGFloat = 0
    private var finished = false

    init(scrollView: NSScrollView, pixelsPerSecond: Double, loadMs: Double?, completion: @escaping (Report) -> Void) {
        self.scrollView = scrollView
        self.pixelsPerSecond = pixelsPerSecond
        self.loadMs = loadMs
        self.completion = completion
    }

    func start() {
        scroll(to: 0)
        let link = scrollView.displayLink(target: self, selector: #selector(step(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
        Task {
            try? await Task.sleep(for: .seconds(1))
            if lastTimestamp == nil, !finished { startForcedDisplay() }
        }
    }

    @objc private func step(_ link: CADisplayLink) {
        guard let last = lastTimestamp else {
            lastTimestamp = link.timestamp
            startTimestamp = link.timestamp
            return
        }
        let delta = link.timestamp - last
        lastTimestamp = link.timestamp
        deltas.append(delta)
        budgets.append(link.duration)
        advance(by: delta, elapsed: link.timestamp - startTimestamp)
    }

    private func startForcedDisplay() {
        link?.invalidate()
        link = nil
        mode = .forcedDisplay
        startTimestamp = CACurrentMediaTime()
        let timer = Timer(timeInterval: Self.forcedFrameBudget, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.forcedStep() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func forcedStep() {
        let begin = CACurrentMediaTime()
        advance(by: Self.forcedFrameBudget, elapsed: begin - startTimestamp)
        scrollView.window?.displayIfNeeded()
        CATransaction.flush()
        let work = CACurrentMediaTime() - begin
        deltas.append(work)
        budgets.append(Self.forcedFrameBudget)
        if work > Self.forcedFrameBudget * 1.5, let describe = describeSlowFrame {
            FileHandle.standardError.write(Data("[harness] slow \(Int(work * 1_000))ms at \(Int(offset)): \(describe())\n".utf8))
        }
    }

    private func advance(by seconds: Double, elapsed: Double) {
        let maxOffset = max(0, (scrollView.documentView?.bounds.height ?? 0) - scrollView.contentView.bounds.height)
        offset = min(maxOffset, offset + pixelsPerSecond * seconds)
        scroll(to: offset)
        if offset >= maxOffset || elapsed > Self.maxDuration { finish(duration: elapsed) }
    }

    private func scroll(to y: CGFloat) {
        scrollView.contentView.scroll(to: CGPoint(x: 0, y: y))
        scrollView.reflectScrolledClipView(scrollView.contentView)
    }

    private func finish(duration: Double) {
        guard !finished else { return }
        finished = true
        link?.invalidate()
        timer?.invalidate()
        let sorted = deltas.sorted()
        func percentile(_ value: Double) -> Double {
            sorted.isEmpty ? 0 : sorted[min(sorted.count - 1, Int(Double(sorted.count) * value))] * 1_000
        }
        let pairs = zip(deltas, budgets)
        let hitchPairs = pairs.filter { $0.0 > $0.1 * 1.5 }
        let hitchSeconds = hitchPairs.reduce(0) { $0 + ($1.0 - $1.1) }
        let budget = budgets.isEmpty ? Self.forcedFrameBudget : budgets.reduce(0, +) / Double(budgets.count)
        completion(Report(
            mode: mode,
            frames: deltas.count,
            durationSeconds: duration,
            expectedFrameMs: budget * 1_000,
            averageFrameMs: deltas.isEmpty ? 0 : deltas.reduce(0, +) / Double(deltas.count) * 1_000,
            p50FrameMs: percentile(0.5),
            p95FrameMs: percentile(0.95),
            p99FrameMs: percentile(0.99),
            maxFrameMs: (sorted.last ?? 0) * 1_000,
            hitches: hitchPairs.count,
            hitchTimeRatioMsPerSecond: duration > 0 ? hitchSeconds * 1_000 / duration : 0,
            scrolledPixels: offset,
            loadMs: loadMs
        ))
    }
}
