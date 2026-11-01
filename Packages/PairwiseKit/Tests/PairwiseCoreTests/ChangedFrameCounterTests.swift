import PairwiseCore
import Testing

@Suite struct ChangedFrameCounterTests {
    @Test func aFirstFrameIsNoChange() {
        var counter = ChangedFrameCounter()
        counter.note(1)
        #expect(counter.changes == 0)
    }

    @Test func theSameFrameAgainIsNoChange() {
        var counter = ChangedFrameCounter()
        counter.note(1)
        counter.note(1)
        #expect(counter.changes == 0)
    }

    @Test func eachDifferentFrameCounts() {
        var counter = ChangedFrameCounter()
        counter.note(1)
        counter.note(2)
        counter.note(3)
        counter.note(3)
        #expect(counter.changes == 2)
    }

    @Test func aFrameWithoutAPixelIsSkipped() {
        var counter = ChangedFrameCounter()
        counter.note(1)
        counter.note(nil)
        counter.note(1)
        #expect(counter.changes == 0)
    }
}
