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
        let layout = StandInPanel.seamLayout(of: Self.sizes, splits: Self.splits, seamAt: 100)
        #expect(layout[0].slot == CGRect(x: 0, y: 120, width: 100, height: 80))
        #expect(layout[0].head == CGRect(x: 0, y: 0, width: 50, height: 80))
        #expect(layout[0].tail == CGRect(x: 50, y: 0, width: 50, height: 80))
        #expect(layout[0].fill.width == 0)
        #expect(layout[1].slot == CGRect(x: 100, y: 0, width: 50, height: 200))
    }

    @Test func aNarrowerPictureLosesItsMiddleAndKeepsBothEdges() {
        let layout = StandInPanel.seamLayout(of: Self.sizes, splits: Self.splits, seamAt: 80)
        #expect(layout[0].slot.width == 80)
        #expect(layout[0].head == CGRect(x: 0, y: 0, width: 50, height: 80))
        #expect(layout[0].tail == CGRect(x: 30, y: 0, width: 50, height: 80))
        #expect(layout[0].fill.width == 0)
    }

    @Test func aWiderPictureFillsItsMiddleAndKeepsBothEdges() {
        let layout = StandInPanel.seamLayout(of: Self.sizes, splits: Self.splits, seamAt: 80)
        #expect(layout[1].slot == CGRect(x: 80, y: 0, width: 70, height: 200))
        #expect(layout[1].head == CGRect(x: 0, y: 0, width: 25, height: 200))
        #expect(layout[1].fill == CGRect(x: 25, y: 0, width: 20, height: 200))
        #expect(layout[1].tail == CGRect(x: 45, y: 0, width: 25, height: 200))
    }

    @Test func thePartsDivideAtTheSplitWhereverThatIs() {
        let layout = StandInPanel.seamLayout(of: Self.sizes, splits: [30, 25], seamAt: 120)
        #expect(layout[0].head == CGRect(x: 0, y: 0, width: 30, height: 80))
        #expect(layout[0].fill == CGRect(x: 30, y: 0, width: 20, height: 80))
        #expect(layout[0].tail == CGRect(x: 50, y: 0, width: 70, height: 80))
    }

    @Test func theFillShowsOneColumnAtTheSplit() {
        let column = StandInPanel.fillColumn(ofPictureWidth: 100, atSplit: 30)
        #expect(column == CGRect(x: 0.3, y: 0, width: 0.01, height: 1))
    }

    @Test func noPicturesTakeNoRoom() {
        #expect(StandInPanel.layout(of: []).size == .zero)
    }
}
