import Foundation
import PairwiseCore
import Testing

@testable import PairwiseWindowSystem

@MainActor
@Suite struct SystemHoldAndMarkTests {
    private static let frame = WindowFrame(x: 1, y: 2, width: 3, height: 4)

    private var holds: [FakeHold] { holdBox.holds }
    private var marks: [FakeMark] { markBox.marks }

    private final class HoldBox {
        var holds: [FakeHold] = []
        var startError: WindowSystemError?
    }

    private final class MarkBox {
        var marks: [FakeMark] = []
        var locks: [FakeLockMark] = []
    }

    private let holdBox = HoldBox()
    private let markBox = MarkBox()
    private let system: AccessibilityWindowSystem

    init() {
        let holdBox = self.holdBox
        let markBox = self.markBox
        system = AccessibilityWindowSystem(
            access: FakeSystemAccess(), captureService: FakeCaptureService(),
            makeMark: {
                let mark = FakeMark()
                markBox.marks.append(mark)
                return mark
            },
            makeLock: {
                let lock = FakeLockMark()
                markBox.locks.append(lock)
                return lock
            },
            makeHold: { _ in
                let hold = FakeHold()
                hold.startError = holdBox.startError
                holdBox.holds.append(hold)
                return hold
            })
    }

    @Test func holdingInstallsATap() throws {
        try system.startHoldingDrags { _ in true }
        #expect(holds.first?.starts == 1)
    }

    @Test func holdingAgainEndsTheEarlierHold() throws {
        try system.startHoldingDrags { _ in true }
        try system.startHoldingDrags { _ in true }
        #expect(holds.first?.stops == 1)
    }

    @Test func stoppingRemovesTheTap() throws {
        try system.startHoldingDrags { _ in true }
        system.stopHoldingDrags()
        #expect(holds.first?.stops == 1)
    }

    @Test func aTapThatFailsSaysWhy() {
        holdBox.startError = .eventTapUnavailable
        #expect(throws: WindowSystemError.eventTapUnavailable) {
            try system.startHoldingDrags { _ in true }
        }
    }

    @Test func theGuideIsOneMarkThatMoves() {
        system.showJoinGuide(at: Self.frame)
        system.showJoinGuide(at: Self.frame)
        #expect(marks.count == 1)
        #expect(marks.first?.frames.count == 2)
    }

    @Test func hidingTheGuideTakesItAway() {
        system.showJoinGuide(at: Self.frame)
        system.hideJoinGuide()
        #expect(marks.first?.isHidden == true)
    }

    @Test func aHiddenGuideComesBackAsANewMark() {
        system.showJoinGuide(at: Self.frame)
        system.hideJoinGuide()
        system.showJoinGuide(at: Self.frame)
        #expect(marks.count == 2)
    }

    @Test func theLockIsOneMarkThatChanges() {
        system.showSeamLock(at: Self.frame, isClosed: true)
        system.showSeamLock(at: Self.frame, isClosed: false)
        #expect(markBox.locks.count == 1)
        #expect(markBox.locks.first?.states == [true, false])
    }

    @Test func hidingTheLockTakesItAway() {
        system.showSeamLock(at: Self.frame, isClosed: true)
        system.hideSeamLock()
        #expect(markBox.locks.first?.isHidden == true)
    }

    @Test func aSeamLightsUpOnAMarkOfItsOwn() {
        system.showJoinGuide(at: Self.frame)
        system.flashSeam(at: Self.frame)
        #expect(marks.count == 2)
        #expect(marks.last?.frames == [Self.frame])
    }
}

@MainActor
private final class FakeLockMark: SeamLockMark {
    private(set) var states: [Bool] = []
    private(set) var isHidden = false

    func show(at frame: WindowFrame, isClosed: Bool) {
        states.append(isClosed)
    }

    func hide() {
        isHidden = true
    }
}

@MainActor
@Suite struct ParkingRecordFileTests {
    private let folder = FileManager.default.temporaryDirectory
        .appending(path: "PairwiseTests-\(UUID().uuidString)", directoryHint: .isDirectory)

    private func system() -> AccessibilityWindowSystem {
        AccessibilityWindowSystem(
            access: FakeSystemAccess(), captureService: FakeCaptureService(),
            recordsFolder: folder)
    }

    @Test func aRecordSurvivesInANewSystem() {
        defer { try? FileManager.default.removeItem(at: folder) }
        system().saveParkingRecord(Data("record".utf8))
        #expect(system().loadParkingRecord() == Data("record".utf8))
    }

    @Test func nilRemovesTheRecord() {
        defer { try? FileManager.default.removeItem(at: folder) }
        let system = system()
        system.saveParkingRecord(Data("record".utf8))
        system.saveParkingRecord(nil)
        #expect(system.loadParkingRecord() == nil)
    }

    @Test func aPairsRecordSurvivesInANewSystemApartFromTheParkingRecord() {
        defer { try? FileManager.default.removeItem(at: folder) }
        system().savePairsRecord(Data("pairs".utf8))
        system().saveParkingRecord(Data("parked".utf8))
        #expect(system().loadPairsRecord() == Data("pairs".utf8))
        #expect(system().loadParkingRecord() == Data("parked".utf8))
    }

    @Test func noRecordGivesNone() {
        #expect(system().loadParkingRecord() == nil)
    }
}
