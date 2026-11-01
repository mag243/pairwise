import PairwiseCore
import Testing

@Suite struct StillPointerTests {
    private static let here = ScreenPoint(x: 10, y: 10)
    private static let there = ScreenPoint(x: 20, y: 10)

    @Test func aPointerJustSeenIsNotStillYet() {
        var still = StillPointer()
        let settled = still.hasSettled(at: Self.here, time: 0)
        #expect(!settled)
    }

    @Test func aPointerThatStaysPutSettles() {
        var still = StillPointer()
        _ = still.hasSettled(at: Self.here, time: 0)
        let settledNow = still.hasSettled(at: Self.here, time: 0.2)
        #expect(settledNow)
    }

    @Test func tooShortAPauseDoesNotSettle() {
        var still = StillPointer()
        _ = still.hasSettled(at: Self.here, time: 0)
        let settled = still.hasSettled(at: Self.here, time: 0.05)
        #expect(!settled)
    }

    @Test func oneStopSettlesOnce() {
        var still = StillPointer()
        _ = still.hasSettled(at: Self.here, time: 0)
        _ = still.hasSettled(at: Self.here, time: 0.2)
        let settled = still.hasSettled(at: Self.here, time: 0.4)
        #expect(!settled)
    }

    @Test func movingOnStartsAgain() {
        var still = StillPointer()
        _ = still.hasSettled(at: Self.here, time: 0)
        _ = still.hasSettled(at: Self.here, time: 0.2)
        let settled = still.hasSettled(at: Self.there, time: 0.3)
        #expect(!settled)
        let settledNow = still.hasSettled(at: Self.there, time: 0.5)
        #expect(settledNow)
    }
}
