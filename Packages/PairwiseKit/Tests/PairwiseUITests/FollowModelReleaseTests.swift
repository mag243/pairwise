import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

@MainActor
@Suite struct FollowModelReleaseTests {
    private static let start = WindowFrame(x: 100, y: 100, width: 400, height: 300)
    private static let grab = ScreenPoint(x: 150, y: 110)
    private static let pointer = ScreenPoint(x: 250, y: 60)

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
        model.standInHoldBack = 0
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

    @Test func thePartnerIsRaisedBeforeTheStandInComesDown() {
        startDragWithStandIn()
        system.tick()
        var dismissedAtRaise = true
        partner.duringRaise = { [standIn] in dismissedAtRaise = standIn.isDismissed }
        system.release(at: Self.pointer)
        #expect(partner.raises == 1)
        #expect(!dismissedAtRaise)
        #expect(standIn.isDismissed)
    }

    @Test func aPartnerThatCannotBeRaisedIsNotAProblem() {
        startDragWithStandIn()
        system.tick()
        partner.raiseError = .windowRefused
        system.release(at: Self.pointer)
        #expect(model.problem == nil)
        #expect(standIn.isDismissed)
    }

    @Test func aPartnerThatFollowedAsItselfIsRaisedToo() {
        system.isScreenRecordingGranted = false
        startDrag()
        system.release(at: Self.grab)
        #expect(partner.raises == 1)
    }

    @Test func aPartnerThatDidNotMoveAtTheReleaseIsNotRaised() {
        startDragWithStandIn()
        system.tick()
        partner.moveError = .windowGone
        system.release(at: Self.pointer)
        #expect(partner.raises == 0)
    }

    /// Holds the pointer still for longer than the grip check waits, with ticks.
    private func holdStill() {
        system.tick()
        system.uptime += 0.2
        system.tick()
    }

    @Test func aStillPointerMeasuresTheGripAgainstTheRealWindow() throws {
        startDrag()
        system.pointerLocation = Self.pointer
        dragged.currentFrame.origin = ScreenPoint(x: 203, y: 54)
        holdStill()
        system.release(at: Self.pointer)
        #expect(try #require(model.lastDrag).gripOffset == 5)
    }

    @Test func theLargestOffsetIsReported() throws {
        startDrag()
        system.pointerLocation = Self.pointer
        dragged.currentFrame.origin = ScreenPoint(x: 203, y: 54)
        holdStill()
        system.pointerLocation = ScreenPoint(x: 350, y: 60)
        dragged.currentFrame.origin = ScreenPoint(x: 300, y: 50)
        holdStill()
        system.release(at: ScreenPoint(x: 350, y: 60))
        #expect(try #require(model.lastDrag).gripOffset == 5)
    }

    @Test func aDragWithoutAPauseHasNoGripOffset() throws {
        startDrag()
        system.pointerLocation = Self.pointer
        system.tick()
        system.uptime = 1
        system.release(at: Self.pointer)
        #expect(try #require(model.lastDrag).gripOffset == nil)
    }

    @Test func aDraggedWindowThatHasGoneLeavesNoGripOffset() throws {
        startDrag()
        system.pointerLocation = Self.pointer
        dragged.frameError = .windowGone
        holdStill()
        system.release(at: Self.pointer)
        #expect(try #require(model.lastDrag).gripOffset == nil)
    }
}
