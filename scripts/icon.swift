// Usage: swift scripts/icon.swift <artwork.png> <AppIcon.appiconset>
// Masks full-bleed artwork to the macOS icon grid and writes every App Icon size.
// Sizes of 32 px and less use a simplified vector drawing, because the artwork blurs at that size.
import AppKit
import SwiftUI

let args = CommandLine.arguments
guard args.count == 3, let artwork = NSImage(contentsOfFile: args[1]) else {
    FileHandle.standardError.write(Data("usage: icon.swift <artwork.png> <AppIcon.appiconset>\n".utf8))
    exit(1)
}
let outDir = URL(fileURLWithPath: args[2])
try FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

// Apple macOS icon grid on a 1024 canvas: 824 pt body, 185.4 pt continuous corners.
let canvas: CGFloat = 1024
let body = CGRect(x: 100, y: 100, width: 824, height: 824)
let mask = RoundedRectangle(cornerRadius: 185.4, style: .continuous).path(in: body).cgPath

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = context
    let cg = context.cgContext
    cg.interpolationQuality = .high
    cg.scaleBy(x: CGFloat(pixels) / canvas, y: CGFloat(pixels) / canvas)

    cg.saveGState()
    cg.setShadow(offset: CGSize(width: 0, height: -10), blur: 20, color: NSColor.black.withAlphaComponent(0.3).cgColor)
    cg.addPath(mask)
    cg.setFillColor(NSColor.black.cgColor)
    cg.fillPath()
    cg.restoreGState()

    cg.saveGState()
    cg.addPath(mask)
    cg.clip()
    if pixels <= 32 { drawSmall(cg) } else { artwork.draw(in: body, from: .zero, operation: .sourceOver, fraction: 1) }
    cg.restoreGState()

    NSGraphicsContext.current = nil
    return rep.representation(using: .png, properties: [:])!
}

func drawSmall(_ cg: CGContext) {
    let gradient = CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB),
        colors: [rgb(0x24, 0x0C, 0xA8), rgb(0x7A, 0x3C, 0xF6)] as CFArray,
        locations: [0, 1]
    )!
    cg.drawLinearGradient(gradient, start: CGPoint(x: 100, y: 100), end: CGPoint(x: 924, y: 924), options: [])
    // Coordinates are multiples of 64, so every edge falls on a pixel at 16 px.
    cg.setFillColor(rgb(0xF4, 0xF4, 0xFA))
    for pane in [CGRect(x: 192, y: 192, width: 256, height: 640), CGRect(x: 576, y: 192, width: 256, height: 640)] {
        cg.addPath(CGPath(roundedRect: pane, cornerWidth: 64, cornerHeight: 64, transform: nil))
    }
    cg.fillPath()
    let bars: [(CGRect, CGColor)] = [
        (CGRect(x: 256, y: 640, width: 128, height: 64), rgb(0xF2, 0x5C, 0x5C)),
        (CGRect(x: 256, y: 384, width: 128, height: 64), rgb(0xA9, 0xB0, 0xC0)),
        (CGRect(x: 640, y: 640, width: 128, height: 64), rgb(0xA9, 0xB0, 0xC0)),
        (CGRect(x: 640, y: 384, width: 128, height: 64), rgb(0x4C, 0xC4, 0x62)),
    ]
    for (rect, color) in bars {
        cg.setFillColor(color)
        cg.addPath(CGPath(roundedRect: rect, cornerWidth: 32, cornerHeight: 32, transform: nil))
        cg.fillPath()
    }
}

func rgb(_ r: Int, _ g: Int, _ b: Int) -> CGColor {
    CGColor(srgbRed: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: 1)
}

var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        try render(pixels: points * scale).write(to: outDir.appendingPathComponent(name))
        images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: outDir.appendingPathComponent("Contents.json"))
print("wrote \(outDir.path)")
