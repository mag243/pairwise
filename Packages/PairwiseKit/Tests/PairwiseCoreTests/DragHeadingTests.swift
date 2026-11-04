import PairwiseCore
import Testing

@Suite struct DragHeadingTests {
    private func heading(through places: [Double]) -> MoveDirection? {
        var heading = DragHeading(startingAt: 100)
        for place in places { heading.update(x: place) }
        return heading.direction
    }

    @Test func aStillPointerHasNoDirection() {
        #expect(heading(through: [100, 100]) == nil)
    }

    @Test(arguments: [(111.0, nil), (112.0, MoveDirection.right), (89.0, nil), (88.0, .left)])
    func aDirectionTakesEnoughMovement(place: Double, direction: MoveDirection?) {
        #expect(heading(through: [place]) == direction)
    }

    @Test func aDirectionStaysWhileThePointerStandsStill() {
        #expect(heading(through: [150, 150, 150]) == .right)
    }

    @Test func aSmallMoveBackKeepsTheDirection() {
        #expect(heading(through: [150, 139]) == .right)
    }

    @Test func aTurnIsMeasuredFromTheFurthestPlace() {
        #expect(heading(through: [150, 200, 188]) == .left)
    }

    @Test func aTurnLeftCanTurnRightAgain() {
        #expect(heading(through: [150, 130, 142]) == .right)
    }

    @Test func goingOnKeepsMovingTheFurthestPlace() {
        #expect(heading(through: [80, 40, 51]) == .left)
    }
}
