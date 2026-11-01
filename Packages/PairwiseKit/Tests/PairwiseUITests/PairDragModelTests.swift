import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

@MainActor
@Suite struct PairDragModelTests {
    private static let frame = WindowFrame(x: 100, y: 100, width: 400, height: 300)
    private static let onTitleBar = ScreenPoint(x: 150, y: 110)
    private static let inContent = ScreenPoint(x: 150, y: 300)
    private static let further = ScreenPoint(x: 190, y: 140)
    private static let parked = ScreenPoint(x: 9999, y: 9999)

    private let system = FakeWindowSystem()
    private let window = FakeWindow(frame: Self.frame)
    private let partner = FakeWindow(frame: WindowFrame(x: 0, y: 500, width: 200, height: 200))
    private let panel = FakeStandIn()
    private let model: PairDragModel

    init() {
        system.isScreenRecordingGranted = true
        system.windowUnderPointer = window
        system.partnerWindow = partner
        model = PairDragModel(system: system)
        model.start()
    }

    /// Presses on the title bar, lets the picture arrive, and drags so the panel takes over.
    private func startDrag() {
        _ = system.send(.pressed(Self.onTitleBar))
        system.finishStandIn(with: .success(panel))
        _ = system.send(.dragged(Self.further))
    }

    /// Lets the time pass that the panel stays over placed windows.
    private func letWindowsSettle() {
        system.uptime += 1
        system.tick()
    }

    @Test func thePanelStaysAMomentOverPlacedWindows() {
        startDrag()
        _ = system.send(.released(Self.further))
        #expect(!panel.isDismissed)
        #expect(system.isTicking)
        letWindowsSettle()
        #expect(panel.isDismissed)
        #expect(!system.isTicking)
    }

    @Test func aPressBringsASettlingPanelDownAtOnce() {
        startDrag()
        _ = system.send(.released(Self.further))
        _ = system.send(.pressed(Self.inContent))
        #expect(panel.isDismissed)
    }

    @Test func aDragEventWhileSettlingPasses() {
        startDrag()
        _ = system.send(.released(Self.further))
        #expect(system.send(.dragged(Self.further)))
    }

    @Test func withoutScreenRecordingNothingIsTakenOver() {
        model.stop()
        system.isScreenRecordingGranted = false
        model.start()
        #expect(model.problem == .screenRecordingDenied)
        #expect(!system.isHolding)
    }

    @Test func aPressAndReleaseAlwaysPass() {
        #expect(system.send(.pressed(Self.onTitleBar)))
        #expect(system.send(.released(Self.onTitleBar)))
    }

    @Test func aDragFromTheContentPasses() {
        _ = system.send(.pressed(Self.inContent))
        #expect(system.send(.dragged(Self.further)))
        #expect(system.standInRequests == 0)
    }

    @Test func aPressWithoutAPartnerLetsTheDragPass() {
        system.partnerWindow = nil
        _ = system.send(.pressed(Self.onTitleBar))
        #expect(system.send(.dragged(Self.further)))
    }

    @Test func aClickShowsNoPanelAndMovesNothing() {
        _ = system.send(.pressed(Self.onTitleBar))
        system.finishStandIn(with: .success(panel))
        _ = system.send(.released(Self.onTitleBar))
        #expect(panel.shownAt == nil)
        #expect(window.moves.isEmpty)
        #expect(!system.isTicking)
    }

    @Test func aSmallMoveIsHeldButShowsNoPanel() {
        _ = system.send(.pressed(Self.onTitleBar))
        system.finishStandIn(with: .success(panel))
        #expect(!system.send(.dragged(ScreenPoint(x: 151, y: 110))))
        #expect(panel.shownAt == nil)
    }

    @Test func thePanelShowsWhereThePointerTookTheWindow() {
        startDrag()
        #expect(panel.shownAt == ScreenPoint(x: 140, y: 130))
    }

    @Test func aDragBeforeThePictureIsHeldAndThePanelComesLater() {
        _ = system.send(.pressed(Self.onTitleBar))
        #expect(!system.send(.dragged(Self.further)))
        system.finishStandIn(with: .success(panel))
        #expect(panel.shownAt == ScreenPoint(x: 140, y: 130))
    }

    @Test func eachDragEventMovesThePanelAndIsHeld() {
        startDrag()
        #expect(!system.send(.dragged(ScreenPoint(x: 200, y: 150))))
        #expect(panel.moves == [ScreenPoint(x: 150, y: 140)])
    }

    @Test func bothWindowsAreParkedOnATickOnce() {
        startDrag()
        #expect(window.moves.isEmpty)
        system.tick()
        system.tick()
        #expect(window.moves == [Self.parked])
        #expect(partner.moves == [Self.parked])
    }

    @Test func aBusyWindowIsParkedOnALaterTick() {
        startDrag()
        partner.moveError = .windowBusy
        system.tick()
        partner.moveError = nil
        system.tick()
        #expect(window.moves == [Self.parked])
        #expect(partner.moves == [Self.parked])
    }

    @Test func aWindowThatHasGoneEndsTheDragWithThePartnerBack() {
        startDrag()
        window.moveError = .windowGone
        system.tick()
        #expect(model.problem == .windowGone)
        #expect(panel.isDismissed)
        #expect(partner.moves.last == ScreenPoint(x: 540, y: 130))
    }

    @Test func theReleasePutsBothWherePanelIs() {
        startDrag()
        system.tick()
        #expect(system.send(.released(Self.further)))
        #expect(window.moves.last == ScreenPoint(x: 140, y: 130))
        #expect(partner.moves.last == ScreenPoint(x: 540, y: 130))
        letWindowsSettle()
        #expect(panel.isDismissed)
        #expect(!system.isTicking)
    }

    @Test func thePartnerGoesBesideWhereTheSystemLeftTheWindow() {
        startDrag()
        window.duringMove = { [window] in window.currentFrame.origin.y = 25 }
        _ = system.send(.released(Self.further))
        #expect(partner.moves.last == ScreenPoint(x: 540, y: 25))
    }

    @Test func bothAreRaisedBeforeThePanelComesDown() {
        startDrag()
        var dismissedAtRaise = true
        window.duringRaise = { [panel] in dismissedAtRaise = panel.isDismissed }
        _ = system.send(.released(Self.further))
        #expect(window.raises == 1)
        #expect(partner.raises == 1)
        #expect(!dismissedAtRaise)
    }

    @Test func aBusyAppKeepsThePanelUntilItAnswers() {
        startDrag()
        partner.moveError = .windowBusy
        _ = system.send(.released(Self.further))
        #expect(!panel.isDismissed)
        #expect(system.isTicking)
        partner.moveError = nil
        system.tick()
        #expect(partner.moves.last == ScreenPoint(x: 540, y: 130))
        #expect(window.moves.count == 1)
        letWindowsSettle()
        #expect(panel.isDismissed)
    }

    @Test func anAppBusyTooLongIsReportedAndThePanelComesDown() {
        startDrag()
        partner.moveError = .windowBusy
        _ = system.send(.released(Self.further))
        system.uptime += 1
        system.tick()
        #expect(model.problem == .windowBusy)
        #expect(panel.isDismissed)
    }

    @Test func aFailedPictureLetsTheDragPass() {
        _ = system.send(.pressed(Self.onTitleBar))
        system.finishStandIn(with: .failure(.captureFailed))
        #expect(model.problem == .captureFailed)
        #expect(system.send(.dragged(Self.further)))
    }

    @Test func aPictureThatTakesTooLongLetsTheDragPass() {
        _ = system.send(.pressed(Self.onTitleBar))
        system.uptime = 1
        #expect(system.send(.dragged(Self.further)))
        #expect(model.problem == .captureFailed)
        system.finishStandIn(with: .success(panel))
        #expect(panel.shownAt == nil)
    }

    @Test func aPictureThatArrivedKeepsHoldingALongDrag() {
        startDrag()
        system.uptime = 60
        #expect(!system.send(.dragged(Self.onTitleBar)))
    }

    @Test func aButtonNotYetSeenDownDoesNotEndThePress() {
        system.isPrimaryButtonDown = false
        _ = system.send(.pressed(Self.onTitleBar))
        system.tick()
        #expect(!system.send(.dragged(Self.further)))
    }

    @Test func aButtonSeenDownAndThenUpEndsThePress() {
        _ = system.send(.pressed(Self.onTitleBar))
        system.tick()
        system.isPrimaryButtonDown = false
        system.tick()
        #expect(system.send(.dragged(Self.further)))
    }

    @Test func aButtonNeverSeenDownEndsThePressInTheEnd() {
        system.isPrimaryButtonDown = false
        _ = system.send(.pressed(Self.onTitleBar))
        system.uptime = 0.3
        system.tick()
        #expect(system.send(.dragged(Self.further)))
    }

    @Test func aLostReleaseIsSeenOnATick() {
        startDrag()
        system.tick()
        system.isPrimaryButtonDown = false
        system.tick()
        #expect(window.moves.last == ScreenPoint(x: 140, y: 130))
        letWindowsSettle()
        #expect(panel.isDismissed)
    }

    @Test func stopPutsBothWindowsBack() {
        startDrag()
        system.tick()
        model.stop()
        #expect(window.moves.last == ScreenPoint(x: 140, y: 130))
        #expect(partner.moves.last == ScreenPoint(x: 540, y: 130))
        #expect(panel.isDismissed)
        #expect(!system.isHolding)
    }

    @Test func aNewPressPutsBothWindowsBack() {
        startDrag()
        system.tick()
        _ = system.send(.pressed(Self.inContent))
        #expect(window.moves.last == ScreenPoint(x: 140, y: 130))
        #expect(panel.isDismissed)
    }
}
