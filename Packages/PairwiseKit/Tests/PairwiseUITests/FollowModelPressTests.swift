import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

@MainActor
@Suite struct FollowModelPressTests {
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
        model = FollowModel(system: system)
    }

    @Test func aPressAsksForTheStandInBeforeTheDragIsSeen() {
        model.start()
        system.press(at: Self.grab)
        #expect(system.standInRequests == 1)
    }

    @Test func aClicksPictureIsNeverShown() {
        model.start()
        system.press(at: Self.grab)
        system.finishStandIn(with: .success(standIn))
        system.tick()
        system.release(at: Self.grab)
        #expect(standIn.shownAt == nil)
    }

    @Test func aPictureFromThePressShowsAsSoonAsTheDragIsSeen() {
        model.start()
        system.press(at: Self.grab)
        system.finishStandIn(with: .success(standIn))
        dragged.currentFrame.origin = ScreenPoint(x: 101, y: 100)
        system.tick()
        #expect(standIn.shownAt == ScreenPoint(x: 500, y: 100))
    }

    @Test func aPictureFromThePressHasNoDelay() throws {
        model.start()
        system.press(at: Self.grab)
        system.finishStandIn(with: .success(standIn))
        dragged.currentFrame.origin = ScreenPoint(x: 101, y: 100)
        system.tick()
        system.tick()
        system.uptime = 1
        system.release(at: Self.grab)
        #expect(try #require(model.lastDrag).standInDelay == 0)
    }

    @Test func aPictureThatFailedAtThePressIsReportedWhenTheDragIsSeen() {
        model.start()
        system.press(at: Self.grab)
        system.finishStandIn(with: .failure(.captureFailed))
        #expect(model.problem == nil)
        dragged.currentFrame.origin = ScreenPoint(x: 101, y: 100)
        system.tick()
        #expect(model.problem == .captureFailed)
    }

    @Test func aPressWithoutAPartnerIsNoProblemUntilADrag() {
        system.partnerWindow = nil
        model.start()
        system.press(at: Self.grab)
        #expect(model.problem == nil)
        #expect(system.standInRequests == 0)
    }
}

@MainActor
@Suite struct FollowModelPartnerAppTests {
    private let system = FakeWindowSystem()

    @Test func theSystemsPartnerAppIsTheFirstChoice() {
        system.partnerBundleIdentifier = "com.example.first"
        #expect(FollowModel(system: system).partnerBundleIdentifier == "com.example.first")
    }

    @Test func choosingAPartnerAppGoesToTheSystem() {
        let model = FollowModel(system: system)
        model.partnerBundleIdentifier = "com.example.slow"
        #expect(system.partnerBundleIdentifier == "com.example.slow")
    }

    @Test func newlyRunningAppsAreSeenOnRefresh() {
        let model = FollowModel(system: system)
        let app = PartnerApp(bundleIdentifier: "com.example.slow", name: "Slow")
        system.partnerApps = [app]
        model.refreshPermission()
        #expect(model.partnerApps == [app])
    }
}
