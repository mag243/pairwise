import Foundation
import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

/// Not losing windows when Pairwise stops during a drag (ADR 0053).
@MainActor
@Suite struct PairDragModelParkingRecordTests {
    private static let press = ScreenPoint(x: 150, y: 110)
    private static let further = ScreenPoint(x: 190, y: 140)
    private static let moved = ScreenPoint(x: 140, y: 130)
    private static let leftStart = WindowFrame(x: 100, y: 100, width: 400, height: 300)
    private static let rightStart = WindowFrame(x: 500, y: 100, width: 200, height: 200)

    private let system = FakeWindowSystem()
    private let panel = FakeStandIn()
    private let left = FakeWindow(frame: leftStart, number: 1)
    private let right = FakeWindow(frame: rightStart, number: 2)
    private let model: PairDragModel

    init() throws {
        left.owner = 40
        right.owner = 41
        system.isScreenRecordingGranted = true
        system.windowUnderPointer = left
        system.knownWindows = [left, right]
        model = PairDragModel(system: system)
        model.start()
        try model.join(left, to: right, on: .left)
    }

    private var record: ParkingRecord? {
        system.parkingRecord.flatMap(ParkingRecord.init(data:))
    }

    /// Presses, lets the panel take over, and goes up to `ticks` ticks into parking.
    private func startDrag(ticks: Int = 2) {
        _ = system.send(.pressed(Self.press))
        system.finishStandIn(with: .success(panel))
        _ = system.send(.dragged(Self.further))
        left.currentFrame.origin = Self.moved
        for _ in 0..<ticks { system.tick() }
    }

    @Test func theRecordIsWrittenBeforeAWindowLeaves() {
        var seenFirstMove: Data?
        left.duringMove = { seenFirstMove = seenFirstMove ?? system.parkingRecord }
        startDrag()
        #expect(seenFirstMove != nil)
    }

    @Test func theRecordSaysWhereBothWindowsBelong() {
        startDrag()
        #expect(
            record?.windows == [
                ParkedWindow(number: 1, owner: 40, frame: Self.leftStart),
                ParkedWindow(number: 2, owner: 41, frame: Self.rightStart),
            ])
    }

    @Test func aClickWritesNoRecord() {
        _ = system.send(.pressed(Self.press))
        system.finishStandIn(with: .success(panel))
        _ = system.send(.released(Self.press))
        #expect(system.parkingRecord == nil)
    }

    @Test func theReleaseForgetsTheRecordOnceTheWindowsAreBack() {
        startDrag()
        _ = system.send(.released(Self.further))
        #expect(system.parkingRecord == nil)
        #expect(left.moves.last != system.parkingOrigin)
    }

    @Test func aWindowThatStaysBusyKeepsTheRecord() {
        startDrag()
        left.moveError = .windowBusy
        _ = system.send(.released(Self.further))
        #expect(system.parkingRecord != nil)
    }

    @Test func partingForgetsTheRecord() {
        startDrag()
        system.isJoinKeyDown = true
        _ = system.send(.dragged(Self.further))
        system.tick()
        #expect(system.parkingRecord == nil)
    }

    @Test func stoppingForgetsTheRecord() {
        startDrag()
        model.stop()
        #expect(system.parkingRecord == nil)
    }

    @Test func aResizeAtTheSeamWritesAndForgetsTheRecord() {
        _ = system.send(.pressed(Self.press))
        system.finishStandIn(with: .success(panel))
        left.currentFrame.size.width += 10
        system.tick()
        system.tick()
        #expect(record?.windows.count == 2)
        _ = system.send(.released(Self.press))
        system.tick()
        #expect(system.parkingRecord == nil)
    }

    /// A new model, as after a crash, with the windows still parked.
    private func restart() -> PairDragModel {
        let parked = ScreenPoint(x: 9000, y: 9000)
        left.currentFrame.origin = parked
        right.currentFrame.origin = parked
        let next = PairDragModel(system: system)
        next.start()
        return next
    }

    @Test func aNewStartPutsParkedWindowsBack() {
        startDrag()
        left.currentFrame.size.width = 900
        _ = restart()
        #expect(left.currentFrame == Self.leftStart)
        #expect(right.currentFrame == Self.rightStart)
    }

    @Test func aNewStartForgetsTheRecord() {
        startDrag()
        _ = restart()
        #expect(system.parkingRecord == nil)
    }

    @Test func aRecordOfAnotherProcessMovesNothing() {
        startDrag()
        left.owner = 99
        _ = restart()
        #expect(left.currentFrame.origin.x == 9000)
        #expect(right.currentFrame == Self.rightStart)
    }

    @Test func aRecordThatCannotBeReadIsThrownAwayAndMovesNothing() {
        system.parkingRecord = Data("not a record".utf8)
        let moves = left.moves.count
        PairDragModel(system: system).start()
        #expect(system.parkingRecord == nil)
        #expect(left.moves.count == moves)
    }

    @Test func withoutThePermissionTheRecordStays() {
        startDrag()
        system.isAccessibilityGranted = false
        _ = restart()
        #expect(system.parkingRecord != nil)
        #expect(left.currentFrame.origin.x == 9000)
    }

    @Test func withoutScreenRecordingWindowsStillComeBack() {
        startDrag()
        system.isScreenRecordingGranted = false
        _ = restart()
        #expect(left.currentFrame == Self.leftStart)
    }
}
