import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

/// A pair resized at the seam, with pictures in a panel over both windows (ADR 0048).
@MainActor
@Suite struct PairDragModelSeamResizeTests {
    private static let press = ScreenPoint(x: 500, y: 200)
    private static let lookInterval = 0.1
    private static let settleTime = 0.05

    private let system = FakeWindowSystem()
    private let panel = FakeStandIn()
    private let left = FakeWindow(
        frame: WindowFrame(x: 100, y: 100, width: 400, height: 300), number: 1)
    private let right = FakeWindow(
        frame: WindowFrame(x: 500, y: 100, width: 200, height: 200), number: 2)
    private let model: PairDragModel

    private let wider = WindowFrame(x: 100, y: 100, width: 410, height: 300)
    private let rightWider = WindowFrame(x: 490, y: 100, width: 210, height: 200)

    init() throws {
        system.isScreenRecordingGranted = true
        system.knownWindows = [left, right]
        model = PairDragModel(system: system)
        model.start()
        try model.join(left, to: right, on: .left)
    }

    /// Presses on `pressed`, with the pictures there, and has macOS move the seam of `held`.
    private func start(on pressed: FakeWindow, moving held: FakeWindow, to frame: WindowFrame) {
        system.windowUnderPointer = pressed
        _ = system.send(.pressed(Self.press))
        system.finishStandIn(with: .success(panel))
        held.currentFrame = frame
        system.tick()
    }

    private func startOnLeft() {
        start(on: left, moving: left, to: wider)
    }

    private func drag(toX x: Double) -> Bool {
        system.send(.dragged(ScreenPoint(x: x, y: 200)))
    }

    private func look() {
        system.uptime += Self.lookInterval
        system.tick()
    }

    private func release() {
        _ = system.send(.released(Self.press))
        system.tick()
    }

    @Test func aMovingSeamShowsThePicturesOverThePair() {
        startOnLeft()
        #expect(panel.seamShownAt == ScreenPoint(x: 100, y: 100))
        #expect(panel.shownAt == nil)
    }

    @Test func thePanelStandsOverTheLeftWindowWhenTheRightIsHeld() {
        start(on: right, moving: right, to: rightWider)
        #expect(panel.seamShownAt == ScreenPoint(x: 100, y: 100))
    }

    @Test func theDragEventsAreWithheld() {
        startOnLeft()
        #expect(!drag(toX: 520))
    }

    @Test func theReleaseEventPasses() {
        startOnLeft()
        #expect(system.send(.released(Self.press)))
    }

    @Test func theSeamInThePanelFollowsThePointer() {
        startOnLeft()
        _ = drag(toX: 560)
        #expect(panel.seams.last == 460)
    }

    @Test func aDragEventCallsNoApp() {
        startOnLeft()
        look()
        let calls = right.moves.count + right.resizes.count + left.resizes.count
        _ = drag(toX: 560)
        #expect(right.moves.count + right.resizes.count + left.resizes.count == calls)
    }

    @Test func bothWindowsGetTheSeamsWidthsAtALook() {
        startOnLeft()
        _ = drag(toX: 560)
        look()
        #expect(left.currentFrame.size.width == 460)
        #expect(right.currentFrame.size.width == 140)
    }

    @Test func bothWindowsAreParkedOnceThePanelShows() {
        startOnLeft()
        system.tick()
        #expect(left.currentFrame.origin == system.parkingOrigin)
        #expect(right.currentFrame.origin == system.parkingOrigin)
    }

    @Test func aLookOnlyResizesAWindowThatIsParked() {
        startOnLeft()
        system.tick()
        let moves = right.moves.count
        _ = drag(toX: 560)
        look()
        #expect(right.moves.count == moves)
    }

    @Test func noWindowIsParkedBeforeThePicturesCome() {
        system.windowUnderPointer = left
        _ = system.send(.pressed(Self.press))
        left.currentFrame = wider
        system.tick()
        system.tick()
        #expect(left.currentFrame.origin.x == 100)
        #expect(right.moves.isEmpty)
    }

    @Test func aBusyWindowIsParkedOnALaterTick() {
        startOnLeft()
        right.moveError = .windowBusy
        system.tick()
        right.moveError = nil
        system.tick()
        #expect(right.currentFrame.origin == system.parkingOrigin)
    }

    @Test func noLookComesBeforeItsTime() {
        startOnLeft()
        look()
        let resizes = right.resizes.count
        _ = drag(toX: 560)
        system.tick()
        #expect(right.resizes.count == resizes)
    }

    @Test func aStillSeamAsksTheAppsNothingMore() {
        startOnLeft()
        _ = drag(toX: 560)
        look()
        let resizes = right.resizes.count
        look()
        #expect(right.resizes.count == resizes)
    }

    @Test func aPressBesideTheSeamThatMovesTheOtherWindowsSeamWorksAlike() {
        start(on: right, moving: left, to: wider)
        _ = drag(toX: 560)
        look()
        #expect(left.currentFrame.size.width == 460)
        #expect(right.currentFrame.size.width == 140)
    }

    @Test func thePartnerKeepsItsHeight() {
        startOnLeft()
        _ = drag(toX: 560)
        look()
        #expect(right.currentFrame.size.height == 200)
    }

    @Test func aPictureThatComesLateShowsWithTheSeamWhereItIsNow() {
        system.windowUnderPointer = left
        _ = system.send(.pressed(Self.press))
        left.currentFrame = wider
        system.tick()
        #expect(!drag(toX: 560))
        system.finishStandIn(with: .success(panel))
        #expect(panel.seamShownAt == ScreenPoint(x: 100, y: 100))
        #expect(panel.seams.last == 460)
    }

    @Test func noPicturesLetTheEventsPassAndTheReleasePutsThePartnerBeside() {
        system.windowUnderPointer = left
        _ = system.send(.pressed(Self.press))
        left.currentFrame = wider
        system.tick()
        system.finishStandIn(with: .failure(.captureFailed))
        #expect(drag(toX: 560))
        left.currentFrame = WindowFrame(x: 100, y: 100, width: 460, height: 300)
        release()
        #expect(right.currentFrame == WindowFrame(x: 560, y: 100, width: 140, height: 200))
    }

    @Test func picturesThatTakeTooLongLetTheEventsPass() {
        system.windowUnderPointer = left
        _ = system.send(.pressed(Self.press))
        left.currentFrame = wider
        system.tick()
        system.uptime += 2
        system.tick()
        #expect(drag(toX: 560))
    }

    @Test func theReleaseActsOnTheNextTickAndNotOnTheEvent() {
        startOnLeft()
        _ = drag(toX: 560)
        _ = system.send(.released(ScreenPoint(x: 560, y: 200)))
        #expect(right.currentFrame.origin.x == 500)
        system.tick()
        #expect(left.currentFrame == WindowFrame(x: 100, y: 100, width: 460, height: 300))
        #expect(right.currentFrame == WindowFrame(x: 560, y: 100, width: 140, height: 200))
    }

    @Test func thePanelStaysForTheSettleTimeAfterTheRelease() {
        startOnLeft()
        release()
        #expect(!panel.isDismissed)
        system.uptime += Self.settleTime
        system.tick()
        #expect(panel.isDismissed)
        #expect(!system.isTicking)
    }

    @Test func aLostReleaseStillEndsTheResize() {
        startOnLeft()
        _ = drag(toX: 560)
        system.isPrimaryButtonDown = false
        system.tick()
        #expect(right.currentFrame == WindowFrame(x: 560, y: 100, width: 140, height: 200))
    }

    @Test func aPressRightAfterAReleasePutsTheWindowsExactly() {
        startOnLeft()
        _ = drag(toX: 560)
        _ = system.send(.released(ScreenPoint(x: 560, y: 200)))
        _ = system.send(.pressed(Self.press))
        #expect(right.currentFrame == WindowFrame(x: 560, y: 100, width: 140, height: 200))
        #expect(panel.isDismissed)
    }

    @Test func thePairGoesOnAfterAResize() {
        startOnLeft()
        release()
        _ = system.send(.pressed(Self.press))
        #expect(system.standInRequests == 2)
    }

    @Test func anOuterEdgeResizesOneWindowOnly() {
        start(on: left, moving: left, to: WindowFrame(x: 50, y: 100, width: 450, height: 300))
        #expect(right.moves.isEmpty && right.resizes.isEmpty)
        #expect(panel.seamShownAt == nil)
        #expect(!system.isTicking)
    }

    @Test func aPressBesideTheSeamThatMovesAnOuterEdgeStartsNothing() {
        start(on: right, moving: left, to: WindowFrame(x: 50, y: 100, width: 450, height: 300))
        #expect(right.moves.isEmpty && right.resizes.isEmpty)
        #expect(panel.seamShownAt == nil)
    }
}
