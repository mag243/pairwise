import PairwiseCore
import Testing

@Suite struct DragGripTests {
    @Test func windowStaysAtTheSameDistanceFromThePointer() {
        let grip = DragGrip(
            pointer: ScreenPoint(x: 150, y: 110), windowOrigin: ScreenPoint(x: 100, y: 100))
        #expect(
            grip.windowOrigin(forPointer: ScreenPoint(x: 250, y: 60)) == ScreenPoint(x: 200, y: 50))
    }

    @Test func pointerAtTheStartGivesTheStartOrigin() {
        let grip = DragGrip(
            pointer: ScreenPoint(x: 150, y: 110), windowOrigin: ScreenPoint(x: 100, y: 100))
        #expect(
            grip.windowOrigin(forPointer: ScreenPoint(x: 150, y: 110))
                == ScreenPoint(x: 100, y: 100))
    }
}
