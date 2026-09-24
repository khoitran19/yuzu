import AppKit
import QuartzCore

/// Scrolls a view top to bottom at a fixed speed on the display link and reports frame pacing.
@MainActor
final class ScrollPerfHarness: NSObject {
    struct Report: Encodable {
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

    private let scrollView: NSScrollView
    private let pixelsPerSecond: Double
    private let loadMs: Double?
    private let completion: (Report) -> Void
    private var link: CADisplayLink?
    private var lastTimestamp: CFTimeInterval?
    private var startTimestamp: CFTimeInterval = 0
    private var deltas: [Double] = []
    private var expected: [Double] = []
    private var offset: CGFloat = 0

    init(scrollView: NSScrollView, pixelsPerSecond: Double, loadMs: Double?, completion: @escaping (Report) -> Void) {
        self.scrollView = scrollView
        self.pixelsPerSecond = pixelsPerSecond
        self.loadMs = loadMs
        self.completion = completion
    }

    func start() {
        scrollView.contentView.scroll(to: .zero)
        let link = scrollView.displayLink(target: self, selector: #selector(step(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
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
        expected.append(link.duration)

        let maxOffset = max(0, (scrollView.documentView?.bounds.height ?? 0) - scrollView.contentView.bounds.height)
        offset = min(maxOffset, offset + pixelsPerSecond * delta)
        scrollView.contentView.scroll(to: CGPoint(x: 0, y: offset))
        scrollView.reflectScrolledClipView(scrollView.contentView)
        if offset >= maxOffset { finish(link) }
    }

    private func finish(_ link: CADisplayLink) {
        link.invalidate()
        self.link = nil
        let sorted = deltas.sorted()
        func percentile(_ value: Double) -> Double {
            sorted.isEmpty ? 0 : sorted[min(sorted.count - 1, Int(Double(sorted.count) * value))] * 1_000
        }
        let frameBudget = expected.isEmpty ? 1.0 / 60 : expected.reduce(0, +) / Double(expected.count)
        let hitchSeconds = zip(deltas, expected).filter { $0.0 > $0.1 * 1.5 }.reduce(0) { $0 + ($1.0 - $1.1) }
        let duration = (lastTimestamp ?? startTimestamp) - startTimestamp
        completion(Report(
            frames: deltas.count,
            durationSeconds: duration,
            expectedFrameMs: frameBudget * 1_000,
            averageFrameMs: deltas.isEmpty ? 0 : deltas.reduce(0, +) / Double(deltas.count) * 1_000,
            p50FrameMs: percentile(0.5),
            p95FrameMs: percentile(0.95),
            p99FrameMs: percentile(0.99),
            maxFrameMs: (sorted.last ?? 0) * 1_000,
            hitches: zip(deltas, expected).filter { $0.0 > $0.1 * 1.5 }.count,
            hitchTimeRatioMsPerSecond: duration > 0 ? hitchSeconds * 1_000 / duration : 0,
            scrolledPixels: offset,
            loadMs: loadMs
        ))
    }
}
