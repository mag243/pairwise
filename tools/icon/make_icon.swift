// Draws the app icon and writes the PNGs of Apps/PairwiseMac's AppIcon.
// Run from the repository root: swift tools/icon/make_icon.swift
//
// The icon is drawn on a grid of 100 units with y growing downwards: two halves of a
// window with a title bar, hooked together by a dovetail, with the seam between them
// in amber.
import CoreGraphics
import Foundation
import ImageIO

let outputDirectory = "Apps/PairwiseMac/Resources/Assets.xcassets/AppIcon.appiconset"
let pixelSizes = [16, 32, 64, 128, 256, 512, 1024]
let gridUnits = 100.0
/// macOS icons leave a margin around the tile: 824 of 1024 pixels.
let tileShare = 824.0 / 1024.0
let tileCornerRadius = 22.5
let seamWidth = 3.2

func color(_ hex: UInt32) -> CGColor {
    CGColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

func polygon(_ points: [(Double, Double)]) -> CGPath {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: points[0].0, y: points[0].1))
    for point in points.dropFirst() {
        path.addLine(to: CGPoint(x: point.0, y: point.1))
    }
    path.closeSubpath()
    return path
}

func draw(_ path: CGPath, in context: CGContext, hex: UInt32) {
    context.addPath(path)
    context.setFillColor(color(hex))
    context.fillPath()
}

func drawIcon(in context: CGContext, pixelSize: Int) {
    let size = Double(pixelSize)
    let scale = size * tileShare / gridUnits
    let margin = size * (1 - tileShare) / 2
    context.translateBy(x: margin, y: size - margin)
    context.scaleBy(x: scale, y: -scale)

    let tile = CGPath(
        roundedRect: CGRect(x: 0, y: 0, width: gridUnits, height: gridUnits),
        cornerWidth: tileCornerRadius, cornerHeight: tileCornerRadius, transform: nil)
    context.saveGState()
    context.addPath(tile)
    context.clip()
    let colors = [color(0x454C57), color(0x1E2227)] as CFArray
    if let gradient = CGGradient(colorsSpace: nil, colors: colors, locations: [0, 1]) {
        context.drawLinearGradient(
            gradient, start: .zero, end: CGPoint(x: 0, y: gridUnits), options: [])
    }
    context.restoreGState()

    context.saveGState()
    let window = CGPath(
        roundedRect: CGRect(x: 20, y: 22, width: 60, height: 56),
        cornerWidth: 6, cornerHeight: 6, transform: nil)
    context.addPath(window)
    context.clip()
    draw(polygon([(20, 36), (50, 36), (50, 44), (61, 39), (61, 61), (50, 56), (50, 78), (20, 78)]), in: context, hex: 0xFFFFFF)
    draw(polygon([(53, 36), (80, 36), (80, 78), (53, 78), (53, 58), (64, 63), (64, 37), (53, 42)]), in: context, hex: 0xA7B1BF)
    draw(polygon([(20, 22), (50, 22), (50, 34), (20, 34)]), in: context, hex: 0xC5CCD6)
    draw(polygon([(53, 22), (80, 22), (80, 34), (53, 34)]), in: context, hex: 0x747E8C)
    context.restoreGState()

    // The seam stays at least one pixel wide, or it disappears at the small sizes.
    let seam = CGMutablePath()
    seam.move(to: CGPoint(x: 51.5, y: 22))
    seam.addLine(to: CGPoint(x: 51.5, y: 43))
    seam.addLine(to: CGPoint(x: 62.5, y: 38))
    seam.addLine(to: CGPoint(x: 62.5, y: 62))
    seam.addLine(to: CGPoint(x: 51.5, y: 57))
    seam.addLine(to: CGPoint(x: 51.5, y: 78))
    context.addPath(seam)
    context.setStrokeColor(color(0xF5A623))
    context.setLineWidth(max(seamWidth, 1 / scale))
    context.setLineJoin(.round)
    context.strokePath()
}

func writeIcon(pixelSize: Int) throws {
    let space = CGColorSpace(name: CGColorSpace.sRGB)!
    guard
        let context = CGContext(
            data: nil, width: pixelSize, height: pixelSize, bitsPerComponent: 8, bytesPerRow: 0,
            space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { throw CocoaError(.fileWriteUnknown) }
    drawIcon(in: context, pixelSize: pixelSize)
    let url = URL(fileURLWithPath: "\(outputDirectory)/icon_\(pixelSize).png")
    guard
        let image = context.makeImage(),
        let destination = CGImageDestinationCreateWithURL(
            url as CFURL, "public.png" as CFString, 1, nil)
    else { throw CocoaError(.fileWriteUnknown) }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else { throw CocoaError(.fileWriteUnknown) }
}

try FileManager.default.createDirectory(
    atPath: outputDirectory, withIntermediateDirectories: true)
for pixelSize in pixelSizes {
    try writeIcon(pixelSize: pixelSize)
}
