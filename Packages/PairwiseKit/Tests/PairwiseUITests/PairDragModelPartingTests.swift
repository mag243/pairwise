import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

@MainActor
@Suite struct PairDragModelPartingTests {
    private static let press = ScreenPoint(x: 150, y: 110)
    private static let further = ScreenPoint(x: 190, y: 140)
    private static let moved = ScreenPoint(x: 140, y: 130)
    private static let partnerStart = ScreenPoint(x: 500, y: 100)

    private let system = FakeWindowSystem()
    private let window = FakeWindow(
        frame: WindowFrame(x: 100, y: 100, width: 400, height: 300), number: 1)
    private let partner = FakeWindow(
        frame: WindowFrame(x: 500, y: 100, width: 200, height: 200), number: 2)
    private let panel = FakeStandIn()
    private let model: PairDragModel

    init() throws {
        system.isScreenRecordingGranted = true
        system.windowUnderPointer = window
        system.knownWindows = [window, partner]
        model = PairDragModel(system: system)
        model.start()
        try model.join(window, to: partner, on: .left)
    }

    /// Presses, and lets the panel take over and the windows park.
    private func startDragWithPanel() {
        _ = system.send(.pressed(Self.press))
        system.finishStandIn(with: .success(panel))
        _ = system.send(.dragged(Self.further))
        window.currentFrame.origin = Self.moved
        system.tick()
        system.tick()
    }

    /// Presses Command during the drag, and lets the next tick part the pair.
    private func part() {
        system.isJoinKeyDown = true
        _ = system.send(.dragged(Self.further))
        system.tick()
    }

    @Test func theKeyWithThePointerStillPartsThePair() {
        startDragWithPanel()
        _ = system.send(.keysChanged(isJoinKeyDown: true, isEqualHeightKeyDown: false))
        system.tick()
        #expect(panel.isDismissed)
    }

    @Test func aChangeOfKeysWithoutTheJoinKeyLeavesThePairInOneDrag() {
        startDragWithPanel()
        _ = system.send(.keysChanged(isJoinKeyDown: false, isEqualHeightKeyDown: true))
        system.tick()
        #expect(!panel.isDismissed)
    }

    @Test func theKeyDuringADragBringsThePanelDown() {
        startDragWithPanel()
        part()
        #expect(panel.isDismissed)
    }

    @Test func thePartnerGoesBackToWhereItWas() {
        startDragWithPanel()
        part()
        #expect(partner.moves.last == Self.partnerStart)
    }

    @Test func theWindowGoesWhereThePanelShowedIt() {
        startDragWithPanel()
        part()
        #expect(window.moves.last == Self.moved)
    }

    @Test func thePairHasEnded() {
        startDragWithPanel()
        part()
        system.isJoinKeyDown = false
        _ = system.send(.released(Self.further))
        _ = system.send(.pressed(Self.press))
        #expect(model.lastPressOutcome == "not in a pair")
    }

    @Test func thePartedWindowFollowsThePointerAndTheEventsStayHeld() {
        startDragWithPanel()
        part()
        #expect(!system.send(.dragged(ScreenPoint(x: 200, y: 140))))
        system.tick()
        #expect(window.moves.last == ScreenPoint(x: 150, y: 130))
    }

    @Test func thePartedWindowStaysMovingWithoutTheKey() {
        startDragWithPanel()
        part()
        system.isJoinKeyDown = false
        #expect(!system.send(.dragged(ScreenPoint(x: 200, y: 140))))
        system.tick()
        #expect(window.moves.last == ScreenPoint(x: 150, y: 130))
    }

    @Test func theReleaseLeavesThePartedWindowWhereThePointerIs() {
        startDragWithPanel()
        part()
        _ = system.send(.dragged(ScreenPoint(x: 200, y: 140)))
        _ = system.send(.released(ScreenPoint(x: 200, y: 140)))
        #expect(window.moves.last == ScreenPoint(x: 150, y: 130))
        #expect(!system.isTicking)
    }

    @Test func aPartedWindowCanJoinAnother() {
        let third = FakeWindow(
            frame: WindowFrame(x: 1000, y: 100, width: 200, height: 200), number: 3)
        system.knownWindows.append(third)
        startDragWithPanel()
        part()
        _ = system.send(.dragged(ScreenPoint(x: 640, y: 150)))
        system.tick()
        _ = system.send(.released(ScreenPoint(x: 640, y: 150)))
        #expect(window.currentFrame.origin == ScreenPoint(x: 600, y: 100))
    }

    @Test func theKeyBeforeThePanelLetsMacOSGoOnDragging() {
        _ = system.send(.pressed(Self.press))
        system.isJoinKeyDown = true
        #expect(system.send(.dragged(Self.further)))
        #expect(window.moves.isEmpty)
        system.isJoinKeyDown = false
        _ = system.send(.released(Self.further))
        _ = system.send(.pressed(Self.press))
        #expect(model.lastPressOutcome == "not in a pair")
    }

    @Test func theKeyOnceTheWindowMovedHoldsItAsTheEventsStopped() {
        _ = system.send(.pressed(Self.press))
        _ = system.send(.dragged(Self.further))
        window.currentFrame.origin = Self.moved
        system.tick()
        system.isJoinKeyDown = true
        #expect(!system.send(.dragged(ScreenPoint(x: 200, y: 140))))
        system.tick()
        #expect(window.moves.last == ScreenPoint(x: 150, y: 130))
    }

    @Test func aBusyPartnerStillParts() {
        startDragWithPanel()
        partner.moveError = .windowBusy
        part()
        #expect(panel.isDismissed)
    }
}
