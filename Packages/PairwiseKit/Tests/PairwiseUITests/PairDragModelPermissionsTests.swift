import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

@MainActor
@Suite struct PairDragModelPermissionsTests {
    private let system = FakeWindowSystem()

    private func waitingModel() -> PairDragModel {
        system.isAccessibilityGranted = false
        let model = PairDragModel(system: system)
        model.startWhenPermitted()
        return model
    }

    private func runningModel() -> PairDragModel {
        system.isAccessibilityGranted = true
        let model = PairDragModel(system: system)
        model.startWhenPermitted()
        return model
    }

    @Test func startsAtOnceWithAccessibilityAlone() {
        system.isScreenRecordingGranted = false
        #expect(runningModel().isRunning)
    }

    @Test func aNewUserSeesNoProblemWhileWaiting() {
        let model = waitingModel()
        #expect(!model.isRunning)
        #expect(model.problem == nil)
    }

    @Test func screenRecordingAloneIsNotEnough() {
        let model = waitingModel()
        system.isScreenRecordingGranted = true
        model.followPermissions()
        #expect(model.isScreenRecordingGranted)
        #expect(!model.isRunning)
        #expect(!system.isHolding)
    }

    @Test func startsWhenAccessibilityIsGiven() {
        let model = waitingModel()
        system.isAccessibilityGranted = true
        model.followPermissions()
        #expect(model.isRunning)
        #expect(system.isHolding)
    }

    @Test func stopsWhenAccessibilityIsTakenAway() {
        let model = runningModel()
        system.isAccessibilityGranted = false
        model.followPermissions()
        #expect(!model.isRunning)
        #expect(!system.isHolding)
        #expect(model.problem == .accessibilityDenied)
    }

    @Test func goesOnWhenScreenRecordingIsTakenAway() {
        system.isScreenRecordingGranted = true
        let model = runningModel()
        model.dragPictures = .live
        system.isScreenRecordingGranted = false
        model.followPermissions()
        #expect(model.isRunning)
        #expect(model.problem == nil)
        #expect(system.showsPlaceholders)
    }

    @Test func startsAgainWhenItIsGivenBack() {
        let model = runningModel()
        system.isAccessibilityGranted = false
        model.followPermissions()
        system.isAccessibilityGranted = true
        model.followPermissions()
        #expect(model.isRunning)
        #expect(model.problem == nil)
    }

    @Test func staysOffWhenTheUserTurnedItOff() {
        let model = runningModel()
        model.stop()
        model.followPermissions()
        #expect(!model.isRunning)
    }

    @Test func aTurnedOnSwitchWithoutPermissionWaitsToo() {
        system.isAccessibilityGranted = false
        let model = PairDragModel(system: system)
        model.start()
        #expect(model.problem == .accessibilityDenied)
        system.isAccessibilityGranted = true
        model.followPermissions()
        #expect(model.isRunning)
    }
}
