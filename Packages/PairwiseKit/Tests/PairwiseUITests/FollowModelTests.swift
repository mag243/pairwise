import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

@MainActor
@Suite struct FollowModelTests {
    private static let start = WindowFrame(x: 100, y: 100, width: 400, height: 300)
    private static let grab = ScreenPoint(x: 150, y: 110)

    private let system = FakeWindowSystem()
    private let dragged = FakeWindow(frame: Self.start)
    private let partner = FakeWindow(frame: WindowFrame(x: 0, y: 500, width: 200, height: 200))
    private let model: FollowModel

    init() {
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

    @Test func startWithoutPermissionReportsItAndDoesNotWatch() {
        system.isAccessibilityGranted = false
        let denied = FollowModel(system: system)
        denied.start()
        #expect(denied.problem == .accessibilityDenied)
        #expect(!system.isWatching)
    }

    @Test func aFailingTapIsReported() {
        system.watchError = .eventTapUnavailable
        model.start()
        #expect(model.problem == .eventTapUnavailable)
        #expect(!model.isWatching)
    }

    @Test func requestingAccessGoesToTheSystem() {
        model.requestAccessibility()
        #expect(system.accessibilityRequests == 1)
    }

    @Test func aGrantIsSeenOnRefresh() {
        system.isAccessibilityGranted = false
        let waiting = FollowModel(system: system)
        system.isAccessibilityGranted = true
        waiting.refreshPermission()
        #expect(waiting.isAccessibilityGranted)
    }

    @Test func aPressWithNoWindowDoesNotTick() {
        system.windowUnderPointer = nil
        model.start()
        system.press(at: Self.grab)
        #expect(!system.isTicking)
    }

    @Test func ticksRunOnlyWhileTheButtonIsDown() {
        model.start()
        #expect(!system.isTicking)
        system.press(at: Self.grab)
        #expect(system.isTicking)
        system.release(at: Self.grab)
        #expect(!system.isTicking)
    }

    @Test func aClickNeverMovesThePartner() {
        model.start()
        system.press(at: Self.grab)
        system.tick()
        system.release(at: Self.grab)
        #expect(partner.moves.isEmpty)
        #expect(model.lastDrag == nil)
    }

    @Test func aResizeNeverMovesThePartner() {
        model.start()
        system.press(at: Self.grab)
        dragged.currentFrame = WindowFrame(x: 90, y: 100, width: 410, height: 300)
        system.tick()
        system.tick()
        #expect(partner.moves.isEmpty)
    }

    @Test func thePartnerFollowsThePointerBesideTheWindow() {
        startDrag()
        system.pointerLocation = ScreenPoint(x: 250, y: 60)
        system.tick()
        #expect(partner.moves == [ScreenPoint(x: 600, y: 50)])
    }

    @Test func theReleasePlacesThePartnerFromTheRealFrame() {
        startDrag()
        dragged.currentFrame.origin = ScreenPoint(x: 300, y: 25)
        system.release(at: ScreenPoint(x: 350, y: 0))
        #expect(partner.moves.last == ScreenPoint(x: 700, y: 25))
    }

    @Test func theReleaseReportsTheMeasurements() throws {
        startDrag()
        partner.duringMove = { [system] in
            system.uptime += 0.002
            system.pointerLocation = ScreenPoint(x: 253, y: 64)
        }
        system.uptime = 1
        system.pointerLocation = ScreenPoint(x: 250, y: 60)
        system.tick()
        partner.duringMove = nil
        system.uptime = 1.5
        system.release(at: ScreenPoint(x: 250, y: 60))
        let report = try #require(model.lastDrag)
        #expect(report.moves == 1)
        #expect(report.meanPointsBehind == 5)
        #expect(abs(report.longestMove - 0.002) < 1e-9)
    }

    @Test func noPartnerIsReportedAndEndsTheDrag() {
        system.partnerWindow = nil
        startDrag()
        #expect(model.problem == .noPartner)
        #expect(!system.isTicking)
        #expect(model.isWatching)
    }

    @Test func aPartnerThatHasGoneEndsTheDrag() {
        startDrag()
        partner.moveError = .windowGone
        system.tick()
        #expect(model.problem == .windowGone)
        #expect(!system.isTicking)
    }

    @Test func aBusyPartnerIsTriedAgainOnTheNextTick() {
        startDrag()
        partner.moveError = .windowBusy
        system.tick()
        #expect(model.problem == nil)
        partner.moveError = nil
        system.tick()
        #expect(partner.moves.count == 1)
    }

    @Test func aBusyAppAtTheReleaseStillEndsTheDrag() {
        startDrag()
        partner.moveError = .windowBusy
        system.release(at: Self.grab)
        #expect(!system.isTicking)
        #expect(model.problem == .windowBusy)
    }

    @Test func aNewPressClearsTheLastProblem() {
        system.partnerWindow = nil
        startDrag()
        system.press(at: Self.grab)
        #expect(model.problem == nil)
    }

    @Test func stopEndsWatchingAndTicking() {
        startDrag()
        model.stop()
        #expect(!model.isWatching)
        #expect(!system.isWatching)
        #expect(!system.isTicking)
    }
}
