import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

@MainActor
@Suite struct PairDragModelJoiningTests {
    private static let press = ScreenPoint(x: 50, y: 110)
    /// Far enough from the press for the drag to have a direction.
    private static let goingLeft = ScreenPoint(x: 30, y: 110)
    private static let goingRight = ScreenPoint(x: 70, y: 110)
    private static let far = ScreenPoint(x: 0, y: 150)
    private static let nearRightEdge = ScreenPoint(x: 810, y: 150)
    private static let joined = WindowFrame(x: 800, y: 100, width: 200, height: 200)
    private static let joinedAtItsHeight = WindowFrame(x: 800, y: 100, width: 200, height: 400)

    private let system = FakeWindowSystem()
    private let window = FakeWindow(
        frame: WindowFrame(x: 0, y: 100, width: 200, height: 200), number: 1)
    private let other = FakeWindow(
        frame: WindowFrame(x: 500, y: 100, width: 300, height: 400), number: 2)
    private let model: PairDragModel

    init() {
        system.isScreenRecordingGranted = true
        system.isJoinKeyDown = true
        system.windowUnderPointer = window
        system.knownWindows = [window, other]
        model = PairDragModel(system: system)
        model.start()
    }

    /// Presses with the key, and has macOS move the window to `place`.
    private func drag(to place: ScreenPoint, through point: ScreenPoint = Self.goingLeft) {
        _ = system.send(.pressed(Self.press))
        _ = system.send(.dragged(point))
        window.currentFrame.origin = place
        system.tick()
    }

    @Test func theKeyPressedDuringADragStartsJoining() {
        system.isJoinKeyDown = false
        _ = system.send(.pressed(Self.press))
        #expect(!system.isTicking)
        system.isJoinKeyDown = true
        #expect(system.send(.dragged(Self.goingLeft)))
        #expect(system.isTicking)
        window.currentFrame.origin = Self.nearRightEdge
        system.tick()
        #expect(system.guideFrames.last == Self.joined)
    }

    @Test func aDragWithoutTheKeyStartsNothing() {
        system.isJoinKeyDown = false
        _ = system.send(.pressed(Self.press))
        _ = system.send(.dragged(ScreenPoint(x: 700, y: 200)))
        #expect(!system.isTicking)
    }

    @Test func lettingGoOfTheKeyTakesTheGuideAwayAndJoinsNothing() {
        _ = system.send(.pressed(Self.press))
        _ = system.send(.dragged(ScreenPoint(x: 700, y: 200)))
        window.currentFrame.origin = Self.far
        system.tick()
        system.isJoinKeyDown = false
        _ = system.send(.dragged(ScreenPoint(x: 700, y: 201)))
        system.tick()
        #expect(!system.isGuideShowing)
        _ = system.send(.released(ScreenPoint(x: 700, y: 201)))
        #expect(window.resizes.isEmpty)
    }

    @Test func theKeyAfterTheReleaseStartsNothing() {
        system.isJoinKeyDown = false
        _ = system.send(.pressed(Self.press))
        _ = system.send(.released(Self.press))
        system.isJoinKeyDown = true
        _ = system.send(.dragged(ScreenPoint(x: 700, y: 200)))
        #expect(!system.isTicking)
    }

    @Test func theKeyDuringADragOnAWindowInAPairPartsIt() throws {
        try model.join(window, to: other, on: .left)
        system.isJoinKeyDown = false
        _ = system.send(.pressed(Self.press))
        system.isJoinKeyDown = true
        _ = system.send(.dragged(ScreenPoint(x: 700, y: 200)))
        #expect(model.lastPressOutcome == "joining")
    }

    @Test func withoutTheKeyNothingJoins() {
        system.isJoinKeyDown = false
        drag(to: Self.nearRightEdge)
        #expect(!system.isTicking)
        #expect(!system.isGuideShowing)
    }

    @Test func eventsAlwaysPassWhileJoining() {
        drag(to: Self.nearRightEdge)
        #expect(system.send(.dragged(Self.goingLeft)))
        #expect(system.standInRequests == 0)
    }

    @Test func aWindowNearAnEdgeShowsTheGuideWhereItWillLand() {
        drag(to: Self.nearRightEdge)
        #expect(system.guideFrames.last == Self.joined)
        #expect(system.isGuideShowing)
    }

    @Test func aPointerOverAWindowWithNoEdgeNearShowsNoGuide() {
        _ = system.send(.pressed(Self.press))
        _ = system.send(.dragged(ScreenPoint(x: 700, y: 200)))
        window.currentFrame.origin = Self.far
        system.tick()
        #expect(!system.isGuideShowing)
    }

    @Test func aWindowThatLeavesTheEdgeLosesTheGuide() {
        drag(to: Self.nearRightEdge)
        window.currentFrame.origin = Self.far
        system.tick()
        #expect(!system.isGuideShowing)
    }

    @Test func aWindowThatHasNotMovedShowsNoGuide() {
        window.currentFrame.origin = Self.nearRightEdge
        _ = system.send(.pressed(Self.press))
        system.tick()
        #expect(!system.isGuideShowing)
    }

    @Test func aWindowKeepsItsHeightWhenItJoins() {
        drag(to: Self.nearRightEdge)
        _ = system.send(.released(Self.press))
        #expect(window.resizes.isEmpty)
    }

    @Test func shiftTakesTheOthersHeightAndTheGuideShowsIt() {
        system.isEqualHeightKeyDown = true
        _ = system.send(.pressed(Self.press))
        _ = system.send(.dragged(Self.goingLeft))
        window.currentFrame.origin = Self.nearRightEdge
        system.tick()
        #expect(system.guideFrames.last == Self.joinedAtItsHeight)
        _ = system.send(.released(Self.press))
        #expect(window.currentFrame == Self.joinedAtItsHeight)
    }

    @Test func lettingGoOfShiftKeepsTheOwnHeight() {
        system.isEqualHeightKeyDown = true
        _ = system.send(.pressed(Self.press))
        _ = system.send(.dragged(Self.goingLeft))
        window.currentFrame.origin = Self.nearRightEdge
        system.tick()
        system.isEqualHeightKeyDown = false
        _ = system.send(.dragged(Self.goingLeft))
        system.tick()
        _ = system.send(.released(Self.press))
        #expect(window.currentFrame == Self.joined)
    }

    @Test func theSeamIsAsHighAsTheShorterWindow() {
        drag(to: Self.nearRightEdge)
        _ = system.send(.released(Self.press))
        #expect(system.seamFlashes.first?.size.height == 200)
    }

    @Test func theReleaseJoinsThemWithTheOthersTop() {
        drag(to: Self.nearRightEdge)
        _ = system.send(.released(Self.press))
        #expect(window.currentFrame == Self.joined)
        #expect(!system.isGuideShowing)
        #expect(!system.isTicking)
        system.isJoinKeyDown = false
        _ = system.send(.pressed(Self.press))
        #expect(model.lastPressOutcome == "watching")
    }

    @Test func theSeamLightsUpAtTheJoin() {
        drag(to: Self.nearRightEdge)
        _ = system.send(.released(Self.press))
        #expect(system.seamFlashes == [WindowFrame(x: 797, y: 100, width: 6, height: 200)])
    }

    @Test func aSeamOnTheLeftLightsUpThere() {
        drag(to: ScreenPoint(x: 290, y: 150), through: Self.goingRight)
        _ = system.send(.released(Self.press))
        #expect(system.seamFlashes.first?.origin.x == 497)
    }

    @Test func aReleaseFarAwayJoinsNothing() {
        drag(to: Self.far)
        _ = system.send(.released(Self.press))
        #expect(window.resizes.isEmpty)
        system.isJoinKeyDown = false
        _ = system.send(.pressed(Self.press))
        #expect(model.lastPressOutcome == "not in a pair")
    }

    @Test func aRefusedResizeJoinsNothing() {
        window.resizeError = .windowRefused
        system.isEqualHeightKeyDown = true
        _ = system.send(.pressed(Self.press))
        _ = system.send(.dragged(Self.goingLeft))
        window.currentFrame.origin = Self.nearRightEdge
        system.tick()
        _ = system.send(.released(Self.press))
        #expect(system.seamFlashes.isEmpty)
        system.isJoinKeyDown = false
        _ = system.send(.pressed(Self.press))
        #expect(model.lastPressOutcome == "not in a pair")
    }

    @Test func aWindowInAPairIsNoCandidate() throws {
        let third = FakeWindow(frame: WindowFrame(x: 0, y: 0, width: 9, height: 9), number: 3)
        try model.join(other, to: third, on: .left)
        drag(to: Self.nearRightEdge)
        #expect(!system.isGuideShowing)
    }

    @Test func aLostReleaseStillEndsTheJoin() {
        drag(to: Self.nearRightEdge)
        system.isPrimaryButtonDown = false
        system.tick()
        #expect(window.currentFrame == Self.joined)
        #expect(!system.isTicking)
    }

    @Test func theKeyAtAPressPartsAPair() throws {
        try model.join(window, to: other, on: .left)
        drag(to: Self.far)
        _ = system.send(.released(Self.press))
        system.isJoinKeyDown = false
        _ = system.send(.pressed(Self.press))
        #expect(model.lastPressOutcome == "not in a pair")
    }

    @Test func partingMovesOnlyThatWindow() throws {
        try model.join(window, to: other, on: .left)
        drag(to: Self.far)
        _ = system.send(.released(Self.press))
        #expect(other.moves.isEmpty)
    }

    @Test func aPartedWindowCanJoinAgainAtOnce() throws {
        try model.join(window, to: other, on: .right)
        drag(to: Self.nearRightEdge)
        #expect(system.isGuideShowing)
    }

    @Test func aWindowThatHasGoneCannotJoin() {
        system.knownWindows = []
        _ = system.send(.pressed(Self.press))
        #expect(model.lastPressOutcome == "no window to join with")
    }
}
