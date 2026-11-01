import PairwiseCore
import Testing

@Suite struct WindowDragRuleTests {
    private static let start = WindowFrame(x: 100, y: 100, width: 400, height: 300)

    @Test(arguments: [
        (WindowFrame(x: 110, y: 100, width: 400, height: 300), true),
        (WindowFrame(x: 100, y: 90, width: 400, height: 300), true),
        (WindowFrame(x: 100, y: 100, width: 400, height: 300), false),
        (WindowFrame(x: 100, y: 100, width: 420, height: 300), false),
        (WindowFrame(x: 90, y: 100, width: 410, height: 300), false),
    ])
    func movedOnlyWhenTheOriginChangesAndTheSizeDoesNot(current: WindowFrame, isMove: Bool) {
        #expect(WindowDragRule.isMove(from: Self.start, to: current) == isMove)
    }
}
