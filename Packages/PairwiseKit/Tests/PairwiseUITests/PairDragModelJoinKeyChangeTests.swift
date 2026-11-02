import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

/// A key let go or pressed during a join, with the pointer standing still (ADR 0041).
@MainActor
@Suite struct PairDragModelJoinKeyChangeTests {
    private static let press = ScreenPoint(x: 50, y: 110)
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

    /// Drags to the other's edge with Shift, ready for a key to change with the pointer still.
    private func dragNearTheEdgeWithShift() {
        system.isEqualHeightKeyDown = true
        _ = system.send(.pressed(Self.press))
        _ = system.send(.dragged(Self.press))
        window.currentFrame.origin = Self.nearRightEdge
        system.tick()
    }

    @Test func lettingGoOfShiftWithThePointerStillKeepsTheOwnHeight() {
        dragNearTheEdgeWithShift()
        _ = system.send(.keysChanged(isJoinKeyDown: true, isEqualHeightKeyDown: false))
        _ = system.send(.released(Self.press))
        #expect(window.currentFrame == Self.joined)
    }

    @Test func lettingGoOfShiftWithThePointerStillUpdatesTheGuide() {
        dragNearTheEdgeWithShift()
        _ = system.send(.keysChanged(isJoinKeyDown: true, isEqualHeightKeyDown: false))
        system.tick()
        #expect(system.guideFrames.last == Self.joined)
    }

    @Test func shiftWithThePointerStillUpdatesTheGuide() {
        _ = system.send(.pressed(Self.press))
        _ = system.send(.dragged(Self.press))
        window.currentFrame.origin = Self.nearRightEdge
        system.tick()
        _ = system.send(.keysChanged(isJoinKeyDown: true, isEqualHeightKeyDown: true))
        system.tick()
        #expect(system.guideFrames.last == Self.joinedAtItsHeight)
    }

    @Test func lettingGoOfTheKeyWithThePointerStillJoinsNothing() {
        dragNearTheEdgeWithShift()
        _ = system.send(.keysChanged(isJoinKeyDown: false, isEqualHeightKeyDown: false))
        _ = system.send(.released(Self.press))
        #expect(window.currentFrame.origin == Self.nearRightEdge)
        #expect(window.resizes.isEmpty)
    }

    @Test func lettingGoOfTheKeyWithThePointerStillTakesTheGuideAway() {
        dragNearTheEdgeWithShift()
        _ = system.send(.keysChanged(isJoinKeyDown: false, isEqualHeightKeyDown: false))
        system.tick()
        #expect(!system.isGuideShowing)
    }
}
