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

    @Test func placeholdersAreWhatAUserWhoHasNotChosenGets() {
        #expect(model.dragPictures == .placeholder)
        #expect(system.showsPlaceholders)
    }

    @Test func liveReachesTheSystem() {
        model.dragPictures = .live
        #expect(!system.showsPlaceholders)
        #expect(system.liveFramesPerSecond == DragPictures.live.framesPerSecond)
    }

    @Test func withoutThePermissionLiveFallsBackOnPlaceholders() {
        system.isScreenRecordingGranted = false
        model.refreshPermissions()
        model.dragPictures = .live
        #expect(system.showsPlaceholders)
        #expect(system.liveFramesPerSecond == 0)
    }

    @Test func aGrantedPermissionTurnsTheChoiceOnWithoutARestart() {
        system.isScreenRecordingGranted = false
        model.refreshPermissions()
        model.dragPictures = .live
        system.isScreenRecordingGranted = true
        model.followPermissions()
        #expect(!system.showsPlaceholders)
        #expect(system.liveFramesPerSecond == DragPictures.live.framesPerSecond)
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

    @Test func theStandardChoiceSetsTheFrameRateWhateverTheSystemHad() {
        system.liveFramesPerSecond = 15
        #expect(PairDragModel(system: system).liveFramesPerSecond == 0)
        #expect(system.liveFramesPerSecond == 0)
    }

    @Test func choosingAFrameRateGoesToTheSystem() {
        model.liveFramesPerSecond = 60
        #expect(system.liveFramesPerSecond == 60)
    }
}
