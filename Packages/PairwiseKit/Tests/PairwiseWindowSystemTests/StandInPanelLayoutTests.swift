import AppKit
import CoreGraphics
import Testing

@testable import PairwiseWindowSystem

@MainActor
@Suite struct StandInPanelLayoutTests {
    @Test func picturesGoSideBySideWithTheirTopsLevel() {
        let layout = StandInPanel.layout(of: [
            CGSize(width: 100, height: 80), CGSize(width: 50, height: 200),
        ])
        #expect(layout.size == CGSize(width: 150, height: 200))
        #expect(layout.frames[0] == CGRect(x: 0, y: 120, width: 100, height: 80))
        #expect(layout.frames[1] == CGRect(x: 100, y: 0, width: 50, height: 200))
    }

    private static let sizes = [CGSize(width: 100, height: 80), CGSize(width: 50, height: 200)]
    private static let splits: [CGFloat] = [50, 25]

    @Test func atTheSeamOfThePressThePartsMeetInTheMiddle() {
        let layout = StandInPanel.seamLayout(
            of: Self.sizes, splits: Self.splits, totalWidth: 150, seamAt: 100)
        #expect(layout[0].slot == CGRect(x: 0, y: 120, width: 100, height: 80))
        #expect(layout[0].head == CGRect(x: 0, y: 0, width: 50, height: 80))
        #expect(layout[0].tail == CGRect(x: 50, y: 0, width: 50, height: 80))
        #expect(layout[0].fill.width == 0)
        #expect(layout[1].slot == CGRect(x: 100, y: 0, width: 50, height: 200))
    }

    @Test func aNarrowerPictureLosesItsMiddleAndKeepsBothEdges() {
        let layout = StandInPanel.seamLayout(
            of: Self.sizes, splits: Self.splits, totalWidth: 150, seamAt: 80)
        #expect(layout[0].slot.width == 80)
        #expect(layout[0].head == CGRect(x: 0, y: 0, width: 50, height: 80))
        #expect(layout[0].tail == CGRect(x: 30, y: 0, width: 50, height: 80))
        #expect(layout[0].fill.width == 0)
    }

    @Test func aWiderPictureFillsItsMiddleAndKeepsBothEdges() {
        let layout = StandInPanel.seamLayout(
            of: Self.sizes, splits: Self.splits, totalWidth: 150, seamAt: 80)
        #expect(layout[1].slot == CGRect(x: 80, y: 0, width: 70, height: 200))
        #expect(layout[1].head == CGRect(x: 0, y: 0, width: 25, height: 200))
        #expect(layout[1].fill == CGRect(x: 25, y: 0, width: 20, height: 200))
        #expect(layout[1].tail == CGRect(x: 45, y: 0, width: 25, height: 200))
    }

    @Test func thePartsDivideAtTheSplitWhereverThatIs() {
        let layout = StandInPanel.seamLayout(
            of: Self.sizes, splits: [30, 25], totalWidth: 150, seamAt: 120)
        #expect(layout[0].head == CGRect(x: 0, y: 0, width: 30, height: 80))
        #expect(layout[0].fill == CGRect(x: 30, y: 0, width: 20, height: 80))
        #expect(layout[0].tail == CGRect(x: 50, y: 0, width: 70, height: 80))
    }

    @Test func aLiveFrameFillsItsSlotWithNoDivision() {
        let places = StandInPanel.liveLayout(
            of: Self.sizes, totalWidth: 150, seamAt: 90)
        #expect(places[0].slot == CGRect(x: 0, y: 120, width: 90, height: 80))
        #expect(places[0].frame == CGRect(x: 0, y: 0, width: 90, height: 80))
        #expect(places[1].slot == CGRect(x: 90, y: 0, width: 60, height: 200))
        #expect(places[1].frame == CGRect(x: 0, y: 0, width: 60, height: 200))
    }

    @Test func aFramesPartIsAShareOfItsSurface() {
        let share = StandInPanel.share(
            of: CGRect(x: 0, y: 0, width: 100, height: 50), scale: 2,
            inSurface: CGSize(width: 400, height: 200))
        #expect(share == CGRect(x: 0, y: 0, width: 0.5, height: 0.5))
    }

    @Test func theButtonsPatchTakesTheTopLeftOfTheWindow() {
        let patch = StandInPanel.buttonsPatch(ofPictureSize: CGSize(width: 400, height: 200))
        #expect(patch.frame == CGRect(x: 0, y: 148, width: 92, height: 52))
        #expect(patch.part == CGRect(x: 0, y: 0.74, width: 0.23, height: 0.26))
    }

    @Test func theAmberLineStandsOnTheSeamAlongTheShorterWindow() {
        let line = StandInPanel.seamLine(of: Self.sizes, seamAt: 90)
        #expect(line == CGRect(x: 87, y: 120, width: 6, height: 80))
    }

    private func image(red: CGFloat, alpha: CGFloat) throws -> CGImage {
        let context = try #require(
            CGContext(
                data: nil, width: 4, height: 4, bitsPerComponent: 8, bytesPerRow: 16,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(srgbRed: red, green: 0, blue: 0, alpha: alpha))
        context.fill(CGRect(x: 0, y: 0, width: 4, height: 4))
        return try #require(context.makeImage())
    }

    @Test func theBackingHasThePicturesColourAndIsOpaque() throws {
        let colour = StandInPanel.backingColour(of: try image(red: 1, alpha: 0.5))
        let parts = try #require(colour.components)
        #expect(abs(parts[0] - 1) < 0.1)
        #expect(parts[1] < 0.1)
        #expect(colour.alpha == 1)
    }

    @Test(arguments: ["contents", "contentsRect", "bounds", "position", "hidden", "opacity"])
    func aLayerInThePanelHasItsAnimationsOff(key: String) {
        #expect(StandInPanel.stillLayer().actions?[key] is NSNull)
    }

    @Test func theFillShowsOneColumnAtTheSplit() {
        let column = StandInPanel.fillColumn(ofPictureWidth: 100, atSplit: 30)
        #expect(column == CGRect(x: 0.3, y: 0, width: 0.01, height: 1))
    }

    @Test func noPicturesTakeNoRoom() {
        #expect(StandInPanel.layout(of: []).size == .zero)
    }
}
