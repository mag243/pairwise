import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

@MainActor
@Suite struct FollowModelStandInTests {
    private static let start = WindowFrame(x: 100, y: 100, width: 400, height: 300)
    private static let grab = ScreenPoint(x: 150, y: 110)
    private static let pointer = ScreenPoint(x: 250, y: 60)
    private static let besidePointer = ScreenPoint(x: 600, y: 50)
    private static let parked = ScreenPoint(x: 9999, y: 9999)

    private let system = FakeWindowSystem()
    private let dragged = FakeWindow(frame: Self.start)
    private let partner = FakeWindow(frame: WindowFrame(x: 0, y: 500, width: 200, height: 200))
    private let standIn = FakeStandIn()
    private let model: FollowModel

    init() {
        system.isScreenRecordingGranted = true
        system.windowUnderPointer = dragged
        system.partnerWindow = partner
        model = FollowModel(system: system)
    }

    /// Starts watching, presses on the window, and moves it so the drag is seen.
    private func startDrag() {
        model.start()
        system.press(at: Self.grab)
        dragged.currentFrame.origin = ScreenPoint(x: 101, y: 100)
        system.tick()
    }

    /// Starts a drag and lets the stand-in arrive, with the pointer moved along.
    private func startDragWithStandIn() {
        startDrag()
        system.pointerLocation = Self.pointer
        system.finishStandIn(with: .success(standIn))
    }

    @Test func aDragAsksForOneStandIn() {
        startDrag()
        system.tick()
        #expect(system.standInRequests == 1)
    }

    @Test func aClickAsksForNoStandIn() {
        model.start()
        system.press(at: Self.grab)
        system.tick()
        system.release(at: Self.grab)
        #expect(system.standInRequests == 0)
    }

    @Test func withoutTheScreenRecordingPermissionThePartnerFollowsAsItself() {
        system.isScreenRecordingGranted = false
        startDrag()
        system.pointerLocation = Self.pointer
        system.tick()
        #expect(system.standInRequests == 0)
        #expect(partner.moves == [Self.besidePointer])
    }

    @Test func untilThePictureArrivesThePartnerFollowsAsItself() {
        startDrag()
        system.pointerLocation = Self.pointer
        system.tick()
        #expect(partner.moves == [Self.besidePointer])
    }

    @Test func theStandInShowsWhereThePartnerBelongs() {
        startDragWithStandIn()
        #expect(standIn.shownAt == Self.besidePointer)
    }

    @Test func theStandInFollowsAndThePartnerIsParkedOnce() {
        startDragWithStandIn()
        system.tick()
        system.pointerLocation = ScreenPoint(x: 260, y: 60)
        system.tick()
        #expect(standIn.moves == [Self.besidePointer, ScreenPoint(x: 610, y: 50)])
        #expect(partner.moves == [Self.parked])
    }

    @Test func aBusyPartnerIsParkedOnALaterTick() {
        startDragWithStandIn()
        partner.moveError = .windowBusy
        system.tick()
        #expect(model.problem == nil)
        partner.moveError = nil
        system.tick()
        #expect(partner.moves == [Self.parked])
    }

    @Test func theReleasePutsThePartnerBackThenDismisses() {
        startDragWithStandIn()
        system.tick()
        dragged.currentFrame.origin = ScreenPoint(x: 300, y: 25)
        system.release(at: Self.pointer)
        #expect(partner.moves.last == ScreenPoint(x: 700, y: 25))
        #expect(standIn.isDismissed)
        #expect(!system.isTicking)
    }

    @Test func aBusyPartnerKeepsTheStandInUntilItAnswers() {
        startDragWithStandIn()
        system.tick()
        partner.moveError = .windowBusy
        system.release(at: Self.pointer)
        #expect(!standIn.isDismissed)
        #expect(system.isTicking)
        partner.moveError = nil
        system.tick()
        #expect(partner.moves.last == ScreenPoint(x: 501, y: 100))
        #expect(standIn.isDismissed)
        #expect(!system.isTicking)
        #expect(model.problem == nil)
    }

    @Test func aPartnerBusyTooLongIsReportedAndTheStandInComesDown() {
        startDragWithStandIn()
        system.tick()
        partner.moveError = .windowBusy
        system.release(at: Self.pointer)
        system.uptime += 1
        system.tick()
        #expect(standIn.isDismissed)
        #expect(!system.isTicking)
        #expect(model.problem == .windowBusy)
    }

    @Test func aPartnerThatHasGoneAtTheReleaseBringsTheStandInDown() {
        startDragWithStandIn()
        system.tick()
        partner.moveError = .windowGone
        system.release(at: Self.pointer)
        #expect(standIn.isDismissed)
        #expect(!system.isTicking)
        #expect(model.problem == .windowGone)
    }

    @Test func aDraggedWindowThatHasGoneStillGetsThePartnerBack() {
        startDragWithStandIn()
        system.tick()
        dragged.frameError = .windowGone
        system.release(at: Self.pointer)
        #expect(partner.moves.last == Self.besidePointer)
        #expect(standIn.isDismissed)
        #expect(model.problem == .windowGone)
    }

    @Test func aFailedPictureIsReportedAndThePartnerKeepsFollowing() {
        startDrag()
        system.pointerLocation = Self.pointer
        system.finishStandIn(with: .failure(.captureFailed))
        #expect(model.problem == .captureFailed)
        system.tick()
        #expect(partner.moves == [Self.besidePointer])
        #expect(system.isTicking)
    }

    @Test func aPictureAfterTheDragIsNeverShown() {
        startDrag()
        system.release(at: Self.grab)
        system.finishStandIn(with: .success(standIn))
        #expect(standIn.shownAt == nil)
    }

    @Test func aPictureFromAnEarlierDragIsNeverShown() {
        startDrag()
        system.release(at: Self.grab)
        let late = FakeStandIn()
        let completionOfFirstDrag = system.takeStandInCompletion()
        startDrag()
        completionOfFirstDrag?(.success(late))
        #expect(late.shownAt == nil)
    }

    @Test func stopDuringADragPutsThePartnerBack() {
        startDragWithStandIn()
        system.tick()
        model.stop()
        #expect(partner.moves.last == ScreenPoint(x: 501, y: 100))
        #expect(standIn.isDismissed)
    }

    @Test func aPressWhileThePartnerIsBusyPutsItBack() {
        startDragWithStandIn()
        system.tick()
        partner.moveError = .windowBusy
        system.release(at: Self.pointer)
        partner.moveError = nil
        system.press(at: Self.grab)
        #expect(partner.moves.last == ScreenPoint(x: 501, y: 100))
        #expect(standIn.isDismissed)
    }

    @Test func theReportMeasuresTheStandInAndItsDelay() throws {
        startDrag()
        system.uptime = 0.08
        system.pointerLocation = Self.pointer
        system.finishStandIn(with: .success(standIn))
        system.tick()
        system.uptime = 1.08
        system.release(at: Self.pointer)
        let report = try #require(model.lastDrag)
        #expect(report.moves == 1)
        #expect(report.movesPerSecond == 1)
        #expect(report.standInDelay == 0.08)
    }

    @Test func aDragWithoutAStandInReportsNoDelay() throws {
        startDrag()
        system.pointerLocation = Self.pointer
        system.tick()
        system.uptime = 1
        system.release(at: Self.pointer)
        #expect(try #require(model.lastDrag).standInDelay == nil)
    }

    @Test func requestingScreenRecordingGoesToTheSystem() {
        model.requestScreenRecording()
        #expect(system.screenRecordingRequests == 1)
    }

    @Test func aScreenRecordingGrantIsSeenOnRefresh() {
        system.isScreenRecordingGranted = false
        let waiting = FollowModel(system: system)
        #expect(!waiting.isScreenRecordingGranted)
        system.isScreenRecordingGranted = true
        waiting.refreshPermission()
        #expect(waiting.isScreenRecordingGranted)
    }
}
