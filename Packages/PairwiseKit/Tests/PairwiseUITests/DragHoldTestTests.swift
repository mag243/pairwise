import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

@MainActor
@Suite struct DragHoldTestTests {
    private static let frame = WindowFrame(x: 100, y: 100, width: 400, height: 300)
    private static let onTitleBar = ScreenPoint(x: 150, y: 110)
    private static let inContent = ScreenPoint(x: 150, y: 300)
    private static let further = ScreenPoint(x: 190, y: 140)

    private let system = FakeWindowSystem()
    private let window = FakeWindow(frame: Self.frame)
    private let test: DragHoldTest

    init() {
        system.windowUnderPointer = window
        test = DragHoldTest(system: system)
        test.start()
    }

    @Test func aPressAndReleaseAlwaysPass() {
        #expect(system.send(.pressed(Self.onTitleBar)))
        #expect(system.send(.released(Self.onTitleBar)))
    }

    @Test func aDragFromTheTitleBarIsHeldBack() {
        _ = system.send(.pressed(Self.onTitleBar))
        #expect(!system.send(.dragged(Self.further)))
    }

    @Test func aDragFromTheContentPasses() {
        _ = system.send(.pressed(Self.inContent))
        #expect(system.send(.dragged(Self.further)))
    }

    @Test func aDragWithNoWindowPasses() {
        system.windowUnderPointer = nil
        _ = system.send(.pressed(Self.onTitleBar))
        #expect(system.send(.dragged(Self.further)))
    }

    @Test func aWindowThatDoesNotAnswerLetsTheDragPass() {
        window.frameError = .windowBusy
        _ = system.send(.pressed(Self.onTitleBar))
        #expect(system.send(.dragged(Self.further)))
    }

    @Test func aDragWithoutAPressPasses() {
        #expect(system.send(.dragged(Self.further)))
    }

    @Test func aDragHeldTooLongIsLetGo() {
        _ = system.send(.pressed(Self.onTitleBar))
        system.uptime = 5
        #expect(system.send(.dragged(Self.further)))
    }

    @Test func afterTheReleaseADragPasses() {
        _ = system.send(.pressed(Self.onTitleBar))
        _ = system.send(.released(Self.onTitleBar))
        #expect(system.send(.dragged(Self.further)))
    }

    @Test func aReportSaysWhatMoved() {
        _ = system.send(.pressed(Self.onTitleBar))
        _ = system.send(.dragged(Self.further))
        _ = system.send(.dragged(Self.further))
        window.currentFrame.origin = ScreenPoint(x: 103, y: 104)
        _ = system.send(.released(Self.further))
        #expect(
            test.lastReport
                == DragHoldReport(pointerTravel: 50, windowTravel: 5, heldEvents: 2))
    }

    @Test func aClickLeavesNoReport() {
        _ = system.send(.pressed(Self.onTitleBar))
        _ = system.send(.released(Self.onTitleBar))
        #expect(test.lastReport == nil)
    }

    @Test func stopLetsAllInputPass() {
        test.stop()
        #expect(!system.isHolding)
        #expect(!test.isRunning)
    }

    @Test func withoutThePermissionTheTestDoesNotStart() {
        system.isAccessibilityGranted = false
        let denied = DragHoldTest(system: system)
        denied.start()
        #expect(denied.problem == .accessibilityDenied)
        #expect(!denied.isRunning)
    }

    @Test func aFailingTapIsReported() {
        test.stop()
        system.watchError = .eventTapUnavailable
        test.start()
        #expect(test.problem == .eventTapUnavailable)
        #expect(!test.isRunning)
    }
}
