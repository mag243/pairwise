import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

@MainActor
@Suite struct PairDragModelSettingsTests {
    private let system = FakeWindowSystem()
    private let model: PairDragModel

    init() {
        system.isScreenRecordingGranted = true
        model = PairDragModel(system: system)
    }

    @Test func requestingPermissionsGoesToTheSystem() {
        model.requestAccessibility()
        model.requestScreenRecording()
        #expect(system.accessibilityRequests == 1)
        #expect(system.screenRecordingRequests == 1)
    }

    @Test func aGrantIsSeenOnRefresh() {
        system.isScreenRecordingGranted = false
        system.isAccessibilityGranted = false
        let waiting = PairDragModel(system: system)
        #expect(!waiting.isAccessibilityGranted)
        system.isAccessibilityGranted = true
        system.isScreenRecordingGranted = true
        waiting.refreshPermissions()
        #expect(waiting.isAccessibilityGranted)
        #expect(waiting.isScreenRecordingGranted)
    }

    @Test func withoutAccessibilityNothingIsTakenOver() {
        model.stop()
        system.isAccessibilityGranted = false
        model.start()
        #expect(model.problem == .accessibilityDenied)
        #expect(!system.isHolding)
    }

    @Test func aFailingTapIsReported() {
        model.stop()
        system.watchError = .eventTapUnavailable
        model.start()
        #expect(model.problem == .eventTapUnavailable)
        #expect(!model.isRunning)
    }

    @Test func theSystemsPartnerAppIsTheFirstChoice() {
        system.partnerBundleIdentifier = "com.example.first"
        #expect(PairDragModel(system: system).partnerBundleIdentifier == "com.example.first")
    }

    @Test func choosingAPartnerAppGoesToTheSystem() {
        model.partnerBundleIdentifier = "com.example.slow"
        #expect(system.partnerBundleIdentifier == "com.example.slow")
    }

    @Test func theSystemsFrameRateIsTheFirstChoice() {
        system.liveFramesPerSecond = 15
        #expect(PairDragModel(system: system).liveFramesPerSecond == 15)
    }

    @Test func choosingAFrameRateGoesToTheSystem() {
        model.liveFramesPerSecond = 60
        #expect(system.liveFramesPerSecond == 60)
    }

    @Test func newlyRunningAppsAreSeenOnRefresh() {
        let app = PartnerApp(bundleIdentifier: "com.example.slow", name: "Slow")
        system.partnerApps = [app]
        model.refreshPermissions()
        #expect(model.partnerApps == [app])
    }
}
