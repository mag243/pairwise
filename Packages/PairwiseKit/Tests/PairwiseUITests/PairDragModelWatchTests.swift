import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

@MainActor
@Suite struct PairDragModelWatchTests {
    private static let onTitleBar = ScreenPoint(x: 150, y: 110)
    private static let inContent = ScreenPoint(x: 150, y: 300)
    private static let further = ScreenPoint(x: 190, y: 140)
    private static let moved = ScreenPoint(x: 140, y: 130)

    private let system = FakeWindowSystem()
    private let window = FakeWindow(
        frame: WindowFrame(x: 100, y: 100, width: 400, height: 300), number: 1)
    private let partner = FakeWindow(
        frame: WindowFrame(x: 0, y: 500, width: 200, height: 200), number: 2)
    private let panel = FakeStandIn()
    private let model: PairDragModel

    init() {
        system.isScreenRecordingGranted = true
        system.windowUnderPointer = window
        model = PairDragModel(system: system)
        model.start()
        try? model.join(window, to: partner, on: .left)
    }

    /// What macOS does with a window drag: the drag event passes, and the window moves.
    private func dragAsMacOS() {
        _ = system.send(.dragged(Self.further))
        window.currentFrame.origin = Self.moved
        system.tick()
    }

    @Test func dragEventsPassUntilTheWindowMoves() {
        _ = system.send(.pressed(Self.onTitleBar))
        system.finishStandIn(with: .success(panel))
        #expect(system.send(.dragged(Self.further)))
        system.tick()
        #expect(system.send(.dragged(Self.further)))
        #expect(panel.shownAt == nil)
    }

    @Test func aDragThatMovesNoWindowNeverShowsAPanel() {
        _ = system.send(.pressed(Self.inContent))
        system.finishStandIn(with: .success(panel))
        _ = system.send(.dragged(Self.further))
        system.tick()
        _ = system.send(.released(Self.further))
        #expect(panel.shownAt == nil)
        #expect(window.moves.isEmpty)
        #expect(partner.moves.isEmpty)
    }

    @Test func aResizeAtAnOuterEdgeIsLeftAlone() {
        _ = system.send(.pressed(Self.onTitleBar))
        system.finishStandIn(with: .success(panel))
        _ = system.send(.dragged(Self.further))
        window.currentFrame.origin.x -= 10
        window.currentFrame.size.width += 10
        system.tick()
        #expect(system.send(.dragged(Self.further)))
        #expect(panel.shownAt == nil)
    }

    @Test func thePanelGoesWhereThePointerTookTheWindowEvenIfItLagsBehind() {
        _ = system.send(.pressed(Self.onTitleBar))
        system.finishStandIn(with: .success(panel))
        _ = system.send(.dragged(Self.further))
        window.currentFrame.origin = ScreenPoint(x: 101, y: 100)
        system.tick()
        #expect(panel.shownAt == Self.moved)
    }

    @Test func aMovedWindowIsHeldUntilThePictureComes() {
        _ = system.send(.pressed(Self.onTitleBar))
        dragAsMacOS()
        #expect(!system.send(.dragged(Self.further)))
        system.finishStandIn(with: .success(panel))
        #expect(panel.shownAt == Self.moved)
    }

    @Test func aPictureThatTakesTooLongLetsTheDragPass() {
        _ = system.send(.pressed(Self.onTitleBar))
        dragAsMacOS()
        system.uptime = 1
        #expect(system.send(.dragged(Self.further)))
        #expect(model.problem == .captureFailed)
        system.finishStandIn(with: .success(panel))
        #expect(panel.shownAt == nil)
    }

    @Test func aButtonNotYetSeenDownDoesNotEndThePress() {
        system.isPrimaryButtonDown = false
        _ = system.send(.pressed(Self.onTitleBar))
        system.tick()
        window.currentFrame.origin = Self.moved
        system.isPrimaryButtonDown = true
        system.tick()
        #expect(!system.send(.dragged(Self.further)))
    }

    @Test func aButtonSeenDownAndThenUpEndsThePress() {
        _ = system.send(.pressed(Self.onTitleBar))
        system.tick()
        system.isPrimaryButtonDown = false
        system.tick()
        #expect(!system.isTicking)
    }

    @Test func aButtonNeverSeenDownEndsThePressInTheEnd() {
        system.isPrimaryButtonDown = false
        _ = system.send(.pressed(Self.onTitleBar))
        system.uptime = 0.3
        system.tick()
        #expect(!system.isTicking)
    }
}
