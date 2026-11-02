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

    @Test func theClosedLockIsOneMarkThatMoves() {
        system.showSeamLock(at: Self.frame)
        system.showSeamLock(at: Self.frame)
        #expect(markBox.locks.count == 1)
        #expect(markBox.locks.first?.closedFrames.count == 2)
    }

    @Test func hidingTheLockTakesItAway() {
        system.showSeamLock(at: Self.frame)
        system.hideSeamLock()
        #expect(markBox.locks.first?.isHidden == true)
    }

    @Test func anOpenLockIsAMarkOfItsOwn() {
        system.showSeamLock(at: Self.frame)
        system.hideSeamLock()
        system.flashOpenSeamLock(at: Self.frame)
        #expect(markBox.locks.count == 2)
        #expect(markBox.locks.last?.openFrames == [Self.frame])
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
    private(set) var closedFrames: [WindowFrame] = []
    private(set) var openFrames: [WindowFrame] = []
    private(set) var isHidden = false

    func showClosed(at frame: WindowFrame) {
        closedFrames.append(frame)
    }

    func showOpen(at frame: WindowFrame) {
        openFrames.append(frame)
    }

    func hide() {
        isHidden = true
    }
}
