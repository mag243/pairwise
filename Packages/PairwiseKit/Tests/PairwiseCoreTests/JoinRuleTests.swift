import PairwiseCore
import Testing

@Suite struct JoinRuleTests {
    private static let other = ScreenWindow(
        number: 7, frame: WindowFrame(x: 500, y: 100, width: 300, height: 400))

    /// A place for the pointer over none of the windows here.
    private static let awayFromWindows = ScreenPoint(x: -1000, y: -1000)

    private func frame(x: Double, y: Double = 150) -> WindowFrame {
        WindowFrame(x: x, y: y, width: 200, height: 200)
    }

    private func target(
        _ frame: WindowFrame, pointer: ScreenPoint = Self.awayFromWindows,
        among windows: [ScreenWindow] = [Self.other], takingHeight: Bool = false
    ) -> JoinTarget? {
        JoinRule.target(
            for: frame, pointer: pointer, among: windows, takingHeight: takingHeight)
    }

    private static let dragged = ScreenWindow(
        number: 1, frame: WindowFrame(x: 0, y: 0, width: 10, height: 10), owner: 40)
    private static let sameApp = ScreenWindow(
        number: 2, frame: WindowFrame(x: 0, y: 0, width: 10, height: 10), owner: 40)
    private static let otherApp = ScreenWindow(
        number: 3, frame: WindowFrame(x: 0, y: 0, width: 10, height: 10), owner: 41)

    @Test func anyWindowIsACandidateButTheDraggedOne() {
        let candidates = JoinRule.candidates(
            for: 1, among: [Self.dragged, Self.sameApp, Self.otherApp], scope: .anyWindow)
        #expect(candidates == [Self.sameApp, Self.otherApp])
    }

    @Test func withinOneAppOnlyItsWindowsAreCandidates() {
        let candidates = JoinRule.candidates(
            for: 1, among: [Self.dragged, Self.sameApp, Self.otherApp], scope: .sameApp)
        #expect(candidates == [Self.sameApp])
    }

    @Test func withinOneAppAnUnknownDraggedWindowHasNoCandidates() {
        let candidates = JoinRule.candidates(
            for: 9, among: [Self.sameApp, Self.otherApp], scope: .sameApp)
        #expect(candidates.isEmpty)
    }

    @Test(arguments: [
        (JoinScope.anyWindow, false, JoinScope.anyWindow),
        (.anyWindow, true, .sameApp),
        (.sameApp, false, .sameApp),
        (.sameApp, true, .anyWindow),
    ])
    func theKeyGivesTheOtherScope(setting: JoinScope, isKeyDown: Bool, expected: JoinScope) {
        #expect(setting.switched(if: isKeyDown) == expected)
    }

    @Test func noWindowsGiveNoTarget() {
        #expect(target(frame(x: 0), among: []) == nil)
    }

    @Test func aFarWindowIsNoTarget() {
        #expect(target(frame(x: 0)) == nil)
    }

    @Test func aWindowCloseToTheRightEdgeJoinsOnTheRight() throws {
        let found = try #require(target(frame(x: 810)))
        #expect(found.side == .right)
        #expect(found.frame == WindowFrame(x: 800, y: 100, width: 200, height: 200))
    }

    @Test func aWindowCloseToTheLeftEdgeJoinsOnTheLeft() throws {
        let found = try #require(target(frame(x: 290)))
        #expect(found.side == .left)
        #expect(found.frame == WindowFrame(x: 300, y: 100, width: 200, height: 200))
    }

    @Test func anOverlappingEdgeWithinTheDistanceJoins() {
        #expect(target(frame(x: 790))?.side == .right)
    }

    @Test func askedToItTakesTheOthersHeight() {
        let found = target(frame(x: 810), takingHeight: true)
        #expect(found?.frame == WindowFrame(x: 800, y: 100, width: 200, height: 400))
    }

    @Test func aPointerOverTheRightHalfJoinsOnTheRight() throws {
        let found = try #require(target(frame(x: 0), pointer: ScreenPoint(x: 700, y: 200)))
        #expect(found.side == .right)
        #expect(found.frame == WindowFrame(x: 800, y: 100, width: 200, height: 200))
    }

    @Test func aPointerOverTheLeftHalfJoinsOnTheLeft() {
        #expect(target(frame(x: 0), pointer: ScreenPoint(x: 600, y: 200))?.side == .left)
    }

    @Test func aMuchLargerWindowJoinsWhatIsUnderThePointer() {
        let large = WindowFrame(x: 100, y: 0, width: 1500, height: 1000)
        let found = target(large, pointer: ScreenPoint(x: 700, y: 200))
        #expect(found?.other == Self.other)
    }

    @Test func theFrontmostWindowUnderThePointerWins() {
        let front = ScreenWindow(
            number: 8, frame: WindowFrame(x: 650, y: 150, width: 100, height: 100))
        let found = target(
            frame(x: 0), pointer: ScreenPoint(x: 700, y: 200), among: [front, Self.other])
        #expect(found?.other == front)
    }

    @Test func aWindowDraggedOverAnotherWithThePointerElsewhereDoesNotJoin() {
        #expect(target(frame(x: 600)) == nil)
    }

    @Test func aWindowUnderThePointerJoinsWhateverItsSize() {
        let tiny = WindowFrame(x: 0, y: 0, width: 10, height: 10)
        #expect(target(tiny, pointer: ScreenPoint(x: 700, y: 200)) != nil)
    }

    @Test(arguments: [(23.0, true), (24.0, true), (25.0, false)])
    func theDistanceIsALimit(distance: Double, joins: Bool) {
        let found = self.target(frame(x: 800 + distance))
        #expect((found != nil) == joins)
    }

    @Test func aWindowEntirelyAboveIsNoTarget() {
        #expect(target(frame(x: 800, y: -150)) == nil)
    }

    @Test func aWindowEntirelyBelowIsNoTarget() {
        #expect(target(frame(x: 800, y: 500)) == nil)
    }

    @Test func theClosestEdgeWins() throws {
        let near = ScreenWindow(
            number: 8, frame: WindowFrame(x: 1008, y: 100, width: 300, height: 400))
        let found = try #require(target(frame(x: 805), among: [Self.other, near]))
        #expect(found.other.number == 8)
        #expect(found.side == .left)
    }
}
