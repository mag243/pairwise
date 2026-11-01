import PairwiseCore
import Testing

@Suite struct DragHoldRuleTests {
    private static let frame = WindowFrame(x: 100, y: 100, width: 400, height: 300)

    @Test func theSameFrameIsNeitherMoveNorResize() {
        #expect(!DragHoldRule.isMove(from: Self.frame, to: Self.frame))
        #expect(!DragHoldRule.isResize(from: Self.frame, to: Self.frame))
    }

    @Test func aNewOriginWithTheSameSizeIsAMove() {
        let moved = WindowFrame(x: 101, y: 100, width: 400, height: 300)
        #expect(DragHoldRule.isMove(from: Self.frame, to: moved))
        #expect(!DragHoldRule.isResize(from: Self.frame, to: moved))
    }

    @Test func aNewSizeIsAResizeEvenWithANewOrigin() {
        let resized = WindowFrame(x: 90, y: 100, width: 410, height: 300)
        #expect(!DragHoldRule.isMove(from: Self.frame, to: resized))
        #expect(DragHoldRule.isResize(from: Self.frame, to: resized))
    }

    @Test func picturesMayTakeAShortTime() {
        #expect(DragHoldRule.mayWaitForPictures(after: 0.9))
    }

    @Test func picturesThatTakeLongAreNotWaitedFor() {
        #expect(!DragHoldRule.mayWaitForPictures(after: 1))
    }
}
