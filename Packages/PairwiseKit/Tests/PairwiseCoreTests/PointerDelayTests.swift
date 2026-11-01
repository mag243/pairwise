import PairwiseCore
import Testing

@Suite struct PointerDelayTests {
    private static let first = ScreenPoint(x: 10, y: 0)
    private static let second = ScreenPoint(x: 20, y: 0)
    private static let third = ScreenPoint(x: 30, y: 0)

    @Test func noDelayGivesThePointerNow() {
        var delay = PointerDelay()
        _ = delay.place(of: Self.first, at: 0, holdingBack: 0)
        let place = delay.place(of: Self.second, at: 0.01, holdingBack: 0)
        #expect(place == Self.second)
    }

    @Test func aDelayGivesWhereThePointerWasThatLongAgo() {
        var delay = PointerDelay()
        _ = delay.place(of: Self.first, at: 0, holdingBack: 0.016)
        _ = delay.place(of: Self.second, at: 0.01, holdingBack: 0.016)
        let place = delay.place(of: Self.third, at: 0.02, holdingBack: 0.016)
        #expect(place == Self.first)
    }

    @Test func aNewerPlaceTakesOverOnceItIsOldEnough() {
        var delay = PointerDelay()
        _ = delay.place(of: Self.first, at: 0, holdingBack: 0.016)
        _ = delay.place(of: Self.second, at: 0.01, holdingBack: 0.016)
        let place = delay.place(of: Self.third, at: 0.03, holdingBack: 0.016)
        #expect(place == Self.second)
    }

    @Test func withoutEnoughHistoryTheOldestPlaceIsGiven() {
        var delay = PointerDelay()
        _ = delay.place(of: Self.first, at: 0, holdingBack: 0.016)
        let place = delay.place(of: Self.second, at: 0.001, holdingBack: 0.016)
        #expect(place == Self.first)
    }

    @Test func aPointerAtRestIsReached() {
        var delay = PointerDelay()
        _ = delay.place(of: Self.first, at: 0, holdingBack: 0.016)
        _ = delay.place(of: Self.second, at: 0.01, holdingBack: 0.016)
        let place = delay.place(of: Self.second, at: 0.5, holdingBack: 0.016)
        #expect(place == Self.second)
    }
}
