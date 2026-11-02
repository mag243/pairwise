import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

@MainActor
@Suite struct PairDragModelPermissionsTests {
    private let system = FakeWindowSystem()

    private func waitingModel() -> PairDragModel {
        system.isAccessibilityGranted = false
        system.isScreenRecordingGranted = false
        let model = PairDragModel(system: system)
        model.startWhenPermitted()
        return model
    }

    private func runningModel() -> PairDragModel {
        system.isAccessibilityGranted = true
        system.isScreenRecordingGranted = true
        let model = PairDragModel(system: system)
        model.startWhenPermitted()
        return model
    }

    @Test func startsAtOnceWhenBothAreGiven() {
        #expect(runningModel().isRunning)
    }

    @Test func aNewUserSeesNoProblemWhileWaiting() {
        let model = waitingModel()
        #expect(!model.isRunning)
        #expect(model.problem == nil)
    }

    @Test func staysWaitingWhileOneIsMissing() {
        let model = waitingModel()
        system.isAccessibilityGranted = true
        model.followPermissions()
        #expect(model.isAccessibilityGranted)
        #expect(!model.isRunning)
        #expect(!system.isHolding)
    }

    @Test func startsWhenTheLastOneIsGiven() {
        let model = waitingModel()
        system.isAccessibilityGranted = true
        system.isScreenRecordingGranted = true
        model.followPermissions()
        #expect(model.isRunning)
        #expect(system.isHolding)
    }

    @Test(arguments: [true, false])
    func stopsWhenOneIsTakenAway(accessibilityStays: Bool) {
        let model = runningModel()
        system.isAccessibilityGranted = accessibilityStays
        system.isScreenRecordingGranted = !accessibilityStays
        model.followPermissions()
        #expect(!model.isRunning)
        #expect(!system.isHolding)
        #expect(model.problem != nil)
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
        system.isScreenRecordingGranted = true
        let model = PairDragModel(system: system)
        model.start()
        #expect(model.problem == .accessibilityDenied)
        system.isAccessibilityGranted = true
        model.followPermissions()
        #expect(model.isRunning)
    }
}
