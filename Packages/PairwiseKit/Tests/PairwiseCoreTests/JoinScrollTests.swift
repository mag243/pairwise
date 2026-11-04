import PairwiseCore
import Testing

@Suite struct JoinScrollTests {
    @Test(arguments: [(-1, 1), (-5, 1), (1, -1), (7, -1), (0, 0)])
    func aWheelsEventIsOneStep(lines: Int, steps: Int) {
        var scroll = JoinScroll()
        #expect(scroll.steps(forWheelLines: lines) == steps)
    }

    @Test func aTrackpadsMovementIsCollected() {
        var scroll = JoinScroll()
        #expect(scroll.steps(forTrackpadPoints: -30) == 0)
        #expect(scroll.steps(forTrackpadPoints: -10) == 1)
        #expect(scroll.steps(forTrackpadPoints: -39) == 0)
    }

    @Test func aLongTrackpadMovementIsSeveralSteps() {
        var scroll = JoinScroll()
        #expect(scroll.steps(forTrackpadPoints: -85) == 2)
    }

    @Test func theOtherWayCountsBack() {
        var scroll = JoinScroll()
        #expect(scroll.steps(forTrackpadPoints: 40) == -1)
    }

    @Test func turningBackUsesUpWhatWasCollected() {
        var scroll = JoinScroll()
        _ = scroll.steps(forTrackpadPoints: -30)
        #expect(scroll.steps(forTrackpadPoints: 30) == 0)
        #expect(scroll.steps(forTrackpadPoints: 39) == 0)
    }
}
