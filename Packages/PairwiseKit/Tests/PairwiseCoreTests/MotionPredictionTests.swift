import PairwiseCore
import Testing

@Suite struct MotionPredictionTests {
    private static let frame = 1.0 / 60
    private static let lookAhead = 0.016

    /// Runs frames of a drag at `speed` points a second to the right, from x = 0, and
    /// returns the last place with the window's place then.
    private func drag(
        _ motion: inout MotionPrediction, frames: Int, speed: Double, from start: Int = 0
    ) -> (place: ScreenPoint, window: Double) {
        var place = ScreenPoint(x: 0, y: 0)
        var window = 0.0
        for index in start..<(start + frames) {
            let time = Double(index) * Self.frame
            window = speed * time
            place = motion.place(
                forWindowAt: ScreenPoint(x: window, y: 0),
                pointer: ScreenPoint(x: window, y: 0), at: time, lookingAhead: Self.lookAhead)
        }
        return (place, window)
    }

    @Test func theFirstFrameGivesTheWindowsPlace() {
        var motion = MotionPrediction()
        let place = motion.place(
            forWindowAt: ScreenPoint(x: 50, y: 60), pointer: ScreenPoint(x: 5, y: 5), at: 1,
            lookingAhead: Self.lookAhead)
        #expect(place == ScreenPoint(x: 50, y: 60))
    }

    @Test func aSteadyDragEndsUpAheadOfTheWindowByTheLookAhead() {
        var motion = MotionPrediction()
        let result = drag(&motion, frames: 120, speed: 600)
        #expect(abs(result.place.x - (result.window + 600 * Self.lookAhead)) < 0.5)
        #expect(abs(result.place.y) < 0.001)
    }

    @Test func aPointerAtRestSettlesExactlyOnTheWindow() {
        var motion = MotionPrediction()
        let result = drag(&motion, frames: 60, speed: 600)
        let rest = ScreenPoint(x: result.window, y: 0)
        var place = result.place
        for index in 60..<180 {
            place = motion.place(
                forWindowAt: rest, pointer: rest, at: Double(index) * Self.frame,
                lookingAhead: Self.lookAhead)
        }
        #expect(place == rest)
    }

    @Test func aWindowThatHangsLeavesThePlaceWithinReach() {
        var motion = MotionPrediction()
        let window = ScreenPoint(x: 100, y: 0)
        var place = window
        for index in 0..<120 {
            let time = Double(index) * Self.frame
            place = motion.place(
                forWindowAt: window, pointer: ScreenPoint(x: 100 + 1000 * time, y: 0), at: time,
                lookingAhead: Self.lookAhead)
        }
        let spot = 100 + 1000 * Self.lookAhead
        #expect(abs(place.x - spot) <= MotionPrediction.reach + 1)
    }

    @Test func movementToTheLeftLooksAheadToTheLeft() {
        var motion = MotionPrediction()
        let result = drag(&motion, frames: 120, speed: -600)
        #expect(result.place.x < result.window)
    }

    @Test func twoFramesAtOneTimeDoNotBreakTheSpeed() {
        var motion = MotionPrediction()
        let window = ScreenPoint(x: 10, y: 10)
        _ = motion.place(forWindowAt: window, pointer: window, at: 1, lookingAhead: 0)
        let place = motion.place(
            forWindowAt: window, pointer: ScreenPoint(x: 90, y: 90), at: 1, lookingAhead: 0)
        #expect(place == window)
    }
}
