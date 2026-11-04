import PairwiseCore
import Testing

@Suite struct JoinChoicesTests {
    /// A window from x 500 to 800 and y 100 to 500, with a zone of 75 past its edge.
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

    /// The window proposed by itself, if any.
    private func proposed(
        _ frame: WindowFrame, heading: MoveDirection? = .left,
        among windows: [ScreenWindow] = [Self.other]
    ) -> UInt32? {
        numbers(frame, heading: heading, among: windows).first ?? nil
    }

    @Test func withoutADirectionNothingIsProposed() {
        #expect(proposed(frame(x: 810), heading: nil) == nil)
    }

    @Test func movingLeftTheLeftEdgeJoinsTheOthersRightEdge() {
        #expect(places(frame(x: 810)).map { $0?.side } == [.right])
    }

    @Test func movingRightTheRightEdgeJoinsTheOthersLeftEdge() {
        #expect(places(frame(x: 290), heading: .right).map { $0?.side } == [.left])
    }

    @Test func movingRightAWindowOnTheLeftIsNotProposed() {
        #expect(proposed(frame(x: 810), heading: .right) == nil)
    }

    @Test func movingLeftAWindowOnTheRightIsNotProposed() {
        #expect(proposed(frame(x: 290)) == nil)
    }

    @Test(arguments: [
        (824.0, true), (825.0, false),  // ahead of the moving edge
        (725.0, true), (724.0, false),  // past it, by 25% of the other's width
    ])
    func theMovingEdgeHasLimits(x: Double, counts: Bool) {
        #expect((proposed(frame(x: x)) != nil) == counts)
    }

    @Test(arguments: [(276.0, true), (275.0, false), (375.0, true), (376.0, false)])
    func theLimitsHoldMovingRightToo(x: Double, counts: Bool) {
        #expect((proposed(frame(x: x), heading: .right) != nil) == counts)
    }

    @Test(arguments: [(752.0, true), (751.0, false)])
    func aNarrowWindowHasAZoneOfAtLeast48Points(x: Double, counts: Bool) {
        let narrow = ScreenWindow(
            number: 3, frame: WindowFrame(x: 650, y: 100, width: 150, height: 400))
        #expect((proposed(frame(x: x), among: [narrow]) != nil) == counts)
    }

    @Test func aLargeWindowHasALargeZone() {
        let large = ScreenWindow(
            number: 3, frame: WindowFrame(x: 0, y: 100, width: 1000, height: 400))
        #expect(proposed(frame(x: 750), among: [large]) == 3)
        #expect(proposed(frame(x: 749), among: [large]) == nil)
    }

    @Test func aWindowDraggedAwayFromAnOverlapIsNotProposed() {
        #expect(proposed(frame(x: 650), heading: .right) == nil)
    }

    @Test func aWindowInTheMiddleOfAnotherIsNotProposed() {
        #expect(proposed(frame(x: 600)) == nil)
        #expect(proposed(frame(x: 600), heading: .right) == nil)
    }

    @Test func aWindowThatDoesNotOverlapVerticallyIsNotProposed() {
        let above = WindowFrame(x: 810, y: -150, width: 200, height: 200)
        #expect(proposed(above) == nil)
    }

    @Test func thePointerOverAWindowDoesNotPropose() {
        #expect(
            numbers(frame(x: 900), pointer: ScreenPoint(x: 700, y: 200), among: [Self.other])
                == [nil, 3])
    }

    // The window `other` has its right edge at 800; this one covers that over all of its height,
    // with its own right edge further than its zone from the moving edge.
    private static let cover = ScreenWindow(
        number: 4, frame: WindowFrame(x: 400, y: 50, width: 600, height: 600))

    @Test func aHiddenEdgeIsNotProposedButCanBeGoneTo() {
        #expect(numbers(frame(x: 810), among: [Self.cover, Self.other]) == [nil, 3, 4])
    }

    @Test func aHiddenEdgeIsNoTarget() {
        let found = JoinRule.target(
            for: frame(x: 810), pointer: Self.pointer, among: [Self.cover, Self.other],
            takingHeight: false, heading: .left)
        #expect(found == nil)
    }

    @Test func aVisibleEdgeComesBeforeACloserHiddenOne() {
        let visible = ScreenWindow(
            number: 5, frame: WindowFrame(x: 500, y: 100, width: 320, height: 400))
        #expect(
            numbers(frame(x: 803), among: [visible, Self.cover, Self.other]) == [5, 3, 4])
    }

    @Test func aWindowInFrontThatMayNotJoinHidesAnEdgeAndIsNoChoice() {
        #expect(numbers(frame(x: 810), among: [Self.cover, Self.other], except: [4]) == [nil, 3])
    }

    @Test func aWindowThatMayNotJoinIsNoChoice() {
        #expect(places(frame(x: 810), except: [3]).isEmpty)
    }

    @Test func anEdgeCoveredOnlyOutsideTheDraggedHeightIsVisible() {
        let above = ScreenWindow(
            number: 4, frame: WindowFrame(x: 400, y: 0, width: 600, height: 120))
        #expect(proposed(frame(x: 810), among: [above, Self.other]) == 3)
    }

    @Test(arguments: [(19.0, false), (20.0, true)])
    func anEdgeHasToShowEnough(visible: Double, counts: Bool) {
        // The dragged window spans y 150 to 350; the cover leaves `visible` points at the bottom.
        let partly = ScreenWindow(
            number: 4, frame: WindowFrame(x: 400, y: 100, width: 600, height: 250 - visible))
        #expect(proposed(frame(x: 810), among: [partly, Self.other]) == (counts ? 3 : nil))
    }

    @Test func twoCoversTogetherHideAnEdgeThatNeitherHidesAlone() {
        let upper = ScreenWindow(
            number: 4, frame: WindowFrame(x: 400, y: 100, width: 600, height: 150))
        let lower = ScreenWindow(
            number: 6, frame: WindowFrame(x: 400, y: 240, width: 600, height: 150))
        #expect(proposed(frame(x: 810), among: [upper, lower, Self.other]) == nil)
    }

    @Test func aWindowBehindDoesNotHideAnEdge() {
        #expect(proposed(frame(x: 810), among: [Self.other, Self.cover]) == 3)
    }

    @Test func theDraggedWindowsOwnSizeHidesNothing() {
        #expect(proposed(frame(x: 795, width: 900)) == 3)
    }

    private static let near = ScreenWindow(
        number: 5, frame: WindowFrame(x: 505, y: 100, width: 300, height: 400))

    @Test func theSmallestDistanceIsProposedFirst() {
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

    // Going through the windows, from a place where nothing is proposed.
    private static let far = ScreenWindow(
        number: 5, frame: WindowFrame(x: 2000, y: 2000, width: 300, height: 400))

    @Test func allJoinableWindowsAreChoicesClosestFirst() {
        #expect(numbers(frame(x: 1000), among: [Self.far, Self.other]) == [nil, 3, 5])
    }

    @Test func withoutADirectionAllWindowsAreStillChoices() {
        #expect(numbers(frame(x: 1000), heading: nil, among: [Self.other]) == [nil, 3])
    }

    @Test func whatIsProposedComesBeforeTheOtherWindows() {
        #expect(numbers(frame(x: 810), among: [Self.far, Self.other]) == [3, 5])
    }

    @Test func aFurtherWindowTakesItsClosestSideWhateverTheDirection() {
        let onRight = places(frame(x: 1000), heading: .right, among: [Self.other])
        #expect(onRight.last??.side == .right)
        let onLeft = places(frame(x: 100), heading: .left, among: [Self.other])
        #expect(onLeft.last??.side == .left)
    }

    @Test func noWindowsGiveNoChoices() {
        #expect(places(frame(x: 810), among: []).isEmpty)
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
