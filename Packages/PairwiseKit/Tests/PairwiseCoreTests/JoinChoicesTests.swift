import PairwiseCore
import Testing

@Suite struct JoinChoicesTests {
    /// A window of 300 wide from x 500 to 800, and y 100 to 500.
    private static let other = ScreenWindow(
        number: 3, frame: WindowFrame(x: 500, y: 100, width: 300, height: 400))
    private static let pointer = ScreenPoint(x: 900, y: 200)

    /// A dragged window with its left edge at `x`.
    private func frame(x: Double, width: Double = 200) -> WindowFrame {
        WindowFrame(x: x, y: 150, width: width, height: 200)
    }

    private func places(
        _ frame: WindowFrame, heading: MoveDirection? = .left,
        pointer: ScreenPoint = Self.pointer, among windows: [ScreenWindow] = [Self.other],
        except excluded: Set<UInt32> = []
    ) -> [JoinPlace?] {
        JoinRule.choices(for: frame, pointer: pointer, among: windows, heading: heading) {
            !excluded.contains($0.number)
        }
    }

    private func numbers(
        _ frame: WindowFrame, heading: MoveDirection? = .left,
        pointer: ScreenPoint = Self.pointer, among windows: [ScreenWindow],
        except excluded: Set<UInt32> = []
    ) -> [UInt32?] {
        places(frame, heading: heading, pointer: pointer, among: windows, except: excluded)
            .map { $0?.other.number }
    }

    @Test func withoutADirectionThereAreNoChoices() {
        #expect(places(frame(x: 810), heading: nil).isEmpty)
    }

    @Test func movingLeftTheLeftEdgeJoinsTheOthersRightEdge() {
        #expect(places(frame(x: 810)).map { $0?.side } == [.right])
    }

    @Test func movingRightTheRightEdgeJoinsTheOthersLeftEdge() {
        #expect(places(frame(x: 290), heading: .right).map { $0?.side } == [.left])
    }

    @Test func movingRightAWindowOnTheLeftIsNoChoice() {
        #expect(places(frame(x: 810), heading: .right).isEmpty)
    }

    @Test func movingLeftAWindowOnTheRightIsNoChoice() {
        #expect(places(frame(x: 290)).isEmpty)
    }

    @Test(arguments: [
        (824.0, true), (825.0, false),  // ahead of the moving edge
        (752.0, true), (751.0, false),  // past it
    ])
    func theMovingEdgeHasLimits(x: Double, counts: Bool) {
        #expect(places(frame(x: x)).isEmpty != counts)
    }

    @Test(arguments: [(276.0, true), (275.0, false), (348.0, true), (349.0, false)])
    func theLimitsHoldMovingRightToo(x: Double, counts: Bool) {
        #expect(places(frame(x: x), heading: .right).isEmpty != counts)
    }

    @Test func aWindowDraggedAwayFromAnOverlapIsNoChoice() {
        #expect(places(frame(x: 650), heading: .right).isEmpty)
    }

    @Test func aWindowInTheMiddleOfAnotherIsNoChoice() {
        #expect(places(frame(x: 600)).isEmpty)
        #expect(places(frame(x: 600), heading: .right).isEmpty)
    }

    @Test func aWindowThatDoesNotOverlapVerticallyIsNoChoice() {
        let above = WindowFrame(x: 810, y: -150, width: 200, height: 200)
        #expect(places(above).isEmpty)
    }

    @Test func thePointerOverAWindowDoesNotMakeItAChoice() {
        #expect(places(frame(x: 900), pointer: ScreenPoint(x: 700, y: 200)).isEmpty)
    }

    // The window `other` has its right edge at 800; this one covers that over all of its height,
    // with its own right edge further than the moving edge may have passed.
    private static let cover = ScreenWindow(
        number: 4, frame: WindowFrame(x: 400, y: 50, width: 470, height: 600))

    @Test func aHiddenEdgeComesAfterNoWindow() {
        #expect(numbers(frame(x: 810), among: [Self.cover, Self.other]) == [nil, 3])
    }

    @Test func aHiddenEdgeIsNoTargetByItself() {
        let found = JoinRule.target(
            for: frame(x: 810), pointer: Self.pointer, among: [Self.cover, Self.other],
            takingHeight: false, heading: .left)
        #expect(found == nil)
    }

    @Test func aVisibleEdgeComesBeforeACloserHiddenOne() {
        let visible = ScreenWindow(
            number: 5, frame: WindowFrame(x: 500, y: 100, width: 320, height: 400))
        #expect(
            numbers(frame(x: 803), among: [visible, Self.cover, Self.other]) == [5, 3])
    }

    @Test func aWindowInFrontThatMayNotJoinHidesAnEdge() {
        #expect(numbers(frame(x: 810), among: [Self.cover, Self.other], except: [4]) == [nil, 3])
    }

    @Test func anEdgeThatMayNotJoinIsNoChoice() {
        #expect(places(frame(x: 810), except: [3]).isEmpty)
    }

    @Test func anEdgeCoveredOnlyOutsideTheDraggedHeightIsVisible() {
        let above = ScreenWindow(
            number: 4, frame: WindowFrame(x: 400, y: 0, width: 470, height: 120))
        #expect(numbers(frame(x: 810), among: [above, Self.other]) == [3])
    }

    @Test(arguments: [(19.0, false), (20.0, true)])
    func anEdgeHasToShowEnough(visible: Double, counts: Bool) {
        // The dragged window spans y 150 to 350; the cover leaves `visible` points at the bottom.
        let partly = ScreenWindow(
            number: 4, frame: WindowFrame(x: 400, y: 100, width: 470, height: 250 - visible))
        let found = numbers(frame(x: 810), among: [partly, Self.other])
        #expect(found == (counts ? [3] : [nil, 3]))
    }

    @Test func twoCoversTogetherHideAnEdgeThatNeitherHidesAlone() {
        let upper = ScreenWindow(
            number: 4, frame: WindowFrame(x: 400, y: 100, width: 470, height: 150))
        let lower = ScreenWindow(
            number: 6, frame: WindowFrame(x: 400, y: 240, width: 470, height: 150))
        #expect(numbers(frame(x: 810), among: [upper, lower, Self.other]) == [nil, 3])
    }

    @Test func aWindowBehindDoesNotHideAnEdge() {
        #expect(numbers(frame(x: 810), among: [Self.other, Self.cover]).first == 3)
    }

    @Test func theDraggedWindowsOwnPlaceHidesNothing() {
        #expect(numbers(frame(x: 700, width: 900), among: [Self.other]).isEmpty)
        #expect(numbers(frame(x: 795, width: 900), among: [Self.other]) == [3])
    }

    private static let near = ScreenWindow(
        number: 5, frame: WindowFrame(x: 505, y: 100, width: 300, height: 400))

    @Test func theSmallestDistanceComesFirst() {
        #expect(numbers(frame(x: 810), among: [Self.other, Self.near]) == [5, 3])
    }

    @Test func aWindowHoldingThePointerComesBeforeACloserOne() {
        let low = ScreenWindow(
            number: 5, frame: WindowFrame(x: 505, y: 300, width: 300, height: 200))
        let high = ScreenWindow(
            number: 6, frame: WindowFrame(x: 500, y: 100, width: 300, height: 190))
        #expect(
            numbers(frame(x: 810), pointer: ScreenPoint(x: 900, y: 150), among: [low, high])
                == [6, 5])
    }

    @Test func atTheSameDistanceTheFrontmostWindowComesFirst() {
        let same = ScreenWindow(
            number: 5, frame: WindowFrame(x: 600, y: 100, width: 200, height: 400))
        #expect(numbers(frame(x: 810), among: [same, Self.other]) == [5, 3])
        #expect(numbers(frame(x: 810), among: [Self.other, same]) == [3, 5])
    }

    @Test func theFirstChoiceGivesTheFrameOfTheTarget() {
        let found = JoinRule.target(
            for: frame(x: 810), pointer: Self.pointer, among: [Self.other], takingHeight: false,
            heading: .left)
        #expect(found?.frame == WindowFrame(x: 800, y: 100, width: 200, height: 200))
    }

    @Test func aChoiceCanTakeTheOthersHeight() {
        let place = JoinPlace(other: Self.other, side: .right)
        let found = JoinRule.target(at: place, for: frame(x: 810), takingHeight: true)
        #expect(found.frame == WindowFrame(x: 800, y: 100, width: 200, height: 400))
    }
}
