import AppKit
import WebKit

enum WindowSnapshot {
    /// Renders the window content in-process, so it needs no screen-recording permission.
    static func write(_ window: NSWindow, to url: URL) async throws {
        guard let view = window.contentView?.superview ?? window.contentView else { return }
        let bounds = view.bounds
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: bounds) else { return }
        view.cacheDisplay(in: bounds, to: bitmap)
        try await drawWebViews(in: view, onto: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else { return }
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }

    /// `cacheDisplay` leaves web views blank: WebKit draws them in another process.
    private static func drawWebViews(in root: NSView, onto bitmap: NSBitmapImageRep) async throws {
        for webView in webViews(in: root) where isVisible(webView) {
            let image = try await webView.takeSnapshot(configuration: nil)
            var rect = root.convert(webView.bounds, from: webView)
            if root.isFlipped { rect.origin.y = root.bounds.height - rect.maxY }
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
            image.draw(in: rect)
            NSGraphicsContext.restoreGraphicsState()
        }
    }

    private static func webViews(in view: NSView) -> [WKWebView] {
        if let webView = view as? WKWebView { return [webView] }
        return view.subviews.flatMap(webViews(in:))
    }

    private static func isVisible(_ view: NSView) -> Bool {
        var current: NSView? = view
        while let next = current {
            if next.isHidden || next.alphaValue == 0 || next.layer?.opacity == 0 { return false }
            current = next.superview
        }
        return true
    }
}
