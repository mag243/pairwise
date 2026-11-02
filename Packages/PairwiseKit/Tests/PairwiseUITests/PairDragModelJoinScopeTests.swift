import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

/// Which windows a dragged window can join (ADR 0043).
@MainActor
@Suite struct PairDragModelJoinScopeTests {
    private static let press = ScreenPoint(x: 50, y: 110)
    private static let nearRightEdge = ScreenPoint(x: 810, y: 150)
    private static let joined = WindowFrame(x: 800, y: 100, width: 200, height: 200)

    private let system = FakeWindowSystem()
    private let window = FakeWindow(
        frame: WindowFrame(x: 0, y: 100, width: 200, height: 200), number: 1)
    private let other = FakeWindow(
        frame: WindowFrame(x: 500, y: 100, width: 300, height: 400), number: 2)
    private let model: PairDragModel

    init() {
        system.isScreenRecordingGranted = true
        system.isJoinKeyDown = true
        system.windowUnderPointer = window
        system.knownWindows = [window, other]
        window.owner = 40
        other.owner = 41
        model = PairDragModel(system: system)
        model.start()
    }

    private func dragNearTheEdge() {
        _ = system.send(.pressed(Self.press))
        _ = system.send(.dragged(Self.press))
        window.currentFrame.origin = Self.nearRightEdge
        system.tick()
    }

    @Test func byDefaultAnotherAppsWindowCanJoin() {
        dragNearTheEdge()
        #expect(system.guideFrames.last == Self.joined)
    }

    @Test func withinOneAppAnotherAppsWindowCannotJoin() {
        model.joinScope = .sameApp
        dragNearTheEdge()
        #expect(!system.isGuideShowing)
        _ = system.send(.released(Self.press))
        #expect(window.currentFrame.origin == Self.nearRightEdge)
    }

    @Test func withinOneAppAWindowOfThatAppCanJoin() {
        model.joinScope = .sameApp
        other.owner = window.owner
        dragNearTheEdge()
        #expect(system.guideFrames.last == Self.joined)
    }

    @Test func controlKeepsOutAnotherAppsWindow() {
        system.isScopeKeyDown = true
        dragNearTheEdge()
        #expect(!system.isGuideShowing)
    }

    @Test func controlLetsInAnotherAppsWindowWhenTheSettingIsOneApp() {
        model.joinScope = .sameApp
        system.isScopeKeyDown = true
        dragNearTheEdge()
        #expect(system.guideFrames.last == Self.joined)
    }

    @Test func controlWithThePointerStillUpdatesTheGuide() {
        dragNearTheEdge()
        _ = system.send(
            .keysChanged(isJoinKeyDown: true, isEqualHeightKeyDown: false, isScopeKeyDown: true))
        system.tick()
        #expect(!system.isGuideShowing)
    }
}
