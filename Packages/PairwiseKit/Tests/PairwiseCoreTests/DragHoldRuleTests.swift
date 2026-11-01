import PairwiseCore
import Testing

@Suite struct DragHoldRuleTests {
    private static let frame = WindowFrame(x: 100, y: 100, width: 400, height: 300)

    @Test(arguments: [
        (ScreenPoint(x: 150, y: 110), true),
        (ScreenPoint(x: 100, y: 100), true),
        (ScreenPoint(x: 500, y: 152), true),
        (ScreenPoint(x: 150, y: 153), false),
        (ScreenPoint(x: 99, y: 110), false),
        (ScreenPoint(x: 501, y: 110), false),
        (ScreenPoint(x: 150, y: 99), false),
    ])
    func onlyTheTopBandCounts(point: ScreenPoint, expected: Bool) {
        #expect(DragHoldRule.isInTitleBand(point, of: Self.frame) == expected)
    }

    @Test func aDragMayBeHeldForAShortTime() {
        #expect(DragHoldRule.mayHold(after: 4.9))
    }

    @Test func aLongDragIsLetGo() {
        #expect(!DragHoldRule.mayHold(after: 5))
    }
}
