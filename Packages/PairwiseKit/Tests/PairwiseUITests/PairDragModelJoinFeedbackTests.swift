import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

/// What a join and a parting show and sound like (ADR 0051).
@MainActor
@Suite struct PairDragModelJoinFeedbackTests {
    private static let press = ScreenPoint(x: 50, y: 110)
    /// Far enough from the press for the drag to have a direction.
    private static let goingLeft = ScreenPoint(x: 30, y: 110)
    private static let nearRightEdge = ScreenPoint(x: 810, y: 150)
    private static let onLock = ScreenPoint(x: 500, y: 200)

    private let system = FakeWindowSystem()
    private let window = FakeWindow(
        frame: WindowFrame(x: 0, y: 100, width: 200, height: 200), number: 1)
    private let other = FakeWindow(
        frame: WindowFrame(x: 500, y: 100, width: 300, height: 400), number: 2)
    private let left = FakeWindow(
        frame: WindowFrame(x: 100, y: 100, width: 400, height: 200), number: 3)
    private let right = FakeWindow(
        frame: WindowFrame(x: 500, y: 100, width: 200, height: 200), number: 4)
    private let model: PairDragModel

    init() {
        system.isScreenRecordingGranted = true
        system.isPrimaryButtonDown = false
        system.windowUnderPointer = window
        model = PairDragModel(system: system)
        model.start()
    }

    /// Drags the window to the other's edge with the join key, and lets go.
    private func joinWithTheKey() {
        system.knownWindows = [window, other]
        system.isJoinKeyDown = true
        system.isPrimaryButtonDown = true
        _ = system.send(.pressed(Self.press))
        _ = system.send(.dragged(Self.goingLeft))
        window.currentFrame.origin = Self.nearRightEdge
        system.tick()
        _ = system.send(.released(Self.press))
        system.isJoinKeyDown = false
        system.isPrimaryButtonDown = false
    }

    private func clickLock() {
        system.movePointer(to: Self.onLock)
        _ = system.send(.pressed(Self.onLock))
        _ = system.send(.released(Self.onLock))
        system.tick()
    }

    @Test func aJoinBringsTheWindowJoinedToForwardBeforeTheDraggedOne() {
        var order: [String] = []
        other.duringRaise = { order.append("other") }
        window.duringRaise = { order.append("window") }
        joinWithTheKey()
        #expect(order == ["other", "window"])
    }

    @Test func aJoinWithTheLockBringsBothForwardWithTheFrontOneLast() {
        system.knownWindows = [left, right]
        var order: [String] = []
        left.duringRaise = { order.append("left") }
        right.duringRaise = { order.append("right") }
        clickLock()
        #expect(order == ["right", "left"])
    }

    @Test func aFailedJoinBringsNothingForward() {
        window.moveError = .windowRefused
        joinWithTheKey()
        #expect(other.raises == 0)
        #expect(system.sounds.isEmpty)
    }

    @Test func aJoinWithTheKeySounds() {
        joinWithTheKey()
        #expect(system.sounds == [.join])
    }

    @Test func aJoinWithTheLockSounds() {
        system.knownWindows = [left, right]
        clickLock()
        #expect(system.sounds == [.join])
    }

    @Test func partingWithTheLockSounds() throws {
        system.knownWindows = [left, right]
        try model.join(left, to: right, on: .left)
        clickLock()
        #expect(system.sounds == [.part])
    }

    @Test func partingWithTheKeySounds() throws {
        system.knownWindows = [window, other]
        try model.join(window, to: other, on: .left)
        system.isJoinKeyDown = true
        system.isPrimaryButtonDown = true
        _ = system.send(.pressed(Self.press))
        #expect(system.sounds == [.part])
    }

    @Test func aPressWithTheKeyOnAWindowInNoPairMakesNoSound() {
        system.knownWindows = [window, other]
        system.isJoinKeyDown = true
        system.isPrimaryButtonDown = true
        _ = system.send(.pressed(Self.press))
        #expect(system.sounds.isEmpty)
    }

    @Test func aWindowThatHasGoneEndsAPairWithoutASound() throws {
        system.knownWindows = [window, other]
        try model.join(window, to: other, on: .left)
        window.isAvailable = false
        system.isPrimaryButtonDown = true
        _ = system.send(.pressed(Self.press))
        #expect(system.sounds.isEmpty)
    }

    @Test func theSettingTurnsTheSoundsOff() {
        model.playsSounds = false
        joinWithTheKey()
        #expect(system.sounds.isEmpty)
    }
}
