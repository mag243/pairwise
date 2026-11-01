import PairwiseCore
import Testing

@Suite struct PartnerPlacementTests {
    @Test func partnerSitsAgainstTheRightEdgeWithItsTopLevel() {
        let origin = PartnerPlacement.origin(
            besideWindowAt: ScreenPoint(x: 100, y: 50), size: WindowSize(width: 400, height: 300))
        #expect(origin == ScreenPoint(x: 500, y: 50))
    }
}
