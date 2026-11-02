import PairwiseCore
import Testing

@Suite struct JoinRuleTests {
    private static let other = ScreenWindow(
        number: 7, frame: WindowFrame(x: 500, y: 100, width: 300, height: 400))

    private func frame(x: Double, y: Double = 150) -> WindowFrame {
        WindowFrame(x: x, y: y, width: 200, height: 200)
    }

    @Test func noWindowsGiveNoTarget() {
        #expect(JoinRule.target(for: frame(x: 0), among: []) == nil)
    }

    @Test func aFarWindowIsNoTarget() {
        #expect(JoinRule.target(for: frame(x: 0), among: [Self.other]) == nil)
    }

    @Test func aWindowCloseToTheRightEdgeJoinsOnTheRight() throws {
        let target = try #require(JoinRule.target(for: frame(x: 810), among: [Self.other]))
        #expect(target.side == .right)
        #expect(target.frame == WindowFrame(x: 800, y: 100, width: 200, height: 400))
    }

    @Test func aWindowCloseToTheLeftEdgeJoinsOnTheLeft() throws {
        let target = try #require(JoinRule.target(for: frame(x: 290), among: [Self.other]))
        #expect(target.side == .left)
        #expect(target.frame == WindowFrame(x: 300, y: 100, width: 200, height: 400))
    }

    @Test func anOverlappingEdgeWithinTheDistanceJoins() {
        #expect(JoinRule.target(for: frame(x: 790), among: [Self.other])?.side == .right)
    }

    @Test(arguments: [(23.0, true), (24.0, true), (25.0, false)])
    func theDistanceIsALimit(distance: Double, joins: Bool) {
        let target = JoinRule.target(for: frame(x: 800 + distance), among: [Self.other])
        #expect((target != nil) == joins)
    }

    @Test func aWindowEntirelyAboveIsNoTarget() {
        #expect(JoinRule.target(for: frame(x: 800, y: -150), among: [Self.other]) == nil)
    }

    @Test func aWindowEntirelyBelowIsNoTarget() {
        #expect(JoinRule.target(for: frame(x: 800, y: 500), among: [Self.other]) == nil)
    }

    @Test func theClosestEdgeWins() throws {
        let near = ScreenWindow(
            number: 8, frame: WindowFrame(x: 1008, y: 100, width: 300, height: 400))
        let target = try #require(JoinRule.target(for: frame(x: 805), among: [Self.other, near]))
        #expect(target.other.number == 8)
        #expect(target.side == .left)
    }
}
