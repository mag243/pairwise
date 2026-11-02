import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

/// The lock on a seam, to click to end a pair (ADR 0042).
@MainActor
@Suite struct PairDragModelSeamLockTests {
    private static let nearSeam = ScreenPoint(x: 505, y: 200)
    private static let onLock = ScreenPoint(x: 500, y: 200)
    private static let far = ScreenPoint(x: 150, y: 200)
    private static let lockFrame = WindowFrame(x: 486, y: 186, width: 28, height: 28)
    private static let start = ScreenPoint(x: 100, y: 100)

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

    private func joinWindows() throws {
        try model.join(window, to: partner, on: .left)
    }

    private func showLock() throws {
        try joinWindows()
        system.movePointer(to: Self.nearSeam)
    }

    @Test func noPairMeansThePointerIsNotWatched() {
        #expect(!system.isWatchingPointer)
    }

    @Test func aPairHasThePointerWatched() throws {
        try joinWindows()
        #expect(system.isWatchingPointer)
    }

    @Test func theLastPairEndingStopsTheWatching() throws {
        try joinWindows()
        model.leavePair(of: window)
        #expect(!system.isWatchingPointer)
    }

    @Test func stoppingEndsTheWatchingAndRestartingBringsItBack() throws {
        try showLock()
        model.stop()
        #expect(!system.isWatchingPointer)
        #expect(!system.isLockShowing)
        model.start()
        #expect(system.isWatchingPointer)
    }

    @Test func thePointerNearASeamShowsTheLock() throws {
        try showLock()
        #expect(system.isLockShowing)
        #expect(system.lockFrames.last == Self.lockFrame)
    }

    @Test func thePointerLeavingTakesTheLockAway() throws {
        try showLock()
        system.movePointer(to: Self.far)
        #expect(!system.isLockShowing)
    }

    @Test func aStillPointerDoesNotAskForTheWindows() throws {
        try joinWindows()
        system.movePointer(to: Self.far)
        let asked = system.normalWindowsRequests
        system.movePointer(to: Self.far)
        #expect(system.normalWindowsRequests == asked)
    }

    @Test func aWindowLeavingUnderAStillPointerTakesTheLockAway() throws {
        try showLock()
        system.knownWindows = [window]
        system.movePointer(to: Self.nearSeam)
        #expect(!system.isLockShowing)
    }

    @Test func noLockShowsWhileTheButtonIsDown() throws {
        try joinWindows()
        system.isPrimaryButtonDown = true
        system.movePointer(to: Self.nearSeam)
        #expect(!system.isLockShowing)
    }

    @Test func theLockComesBackWithAStillPointerAfterTheButton() throws {
        try joinWindows()
        system.isPrimaryButtonDown = true
        system.movePointer(to: Self.nearSeam)
        system.isPrimaryButtonDown = false
        system.movePointer(to: Self.nearSeam)
        #expect(system.isLockShowing)
    }

    @Test func noLockShowsDuringADrag() throws {
        try joinWindows()
        _ = system.send(.pressed(Self.far))
        system.isPrimaryButtonDown = false
        system.movePointer(to: Self.nearSeam)
        #expect(!system.isLockShowing)
    }

    @Test func aPressElsewhereTakesTheLockAwayAndPasses() throws {
        try showLock()
        #expect(system.send(.pressed(Self.far)))
        #expect(!system.isLockShowing)
    }

    @Test func aPressOnThePlaceWithNoLockShowingIsAPressOnTheWindow() throws {
        try joinWindows()
        #expect(system.send(.pressed(Self.onLock)))
        #expect(system.standInRequests == 1)
    }

    @Test func aClickOnTheLockIsWithheldAndTakesNoPicture() throws {
        try showLock()
        #expect(!system.send(.pressed(Self.onLock)))
        #expect(!system.send(.dragged(Self.onLock)))
        #expect(!system.send(.released(Self.onLock)))
        #expect(system.standInRequests == 0)
    }

    @Test func aClickOnTheLockEndsThePairAndMovesNothing() throws {
        try showLock()
        _ = system.send(.pressed(Self.onLock))
        _ = system.send(.released(Self.onLock))
        #expect(!system.isWatchingPointer)
        #expect(window.moves.isEmpty && partner.moves.isEmpty)
        #expect(window.resizes.isEmpty && partner.resizes.isEmpty)
    }

    @Test func aClickOnTheLockOpensItAndTakesItAway() throws {
        try showLock()
        _ = system.send(.pressed(Self.onLock))
        _ = system.send(.released(Self.onLock))
        #expect(system.openedLocks == [Self.lockFrame])
        #expect(!system.isLockShowing)
    }

    @Test func aReleaseAwayFromTheLockCancelsAndIsWithheld() throws {
        try showLock()
        _ = system.send(.pressed(Self.onLock))
        #expect(!system.send(.released(Self.far)))
        #expect(system.isWatchingPointer)
        #expect(system.openedLocks.isEmpty)
    }

    @Test func aDragAfterACancelledClickIsAPairDragAgain() throws {
        try showLock()
        _ = system.send(.pressed(Self.onLock))
        _ = system.send(.released(Self.far))
        #expect(system.send(.pressed(Self.far)))
        #expect(system.standInRequests == 1)
    }

    @Test func thePairEndingAnotherWayTakesTheLockAway() throws {
        try showLock()
        model.leavePair(of: window)
        #expect(!system.isLockShowing)
    }
}
