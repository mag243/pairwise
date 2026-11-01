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

    @Test func noPicturesTakeNoRoom() {
        #expect(StandInPanel.layout(of: []).size == .zero)
    }
}
