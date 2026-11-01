import PairwiseCore
import Testing

@Suite struct PartnerPlacementTests {
    @Test func partnerSitsAgainstTheRightEdgeWithItsTopLevel() {
        let origin = PartnerPlacement.origin(
            besideWindowAt: ScreenPoint(x: 100, y: 50), size: WindowSize(width: 400, height: 300))
        #expect(origin == ScreenPoint(x: 500, y: 50))
    }
}

@Suite struct PartnerSidePlacementTests {
    private static let origin = ScreenPoint(x: 100, y: 50)
    private static let size = WindowSize(width: 400, height: 300)
    private static let partnerSize = WindowSize(width: 200, height: 500)

    @Test func aPartnerOnTheRightStartsAtTheWindowsRightEdge() {
        let place = PartnerPlacement.origin(
            besideWindowAt: Self.origin, size: Self.size, partnerSize: Self.partnerSize, on: .right)
        #expect(place == ScreenPoint(x: 500, y: 50))
    }

    @Test func aPartnerOnTheLeftEndsAtTheWindowsLeftEdge() {
        let place = PartnerPlacement.origin(
            besideWindowAt: Self.origin, size: Self.size, partnerSize: Self.partnerSize, on: .left)
        #expect(place == ScreenPoint(x: -100, y: 50))
    }
}
