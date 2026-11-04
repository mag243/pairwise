import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

@MainActor
@Suite struct PairDragModelJoinChoiceTests {
    private static let press = ScreenPoint(x: 1000, y: 110)
    private static let goingLeft = ScreenPoint(x: 950, y: 110)
    private static let goingRight = ScreenPoint(x: 1050, y: 110)
    private static let start = WindowFrame(x: 900, y: 100, width: 200, height: 200)
    /// Beside the right edges at x 800 of `front` and `back`.
    private static let beside = ScreenPoint(x: 810, y: 100)
    private static let frontFrame = WindowFrame(x: 500, y: 100, width: 300, height: 400)
    private static let backFrame = WindowFrame(x: 400, y: 120, width: 400, height: 500)

    private let system = FakeWindowSystem()
    private let window = FakeWindow(frame: Self.start, number: 1)
    private let front = FakeWindow(frame: Self.frontFrame, number: 2)
    private let back = FakeWindow(frame: Self.backFrame, number: 3)
    private let model: PairDragModel

    init() {
        system.isScreenRecordingGranted = true
        system.isJoinKeyDown = true
        system.windowUnderPointer = window
        system.knownWindows = [window, front, back]
        model = PairDragModel(system: system)
        model.start()
    }

    private func drag(through point: ScreenPoint, to place: ScreenPoint) {
        _ = system.send(.pressed(Self.press))
        _ = system.send(.dragged(point))
        window.currentFrame.origin = place
        system.tick()
    }

    @Test func movingLeftTheWindowOnTheLeftIsOutlinedAndTheGuideIsBesideIt() {
        drag(through: Self.goingLeft, to: Self.beside)
        #expect(system.outlineFrames.last == Self.frontFrame)
        #expect(system.isOutlineShowing)
        #expect(system.guideFrames.last == WindowFrame(x: 800, y: 100, width: 200, height: 200))
    }

    @Test func movingRightAWindowOnTheLeftGetsNoProposal() {
        drag(through: Self.goingRight, to: Self.beside)
        #expect(!system.isGuideShowing)
        #expect(!system.isOutlineShowing)
    }

    @Test func aWindowOverlappingAnotherGetsNoProposalAtTheStart() {
        window.currentFrame = WindowFrame(x: 600, y: 100, width: 200, height: 200)
        _ = system.send(.pressed(ScreenPoint(x: 650, y: 110)))
        _ = system.send(.dragged(ScreenPoint(x: 750, y: 110)))
        window.currentFrame.origin = ScreenPoint(x: 700, y: 100)
        system.tick()
        #expect(!system.isGuideShowing)
        #expect(!system.isOutlineShowing)
    }

    @Test func theKeyPressedWithTheWindowAtAnEdgeKnowsTheDirectionFromThePress() {
        system.isJoinKeyDown = false
        _ = system.send(.pressed(Self.press))
        _ = system.send(.dragged(Self.goingLeft))
        system.isJoinKeyDown = true
        _ = system.send(.dragged(Self.goingLeft))
        window.currentFrame.origin = Self.beside
        system.tick()
        #expect(system.outlineFrames.last == Self.frontFrame)
    }

    @Test func aWindowInAPairHidesWhatIsBehindIt() throws {
        let partner = FakeWindow(
            frame: WindowFrame(x: 200, y: 100, width: 300, height: 400), number: 4)
        system.knownWindows = [window, partner, front, back]
        try model.join(front, to: partner, on: .right)
        drag(through: Self.goingLeft, to: Self.beside)
        #expect(system.outlineFrames.last == Self.backFrame)
    }

    @Test func theWatchOnChoiceInputLastsAsLongAsTheJoin() {
        drag(through: Self.goingLeft, to: Self.beside)
        #expect(system.isJoinChoiceInputWatched)
        _ = system.send(.released(Self.goingLeft))
        #expect(!system.isJoinChoiceInputWatched)
        #expect(!system.isOutlineShowing)
    }

    @Test func aPlainDragDoesNotWatchChoiceInput() {
        system.isJoinKeyDown = false
        _ = system.send(.pressed(Self.press))
        _ = system.send(.dragged(Self.goingLeft))
        #expect(!system.isJoinChoiceInputWatched)
    }

    @Test func theKeyGoesToTheNextWindowAndIsWithheld() {
        drag(through: Self.goingLeft, to: Self.beside)
        #expect(!system.send(.joinChoiceKey(isRepeat: false)))
        system.tick()
        #expect(system.outlineFrames.last == Self.backFrame)
    }

    @Test func theKeyGivesAProposalWhereThereIsNone() {
        drag(through: Self.goingRight, to: Self.beside)
        #expect(!system.isOutlineShowing)
        _ = system.send(.joinChoiceKey(isRepeat: false))
        system.tick()
        #expect(system.isOutlineShowing)
        #expect(system.outlineFrames.last == Self.frontFrame)
    }

    @Test func aChosenWindowStaysChosenAsTheDragGoesOn() {
        drag(through: Self.goingLeft, to: Self.beside)
        _ = system.send(.joinChoiceKey(isRepeat: false))
        system.tick()
        window.currentFrame.origin = ScreenPoint(x: 2000, y: 100)
        system.tick()
        #expect(system.outlineFrames.last == Self.backFrame)
    }

    @Test func lettingGoOfTheKeyForgetsTheChosenWindow() {
        drag(through: Self.goingLeft, to: Self.beside)
        _ = system.send(.joinChoiceKey(isRepeat: false))
        system.tick()
        _ = system.send(.keysChanged(isJoinKeyDown: false, isEqualHeightKeyDown: false))
        system.tick()
        #expect(!system.isOutlineShowing)
        _ = system.send(.keysChanged(isJoinKeyDown: true, isEqualHeightKeyDown: false))
        system.tick()
        #expect(system.outlineFrames.last == Self.frontFrame)
    }

    @Test func controlGoesOnlyThroughWindowsOfTheSameApp() {
        window.owner = 40
        front.owner = 41
        back.owner = 40
        system.isScopeKeyDown = true
        drag(through: Self.goingRight, to: Self.beside)
        _ = system.send(.joinChoiceKey(isRepeat: false))
        system.tick()
        #expect(system.outlineFrames.last == Self.backFrame)
        _ = system.send(.joinChoiceKey(isRepeat: false))
        system.tick()
        #expect(system.outlineFrames.last == Self.backFrame)
    }

    @Test func aChosenWindowOutOfScopeGivesWayToWhatRemains() {
        window.owner = 40
        front.owner = 40
        back.owner = 41
        drag(through: Self.goingLeft, to: Self.beside)
        _ = system.send(.joinChoiceKey(isRepeat: false))
        system.tick()
        #expect(system.outlineFrames.last == Self.backFrame)
        _ = system.send(
            .keysChanged(isJoinKeyDown: true, isEqualHeightKeyDown: false, isScopeKeyDown: true))
        system.tick()
        #expect(system.outlineFrames.last == Self.frontFrame)
    }

    @Test func aKeyThatRepeatsIsWithheldAndDoesNotMoveOn() {
        drag(through: Self.goingLeft, to: Self.beside)
        #expect(!system.send(.joinChoiceKey(isRepeat: true)))
        system.tick()
        #expect(system.outlineFrames.last == Self.frontFrame)
    }

    @Test func theWheelGoesToTheNextWindowAndIsWithheld() {
        drag(through: Self.goingLeft, to: Self.beside)
        #expect(!system.send(.scrolledWheel(lines: -1)))
        system.tick()
        #expect(system.outlineFrames.last == Self.backFrame)
    }

    @Test func aTrackpadGoesOnOnlyAfterEnoughMovement() {
        drag(through: Self.goingLeft, to: Self.beside)
        #expect(!system.send(.scrolledTrackpad(points: -10)))
        system.tick()
        #expect(system.outlineFrames.last == Self.frontFrame)
        #expect(!system.send(.scrolledTrackpad(points: -30)))
        system.tick()
        #expect(system.outlineFrames.last == Self.backFrame)
    }

    @Test func theReleaseJoinsTheChosenWindow() {
        drag(through: Self.goingLeft, to: Self.beside)
        _ = system.send(.scrolledWheel(lines: -1))
        system.tick()
        _ = system.send(.released(Self.goingLeft))
        #expect(window.currentFrame == WindowFrame(x: 800, y: 120, width: 200, height: 200))
    }

    @Test func outsideAJoinScrollingAndTheKeyPass() {
        #expect(system.send(.scrolledWheel(lines: -1)))
        #expect(system.send(.joinChoiceKey(isRepeat: false)))
        #expect(system.send(.scrolledTrackpad(points: -40)))
    }

    @Test func withoutTheJoinKeyScrollingPasses() {
        drag(through: Self.goingLeft, to: Self.beside)
        _ = system.send(
            .keysChanged(isJoinKeyDown: false, isEqualHeightKeyDown: false))
        #expect(system.send(.scrolledWheel(lines: -1)))
    }
}
