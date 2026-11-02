import AppKit
import Testing

@testable import PairwiseWindowSystem

@MainActor
@Suite struct PlaceholderPictureTests {
    private static let size = CGSize(width: 300, height: 200)
    private static let scale: CGFloat = 2

    private func picture(isDark: Bool) throws -> StandInPanel.Picture {
        try #require(
            PlaceholderPicture.make(
                title: "A window", icon: nil, size: Self.size, scale: Self.scale, isDark: isDark))
    }

    /// The red, green, blue and alpha of a pixel, counted from the top left.
    private func pixel(_ image: CGImage, x: Int, y: Int) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: 4)
        let space = try #require(CGColorSpace(name: CGColorSpace.sRGB))
        let context = try #require(
            CGContext(
                data: &bytes, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
                space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(
            image,
            in: CGRect(
                x: -x, y: y - image.height + 1, width: image.width, height: image.height))
        return bytes
    }

    @Test func hasTheWindowsSizeInPointsAndPixels() throws {
        let result = try picture(isDark: true)
        #expect(result.size == Self.size)
        #expect(result.image.width == 600)
        #expect(result.image.height == 400)
    }

    @Test func aDarkPlaneIsDarkerThanALightOne() throws {
        let dark = try pixel(picture(isDark: true).image, x: 300, y: 300)
        let light = try pixel(picture(isDark: false).image, x: 300, y: 300)
        #expect(dark[0] < light[0])
    }

    @Test func theTitleBarDiffersFromThePlane() throws {
        let image = try picture(isDark: true).image
        let bar = try pixel(image, x: 590, y: 20)
        let plane = try pixel(image, x: 590, y: 300)
        #expect(bar != plane)
    }

    @Test func theCornersAreRound() throws {
        let image = try picture(isDark: true).image
        #expect(try pixel(image, x: 0, y: 0)[3] == 0)
        #expect(try pixel(image, x: 300, y: 300)[3] == 255)
    }

    @Test func theTitleBarHoldsAWindowsThreeButtons() throws {
        let image = try picture(isDark: true).image
        let row = 28
        let close = try pixel(image, x: 28, y: row)
        let minimize = try pixel(image, x: 68, y: row)
        let zoom = try pixel(image, x: 108, y: row)
        #expect(close[0] > close[1] && close[0] > close[2])
        #expect(minimize[0] > minimize[2] && minimize[1] > minimize[2])
        #expect(zoom[1] > zoom[0] && zoom[1] > zoom[2])
    }

    private func solidIcon() -> NSImage {
        NSImage(size: CGSize(width: 8, height: 8), flipped: false) { rect in
            NSColor.systemBlue.setFill()
            rect.fill()
            return true
        }
    }

    @Test func thePlaneShowsTheAppsIconInItsMiddle() throws {
        let image = try #require(
            PlaceholderPicture.make(
                title: "", icon: solidIcon(), size: Self.size, scale: Self.scale, isDark: true)
        ).image
        let middle = try pixel(image, x: 300, y: 228)
        let beside = try pixel(image, x: 30, y: 228)
        #expect(middle != beside)
    }

    @Test func aWindowTooSmallForTheIconShowsOnlyThePlane() throws {
        let small = CGSize(width: 300, height: 60)
        let image = try #require(
            PlaceholderPicture.make(
                title: "", icon: solidIcon(), size: small, scale: Self.scale, isDark: true)
        ).image
        let middle = try pixel(image, x: 300, y: 90)
        let beside = try pixel(image, x: 30, y: 90)
        #expect(middle == beside)
    }

    @Test func atASeamLayersTakeOverAtTheNewWidths() throws {
        let first = try picture(isDark: true)
        let second = try picture(isDark: true)
        let layers = [first, second].map { _ in
            PlaceholderLayers(title: "A window", icon: nil, scale: Self.scale, isDark: true)
        }
        let panel = StandInPanel(pictures: [first, second], streams: [], placeholders: layers)
        panel.setSeam(atOffset: 200)
        #expect(layers[0].root.frame.size == CGSize(width: 200, height: 200))
        #expect(layers[1].root.frame.size == CGSize(width: 400, height: 200))
        #expect(panel.images[0].isHidden)
        #expect(panel.parts.isEmpty)
        panel.dismiss()
    }

    @Test func aNarrowWindowKeepsItsButtonsAndLosesItsTitlesRoom() {
        let places = PlaceholderPicture.places(for: CGSize(width: 80, height: 200))
        #expect(places.title.width == 0)
        #expect(places.buttons.count == 3)
        #expect(places.bodyIcon == nil)
    }

    @Test func aWindowWithoutSizeIsNoPicture() {
        #expect(
            PlaceholderPicture.make(
                title: "", icon: nil, size: .zero, scale: Self.scale, isDark: true) == nil)
    }
}
