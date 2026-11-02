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

    @Test func atTheSeamOfThePressSlotsAndPicturesAreAsTheyWere() {
        let layout = StandInPanel.seamLayout(of: Self.sizes, seamAt: 100)
        #expect(layout[0].slot == CGRect(x: 0, y: 120, width: 100, height: 80))
        #expect(layout[0].image == CGRect(x: 0, y: 0, width: 100, height: 80))
        #expect(layout[1].slot == CGRect(x: 100, y: 0, width: 50, height: 200))
        #expect(layout[1].image == CGRect(x: 0, y: 0, width: 50, height: 200))
    }

    @Test func aNarrowingLeftPictureIsCutOffAtTheSeam() {
        let layout = StandInPanel.seamLayout(of: Self.sizes, seamAt: 80)
        #expect(layout[0].slot.width == 80)
        #expect(layout[0].image == CGRect(x: 0, y: 0, width: 100, height: 80))
    }

    @Test func aNarrowingRightPictureIsCutOffAtTheSeamAndKeepsItsFarEdge() {
        let layout = StandInPanel.seamLayout(of: Self.sizes, seamAt: 120)
        #expect(layout[1].slot == CGRect(x: 120, y: 0, width: 30, height: 200))
        #expect(layout[1].image == CGRect(x: -20, y: 0, width: 50, height: 200))
    }

    @Test func aWideningPictureFillsItsSlot() {
        let layout = StandInPanel.seamLayout(of: Self.sizes, seamAt: 80)
        #expect(layout[1].slot == CGRect(x: 80, y: 0, width: 70, height: 200))
        #expect(layout[1].image == CGRect(x: 0, y: 0, width: 70, height: 200))
    }

    @Test func theColumnThatStretchesLiesNearTheSeam() {
        let left = StandInPanel.stretchingColumn(ofPictureWidth: 100, isLeft: true)
        let right = StandInPanel.stretchingColumn(ofPictureWidth: 100, isLeft: false)
        #expect(left.minX > 0.5)
        #expect(right.maxX < 0.5)
        #expect(left.height == 1 && right.height == 1)
    }

    @Test func noPicturesTakeNoRoom() {
        #expect(StandInPanel.layout(of: []).size == .zero)
    }
}
