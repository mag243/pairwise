import PairwiseCore
import Testing

@Suite struct ScreenGeometryTests {
    @Test func distanceIsStraightLine() {
        #expect(ScreenPoint(x: 1, y: 1).distance(to: ScreenPoint(x: 4, y: 5)) == 5)
    }

    @Test func maxXIsTheRightEdge() {
        #expect(WindowFrame(x: 100, y: 0, width: 400, height: 300).maxX == 500)
    }
}

@Suite struct WindowFrameContainsTests {
    private static let frame = WindowFrame(x: 10, y: 20, width: 100, height: 50)

    @Test(arguments: [
        (ScreenPoint(x: 50, y: 40), true),
        (ScreenPoint(x: 10, y: 20), true),
        (ScreenPoint(x: 110, y: 70), true),
        (ScreenPoint(x: 9, y: 40), false),
        (ScreenPoint(x: 111, y: 40), false),
        (ScreenPoint(x: 50, y: 19), false),
        (ScreenPoint(x: 50, y: 71), false),
    ])
    func aPointIsOnTheWindowUpToItsEdges(point: ScreenPoint, expected: Bool) {
        #expect(Self.frame.contains(point) == expected)
    }
}
