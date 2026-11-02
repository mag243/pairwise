import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

/// A pair that comes forward and minimizes as one window (ADR 0052).
@MainActor
@Suite struct PairDragModelTogetherTests {
    private static let far = ScreenPoint(x: 2000, y: 2000)
    private static let interval = 0.25

    private let system = FakeWindowSystem()
    private let left = FakeWindow(
        frame: WindowFrame(x: 100, y: 100, width: 400, height: 200), number: 1)
    private let right = FakeWindow(
        frame: WindowFrame(x: 500, y: 100, width: 200, height: 200), number: 2)
    private let other = FakeWindow(
        frame: WindowFrame(x: 0, y: 0, width: 50, height: 50), number: 3)
    private let model: PairDragModel

    init() throws {
        system.isScreenRecordingGranted = true
        system.isPrimaryButtonDown = false
        system.knownWindows = [left, right, other]
        model = PairDragModel(system: system)
        model.start()
        try model.join(left, to: right, on: .left)
    }

    private func look() {
        system.uptime += Self.interval
        system.movePointer(to: Self.far)
    }

    @Test func aFrontWindowBringsItsPartnerAndStaysOnTop() {
        var order: [String] = []
        left.duringRaise = { order.append("left") }
        right.duringRaise = { order.append("right") }
        system.knownWindows = [left, other, right]
        look()
        #expect(order == ["right", "left"])
    }

    @Test func thePartnerComesForwardOncePerChange() {
        system.knownWindows = [left, other, right]
        look()
        look()
        #expect(right.raises == 1)
    }

    @Test func comingForwardAgainBringsThePartnerAgain() {
        system.knownWindows = [left, other, right]
        look()
        system.knownWindows = [other, left, right]
        look()
        system.knownWindows = [left, other, right]
        look()
        #expect(right.raises == 2)
    }

    @Test func anotherWindowInFrontLeavesThePairAlone() {
        system.knownWindows = [other, left, right]
        look()
        #expect(left.raises == 0 && right.raises == 0)
    }

    @Test func noLookComesBeforeItsTime() {
        system.knownWindows = [left, other, right]
        system.uptime += Self.interval / 2
        system.movePointer(to: Self.far)
        #expect(right.raises == 0)
    }

    @Test func noLookComesWithTheButtonDown() {
        system.knownWindows = [left, other, right]
        system.isPrimaryButtonDown = true
        look()
        #expect(right.raises == 0)
    }

    @Test func noLookComesDuringADrag() {
        system.windowUnderPointer = left
        system.isPrimaryButtonDown = true
        _ = system.send(.pressed(ScreenPoint(x: 150, y: 110)))
        system.isPrimaryButtonDown = false
        system.knownWindows = [left, other, right]
        look()
        #expect(right.raises == 0)
    }

    @Test func minimizingOneMinimizesTheOther() {
        left.isMinimized = true
        system.knownWindows = [right, other]
        look()
        #expect(right.minimizeRequests == [true])
    }

    @Test func aWindowStillOnTheListWhileItMinimizesIsNotBroughtBack() {
        left.isMinimized = true
        system.knownWindows = [right, other]
        look()
        look()
        #expect(!right.minimizeRequests.contains(false))
        #expect(left.minimizeRequests.isEmpty)
    }

    @Test func bringingOneBackBringsTheOther() {
        left.isMinimized = true
        system.knownWindows = [right, other]
        look()
        system.knownWindows = [other]
        look()
        left.isMinimized = false
        system.knownWindows = [left, other]
        look()
        #expect(right.minimizeRequests.last == false)
    }

    @Test func thePairGoesOnAfterComingBack() {
        left.isMinimized = true
        system.knownWindows = [other]
        right.isMinimized = true
        look()
        left.isMinimized = false
        right.isMinimized = false
        system.knownWindows = [left, right, other]
        look()
        left.isMinimized = true
        system.knownWindows = [right, other]
        look()
        #expect(right.minimizeRequests == [true])
    }

    @Test func aWindowThatHasGoneEndsThePairWithoutMovingTheOther() {
        left.isAvailable = false
        system.knownWindows = [right, other]
        look()
        system.windowUnderPointer = right
        system.isPrimaryButtonDown = true
        _ = system.send(.pressed(ScreenPoint(x: 600, y: 110)))
        #expect(system.standInRequests == 0)
        #expect(right.moves.isEmpty && right.minimizeRequests.isEmpty)
        #expect(system.sounds.isEmpty)
    }

    @Test func aWindowOnAnotherSpaceLeavesThePair() {
        system.knownWindows = [right, other]
        look()
        system.windowUnderPointer = right
        system.isPrimaryButtonDown = true
        _ = system.send(.pressed(ScreenPoint(x: 600, y: 110)))
        #expect(system.standInRequests == 1)
        #expect(right.minimizeRequests.isEmpty)
    }

    @Test func noPairReadsNoWindowListForThis() {
        model.leavePair(of: left)
        system.movePointer(to: Self.far)
        let asked = system.normalWindowsRequests
        system.uptime += Self.interval
        system.movePointer(to: Self.far)
        #expect(system.normalWindowsRequests == asked)
    }
}
