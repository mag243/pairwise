import PairwiseCore
import Testing

@Suite struct JoinPickTests {
    private static func place(_ number: UInt32, side: PairSide = .left) -> JoinPlace {
        JoinPlace(
            other: ScreenWindow(
                number: number, frame: WindowFrame(x: 0, y: 0, width: 10, height: 10)),
            side: side)
    }
    private static let first = place(1)
    private static let second = place(2)
    private static let third = place(3)

    @Test func withoutChoicesThereIsNoPlace() {
        var pick = JoinPick()
        pick.update(to: [])
        pick.advance()
        #expect(pick.place == nil)
    }

    @Test func itStartsAtTheFirstChoice() {
        var pick = JoinPick()
        pick.update(to: [Self.first, Self.second])
        #expect(pick.place == Self.first)
    }

    @Test func advancingGoesToTheNextAndStartsOverAfterTheLast() {
        var pick = JoinPick()
        pick.update(to: [Self.first, Self.second])
        pick.advance()
        #expect(pick.place == Self.second)
        pick.advance()
        #expect(pick.place == Self.first)
    }

    @Test func goingBackFromTheFirstGoesToTheLast() {
        var pick = JoinPick()
        pick.update(to: [Self.first, Self.second, Self.third])
        pick.advance(by: -1)
        #expect(pick.place == Self.third)
    }

    @Test func noWindowIsAChoiceToo() {
        var pick = JoinPick()
        pick.update(to: [nil, Self.second])
        #expect(pick.place == nil)
        pick.advance()
        #expect(pick.place == Self.second)
    }

    @Test func noWindowIsLeftBehindWhenGoingOn() {
        var pick = JoinPick()
        pick.update(to: [nil, Self.first, Self.second])
        pick.advance()
        pick.advance()
        #expect(pick.place == Self.second)
        pick.advance()
        #expect(pick.place == Self.first)
    }

    @Test func goingBackFromNoWindowGoesToTheLast() {
        var pick = JoinPick()
        pick.update(to: [nil, Self.first, Self.second])
        pick.advance(by: -1)
        #expect(pick.place == Self.second)
    }

    @Test func aChosenWindowStaysChosenWhenItBecomesTheFirstChoice() {
        var pick = JoinPick()
        pick.update(to: [Self.first, Self.second])
        pick.advance()
        pick.update(to: [Self.second, Self.first])
        pick.update(to: [Self.first, Self.second])
        #expect(pick.place == Self.second)
    }

    @Test func aChosenWindowStaysChosenAlsoOnTheOtherSide() {
        var pick = JoinPick()
        pick.update(to: [Self.first, Self.second])
        pick.advance()
        let otherSide = Self.place(2, side: .right)
        pick.update(to: [Self.first, otherSide])
        #expect(pick.place == otherSide)
    }

    @Test func aChosenWindowStaysChosenWhenTheChoicesChange() {
        var pick = JoinPick()
        pick.update(to: [Self.first, Self.second])
        pick.advance()
        pick.update(to: [Self.third, Self.first, Self.second])
        #expect(pick.place == Self.second)
    }

    @Test func aChosenWindowThatLeavesGivesTheFirstChoiceAgain() {
        var pick = JoinPick()
        pick.update(to: [Self.first, Self.second])
        pick.advance()
        pick.update(to: [Self.third, Self.first])
        #expect(pick.place == Self.third)
    }

    @Test func nothingChosenFollowsTheFirstChoice() {
        var pick = JoinPick()
        pick.update(to: [Self.first, Self.second])
        pick.update(to: [Self.second, Self.first])
        #expect(pick.place == Self.second)
    }
}
