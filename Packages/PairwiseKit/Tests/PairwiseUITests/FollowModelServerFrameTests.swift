import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

@MainActor
@Suite struct FollowModelServerFrameTests {
    private static let start = WindowFrame(x: 100, y: 100, width: 400, height: 300)
    private static let grab = ScreenPoint(x: 150, y: 110)

    private let system = FakeWindowSystem()
    private let dragged = FakeWindow(frame: Self.start)
    private let partner = FakeWindow(frame: WindowFrame(x: 0, y: 500, width: 200, height: 200))
    private let standIn = FakeStandIn()
    private let model: FollowModel

    init() {
        system.isScreenRecordingGranted = true
        system.windowUnderPointer = dragged
        system.partnerWindow = partner
        dragged.currentServerFrame = Self.start
        model = FollowModel(system: system)
        model.standInLookAhead = 0
    }

    private func moveWindow(toX x: Double, y: Double = 100) {
        dragged.currentServerFrame?.origin = ScreenPoint(x: x, y: y)
    }

    /// Starts watching, presses on the window, and moves it so the drag is seen, with the
    /// stand-in in place.
    private func startDragWithStandIn() {
        model.start()
        system.press(at: Self.grab)
        system.finishStandIn(with: .success(standIn))
        moveWindow(toX: 101)
        system.tick()
    }

    @Test func theWindowServerShowsTheDragBeforeTheAppDoes() {
        model.start()
        system.press(at: Self.grab)
        system.finishStandIn(with: .success(standIn))
        moveWindow(toX: 101)
        system.tick()
        #expect(standIn.shownAt == ScreenPoint(x: 501, y: 100))
    }

    @Test func theStandInFollowsTheWindowNotThePointer() {
        startDragWithStandIn()
        system.pointerLocation = ScreenPoint(x: 900, y: 900)
        moveWindow(toX: 120)
        system.tick()
        #expect(standIn.moves.last == ScreenPoint(x: 520, y: 100))
    }

    @Test func theStandInLooksAheadByThePointersMovement() {
        model.standInLookAhead = 0.016
        startDragWithStandIn()
        system.uptime = 0.1
        system.pointerLocation = ScreenPoint(x: 170, y: 110)
        system.tick()
        system.uptime = 0.11
        system.pointerLocation = ScreenPoint(x: 180, y: 110)
        system.tick()
        system.uptime = 0.12
        system.pointerLocation = ScreenPoint(x: 190, y: 110)
        moveWindow(toX: 110)
        system.tick()
        #expect(standIn.moves.last == ScreenPoint(x: 530, y: 100))
    }

    @Test func theStandInRestsExactlyBesideTheWindow() {
        model.standInLookAhead = 0.016
        startDragWithStandIn()
        system.uptime = 0.1
        system.pointerLocation = ScreenPoint(x: 170, y: 110)
        system.tick()
        moveWindow(toX: 120)
        system.uptime = 0.5
        system.tick()
        system.uptime = 0.6
        system.tick()
        #expect(standIn.moves.last == ScreenPoint(x: 520, y: 100))
    }

    @Test func thePartnerAsItselfDoesNotLookAhead() {
        system.isScreenRecordingGranted = false
        model.standInLookAhead = 0.016
        model.start()
        system.press(at: Self.grab)
        moveWindow(toX: 101)
        system.tick()
        system.pointerLocation = ScreenPoint(x: 170, y: 110)
        system.tick()
        system.uptime = 0.1
        system.pointerLocation = ScreenPoint(x: 190, y: 110)
        moveWindow(toX: 130)
        system.tick()
        #expect(partner.moves.last == ScreenPoint(x: 530, y: 100))
    }

    @Test func aWindowThatHangsHoldsTheStandInStill() {
        startDragWithStandIn()
        moveWindow(toX: 120)
        system.tick()
        let moves = standIn.moves.count
        system.pointerLocation = ScreenPoint(x: 900, y: 900)
        system.tick()
        system.tick()
        #expect(standIn.moves.count == moves)
    }

    @Test func thePartnerAsItselfFollowsTheWindowToo() {
        system.isScreenRecordingGranted = false
        model.start()
        system.press(at: Self.grab)
        moveWindow(toX: 101)
        system.tick()
        moveWindow(toX: 130)
        system.tick()
        #expect(partner.moves == [ScreenPoint(x: 530, y: 100)])
    }

    @Test func thePartnerIsStillParkedWhenTheWindowStandsStill() {
        startDragWithStandIn()
        system.tick()
        system.tick()
        #expect(partner.moves == [ScreenPoint(x: 9999, y: 9999)])
    }

    @Test func theReleasePlacesThePartnerFromTheWindowServersPlace() {
        startDragWithStandIn()
        system.tick()
        dragged.currentFrame.origin = ScreenPoint(x: 1, y: 1)
        moveWindow(toX: 300, y: 25)
        system.release(at: Self.grab)
        #expect(partner.moves.last == ScreenPoint(x: 700, y: 25))
    }

    @Test func theSlipIsTheLargestDistanceFromThePointersPlace() throws {
        startDragWithStandIn()
        system.pointerLocation = ScreenPoint(x: 250, y: 60)
        moveWindow(toX: 203, y: 54)
        system.tick()
        system.pointerLocation = ScreenPoint(x: 350, y: 60)
        moveWindow(toX: 300, y: 50)
        system.tick()
        system.uptime = 1
        system.release(at: ScreenPoint(x: 350, y: 60))
        #expect(try #require(model.lastDrag).mostSlip == 5)
    }

    @Test func withoutTheWindowServerThereIsNoSlip() throws {
        dragged.currentServerFrame = nil
        model.start()
        system.press(at: Self.grab)
        dragged.currentFrame.origin = ScreenPoint(x: 101, y: 100)
        system.tick()
        system.pointerLocation = ScreenPoint(x: 250, y: 60)
        system.tick()
        system.uptime = 1
        system.release(at: ScreenPoint(x: 250, y: 60))
        #expect(try #require(model.lastDrag).mostSlip == nil)
    }
}
