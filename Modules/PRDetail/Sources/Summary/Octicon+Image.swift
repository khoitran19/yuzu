import AppKit

extension Octicon {
    /// A template image, so SwiftUI `foregroundStyle` and AppKit tint colors apply.
    public var image: NSImage {
        let image = NSImage(data: Data(svg().utf8)) ?? NSImage()
        image.isTemplate = true
        return image
    }
}
