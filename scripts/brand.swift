// Usage: swift scripts/brand.swift
// Writes the App Icon set from Design/icon-artwork.png and the logos from Design/mark.png.
// Sizes of 32 px and less use a simplified vector drawing, because the artwork blurs at that size.
import AppKit
import SwiftUI

let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let iconSet = root.appending(path: "App/Resources/Assets.xcassets/AppIcon.appiconset")
let design = root.appending(path: "Design")
let artwork = NSImage(contentsOf: design.appending(path: "icon-artwork.png"))!
let markArt = NSImage(contentsOf: design.appending(path: "mark.png"))!
try FileManager.default.createDirectory(at: iconSet, withIntermediateDirectories: true)

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        srgbRed: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255, alpha: alpha
    )
}

func gradient(_ stops: [(UInt32, CGFloat)]) -> CGGradient {
    CGGradient(
        colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: stops.map { rgb($0.0) } as CFArray,
        locations: stops.map(\.1)
    )!
}

func bitmap(pixels: Int, draw: (CGContext) -> Void) -> CGImage {
    let cg = CGContext(
        data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )!
    cg.interpolationQuality = .high
    NSGraphicsContext.current = NSGraphicsContext(cgContext: cg, flipped: false)
    draw(cg)
    NSGraphicsContext.current = nil
    return cg.makeImage()!
}

func writePNG(_ image: CGImage, _ url: URL) throws {
    try NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])!.write(to: url)
}

/// A yuzu slice in two halves, like the two sides of a split diff, simplified for 16 and 32 px.
func drawSmallMark(_ cg: CGContext, radius r: CGFloat, pixels: CGFloat) {
    let gap = max(r * 0.1, r / pixels * 1.2)
    let segments = pixels >= 8 ? 6 : 0
    let rind = gradient([(0xFFE870, 0), (0xFAC71E, 0.6), (0xE39E00, 1)])
    for side in [-1.0, 1.0] as [CGFloat] {
        cg.saveGState()
        cg.translateBy(x: 512 + side * gap / 2, y: 512)
        cg.clip(to: CGRect(x: side < 0 ? -r : 0, y: -r, width: r, height: r * 2))
        cg.addEllipse(in: CGRect(x: -r, y: -r, width: r * 2, height: r * 2))
        cg.clip()
        cg.drawRadialGradient(
            rind, startCenter: CGPoint(x: -r * 0.35, y: r * 0.4), startRadius: 0, endCenter: .zero, endRadius: r,
            options: .drawsAfterEndLocation
        )
        let pith = r * 0.84
        cg.setFillColor(rgb(0xFFF5D6))
        cg.fillEllipse(in: CGRect(x: -pith, y: -pith, width: pith * 2, height: pith * 2))
        let flesh = r * 0.76
        cg.setFillColor(rgb(0xFFCF3A))
        cg.fillEllipse(in: CGRect(x: -flesh, y: -flesh, width: flesh * 2, height: flesh * 2))
        if segments > 0 {
            cg.setStrokeColor(rgb(0xFFF5D6))
            cg.setLineWidth(r * 0.1)
            for i in 0..<segments {
                let angle = CGFloat.pi / 2 + CGFloat(i) * 2 * .pi / CGFloat(segments)
                cg.move(to: .zero)
                cg.addLine(to: CGPoint(x: flesh * cos(angle), y: flesh * sin(angle)))
            }
            cg.strokePath()
        }
        cg.restoreGState()
    }
}

/// The App Icon on the macOS grid: an 824 pt body with 185.4 pt continuous corners on a 1024 pt canvas.
func appIcon(pixels: Int) -> CGImage {
    bitmap(pixels: pixels) { cg in
        let scale = CGFloat(pixels) / 1024
        cg.scaleBy(x: scale, y: scale)
        let body = CGRect(x: 100, y: 100, width: 824, height: 824)
        let mask = RoundedRectangle(cornerRadius: 185.4, style: .continuous).path(in: body).cgPath

        cg.saveGState()
        cg.setShadow(offset: CGSize(width: 0, height: -10), blur: 20, color: rgb(0x000000, 0.3))
        cg.addPath(mask)
        cg.setFillColor(rgb(0x000000))
        cg.fillPath()
        cg.restoreGState()

        cg.saveGState()
        cg.addPath(mask)
        cg.clip()
        if pixels <= 32 {
            cg.drawLinearGradient(
                gradient([(0x2A8A4A, 0), (0x0E4A2A, 1)]), start: CGPoint(x: 100, y: 924), end: CGPoint(x: 924, y: 100),
                options: []
            )
            drawSmallMark(cg, radius: 340, pixels: 340 * scale)
        } else {
            artwork.draw(in: body, from: .zero, operation: .sourceOver, fraction: 1)
        }
        cg.restoreGState()
    }
}

var images: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        try writePNG(appIcon(pixels: points * scale), iconSet.appending(path: name))
        images.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": images, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    .write(to: iconSet.appending(path: "Contents.json"))

struct Lockup: View {
    let dark: Bool

    var body: some View {
        HStack(spacing: 24) {
            Image(nsImage: markArt).resizable().frame(width: 170, height: 170)
            Text("Yuzu")
                .font(.system(size: 140, weight: .bold, design: .rounded))
                .foregroundStyle(dark ? Color.white : Color(cgColor: rgb(0x14361F)))
        }
        .padding(.vertical, 12)
        .padding(.trailing, 24)
    }
}

struct SocialPreview: View {
    let icon: CGImage

    var body: some View {
        HStack(spacing: 48) {
            Image(decorative: icon, scale: 1).resizable().frame(width: 360, height: 360)
            VStack(alignment: .leading, spacing: 12) {
                Text("Yuzu").font(.system(size: 136, weight: .bold, design: .rounded))
                Text("Review large GitHub pull requests\nin a native macOS app.")
                    .font(.system(size: 40, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .foregroundStyle(.white)
        }
        .frame(width: 1280, height: 640)
        .background(
            LinearGradient(
                colors: [Color(cgColor: rgb(0x14361F)), Color(cgColor: rgb(0x0A2415))], startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

try MainActor.assumeIsolated {
    for dark in [false, true] {
        let renderer = ImageRenderer(content: Lockup(dark: dark))
        renderer.scale = 2
        try writePNG(renderer.cgImage!, design.appending(path: dark ? "logo-dark.png" : "logo-light.png"))
    }
    let social = ImageRenderer(content: SocialPreview(icon: appIcon(pixels: 720)))
    try writePNG(social.cgImage!, design.appending(path: "social-preview.png"))
}
print("wrote \(iconSet.path) and the logos in \(design.path)")
