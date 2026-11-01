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
