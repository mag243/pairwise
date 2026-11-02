import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

/// The open lock on the seam of two windows side by side in no pair (ADR 0044).
@MainActor
@Suite struct PairDragModelOpenLockTests {
    private static let nearSeam = ScreenPoint(x: 505, y: 200)
    private static let onLock = ScreenPoint(x: 500, y: 200)
    /// The lock's middle when one window stands 30 points lower.
    private static let onLowerLock = ScreenPoint(x: 500, y: 215)
    private static let far = ScreenPoint(x: 150, y: 200)

    private let system = FakeWindowSystem()
    private let window = FakeWindow(
        frame: WindowFrame(x: 100, y: 100, width: 400, height: 200), number: 1)
    private let partner = FakeWindow(
        frame: WindowFrame(x: 500, y: 100, width: 200, height: 200), number: 2)
    private let model: PairDragModel

    init() {
        system.isScreenRecordingGranted = true
        system.isPrimaryButtonDown = false
        system.windowUnderPointer = window
        system.knownWindows = [window, partner]
        model = PairDragModel(system: system)
        model.start()
    }

    private func clickOpenLock(at point: ScreenPoint = onLock) {
        system.movePointer(to: point)
        _ = system.send(.pressed(point))
        _ = system.send(.released(point))
        system.tick()
    }

    @Test func windowsSideBySideShowAnOpenLock() {
        system.movePointer(to: Self.nearSeam)
        #expect(system.isLockShowing && !system.isLockClosed)
    }

    @Test func theSettingKeepsTheOpenLockFromAnotherApp() {
        model.joinScope = .sameApp
        partner.owner = 41
        system.movePointer(to: Self.nearSeam)
        #expect(!system.isLockShowing)
    }

    @Test func aClickOnTheOpenLockIsWithheldAndTakesNoPicture() {
        system.movePointer(to: Self.onLock)
        #expect(!system.send(.pressed(Self.onLock)))
        #expect(!system.send(.released(Self.onLock)))
        #expect(system.standInRequests == 0)
    }

    @Test func aClickOnTheOpenLockJoinsOnTheNextTickAndNotOnTheEvent() {
        system.movePointer(to: Self.onLock)
        _ = system.send(.pressed(Self.onLock))
        _ = system.send(.released(Self.onLock))
        #expect(system.seamFlashes.isEmpty)
        system.tick()
        #expect(system.seamFlashes.count == 1)
        #expect(!system.isTicking)
    }

    @Test func aClickOnTheOpenLockTurnsItClosed() {
        clickOpenLock()
        #expect(system.isLockShowing && system.isLockClosed)
    }

    @Test func aClickOnTheOpenLockMakesAPairThatDragsTogether() {
        clickOpenLock()
        _ = system.send(.pressed(Self.far))
        #expect(system.standInRequests == 1)
    }

    @Test func levelWindowsDoNotMoveWhenTheyJoin() {
        clickOpenLock()
        #expect(window.moves.isEmpty && partner.moves.isEmpty)
    }

    @Test func theWindowFurtherBackTakesTheTopOfTheOneInFront() {
        partner.currentFrame.origin.y = 130
        clickOpenLock(at: Self.onLowerLock)
        #expect(partner.moves == [ScreenPoint(x: 500, y: 100)])
        #expect(window.moves.isEmpty)
    }

    @Test func aWindowInFrontOnTheRightKeepsItsPlace() {
        system.knownWindows = [partner, window]
        window.currentFrame.origin.y = 130
        clickOpenLock(at: Self.onLowerLock)
        #expect(window.moves == [ScreenPoint(x: 100, y: 100)])
        #expect(partner.moves.isEmpty)
    }

    @Test func aRefusedMoveJoinsNothing() {
        partner.currentFrame.origin.y = 130
        partner.moveError = .windowRefused
        clickOpenLock(at: Self.onLowerLock)
        #expect(system.seamFlashes.isEmpty)
        _ = system.send(.pressed(Self.far))
        #expect(system.standInRequests == 0)
    }

    @Test func aLockClickedOpenCanBeClickedClosedAgain() throws {
        try model.join(window, to: partner, on: .left)
        system.movePointer(to: Self.onLock)
        _ = system.send(.pressed(Self.onLock))
        _ = system.send(.released(Self.onLock))
        clickOpenLock()
        #expect(system.isLockClosed)
    }
}
