import PairwiseCore
import Testing

@Suite struct PairWatchTests {
    private static let frame = WindowFrame(x: 0, y: 0, width: 10, height: 10)
    private static let pair = WindowPair(left: 1, right: 2)

    private func windows(_ numbers: UInt32...) -> [ScreenWindow] {
        numbers.map { ScreenWindow(number: $0, frame: Self.frame) }
    }

    @Test func aFrontWindowWithItsPartnerBehindAnotherBringsThePartner() {
        let raise = PairWatch.partnerToBringForward(
            windows: windows(1, 3, 2), pairs: [Self.pair])
        #expect(raise == PairWatch.Raise(window: 1, partner: 2))
    }

    @Test func aFrontWindowOnTheRightWorksAlike() {
        let raise = PairWatch.partnerToBringForward(
            windows: windows(2, 3, 1), pairs: [Self.pair])
        #expect(raise == PairWatch.Raise(window: 2, partner: 1))
    }

    @Test func aPartnerRightBehindNeedsNothing() {
        let raise = PairWatch.partnerToBringForward(
            windows: windows(1, 2, 3), pairs: [Self.pair])
        #expect(raise == nil)
    }

    @Test func anotherWindowInFrontLeavesThePairAlone() {
        let raise = PairWatch.partnerToBringForward(
            windows: windows(3, 1, 4, 2), pairs: [Self.pair])
        #expect(raise == nil)
    }

    @Test func aPartnerNotOnTheListStaysThere() {
        let raise = PairWatch.partnerToBringForward(
            windows: windows(1, 3), pairs: [Self.pair])
        #expect(raise == nil)
    }

    @Test func noWindowsNeedNothing() {
        #expect(PairWatch.partnerToBringForward(windows: [], pairs: [Self.pair]) == nil)
    }
}
