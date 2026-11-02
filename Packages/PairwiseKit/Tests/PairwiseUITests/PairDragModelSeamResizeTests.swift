import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

/// A window of a pair resized at the seam, with its partner following (ADR 0045).
@MainActor
@Suite struct PairDragModelSeamResizeTests {
    private static let press = ScreenPoint(x: 499, y: 200)
    private static let reach = SeamFollow.reachUnderHeldWindow

    private let system = FakeWindowSystem()
    private let left = FakeWindow(
        frame: WindowFrame(x: 100, y: 100, width: 400, height: 300), number: 1)
    private let right = FakeWindow(
        frame: WindowFrame(x: 500, y: 100, width: 200, height: 200), number: 2)
    private let model: PairDragModel

    init() throws {
        system.isScreenRecordingGranted = true
        system.knownWindows = [left, right]
        model = PairDragModel(system: system)
        model.start()
        try model.join(left, to: right, on: .left)
    }

    /// Presses on `held`, and has macOS move its seam so that the following starts.
    private func resize(_ held: FakeWindow, to frame: WindowFrame) {
        system.windowUnderPointer = held
        _ = system.send(.pressed(Self.press))
        held.currentFrame = frame
        system.tick()
        system.tick()
    }

    private let wider = WindowFrame(x: 100, y: 100, width: 450, height: 300)

    @Test func aShrinkingPartnerOnTheRightMeetsTheSeam() {
        resize(left, to: wider)
        #expect(right.currentFrame.origin.x == 550)
        #expect(right.currentFrame.maxX == 700)
    }

    @Test func aShrinkingPartnerOnTheLeftMeetsTheSeam() {
        resize(right, to: WindowFrame(x: 450, y: 100, width: 250, height: 200))
        #expect(left.currentFrame.origin.x == 100)
        #expect(left.currentFrame.maxX == 450)
    }

    @Test func aGrowingPartnerOnTheRightReachesUnderTheWindow() {
        resize(left, to: WindowFrame(x: 100, y: 100, width: 350, height: 300))
        #expect(right.currentFrame.origin.x == 450 - Self.reach)
        #expect(right.currentFrame.maxX == 700)
    }

    @Test func aGrowingPartnerOnTheLeftReachesUnderTheWindow() {
        resize(right, to: WindowFrame(x: 550, y: 100, width: 150, height: 200))
        #expect(left.currentFrame.origin.x == 100)
        #expect(left.currentFrame.maxX == 550 + Self.reach)
    }

    /// The grip of a window's edge reaches past the window, so a press on one window can resize
    /// the window beside it.
    private func press(
        on window: FakeWindow, whileResizing resized: FakeWindow, to frame: WindowFrame
    ) {
        system.windowUnderPointer = window
        _ = system.send(.pressed(Self.press))
        resized.currentFrame = frame
        system.tick()
        system.tick()
    }

    @Test func aPressBesideTheSeamThatResizesTheLeftWindowResizesTheRightOneToo() {
        press(on: right, whileResizing: left, to: wider)
        #expect(right.currentFrame.origin.x == 550)
        #expect(right.currentFrame.maxX == 700)
    }

    @Test func aPressBesideTheSeamThatResizesTheRightWindowResizesTheLeftOneToo() {
        press(
            on: left, whileResizing: right,
            to: WindowFrame(x: 450, y: 100, width: 250, height: 200))
        #expect(left.currentFrame.maxX == 450)
        #expect(left.currentFrame.origin.x == 100)
    }

    @Test func aPressBesideTheSeamThatResizesTheOuterEdgeOfTheOtherStartsNothing() {
        press(
            on: right, whileResizing: left,
            to: WindowFrame(x: 50, y: 100, width: 450, height: 300))
        #expect(right.moves.isEmpty && right.resizes.isEmpty)
    }

    @Test func thePartnerKeepsItsHeight() {
        resize(left, to: WindowFrame(x: 100, y: 100, width: 450, height: 350))
        #expect(right.currentFrame.size.height == 200)
    }

    @Test func theEventsPassWhileResizing() {
        resize(left, to: wider)
        #expect(system.send(.dragged(Self.press)))
        #expect(system.send(.released(Self.press)))
    }

    @Test func aStillSeamAsksTheAppNothingMore() {
        resize(left, to: wider)
        let moves = right.moves.count
        system.tick()
        #expect(right.moves.count == moves)
    }

    @Test func theReleaseActsOnTheNextTickAndNotOnTheEvent() {
        let narrower = WindowFrame(x: 100, y: 100, width: 350, height: 300)
        resize(left, to: narrower)
        _ = system.send(.released(Self.press))
        #expect(right.currentFrame.origin.x == 450 - Self.reach)
        system.tick()
        #expect(right.currentFrame == WindowFrame(x: 450, y: 100, width: 250, height: 200))
        #expect(!system.isTicking)
    }

    @Test func aLostReleaseStillEndsTheResize() {
        resize(left, to: wider)
        system.isPrimaryButtonDown = false
        system.tick()
        #expect(right.currentFrame == WindowFrame(x: 550, y: 100, width: 150, height: 200))
    }

    @Test func aPartnerThatRefusesKeepsItsPlaceAndTheWindowComesBack() {
        left.resizeError = .windowRefused
        resize(right, to: WindowFrame(x: 450, y: 100, width: 250, height: 200))
        _ = system.send(.released(Self.press))
        system.tick()
        #expect(right.currentFrame == WindowFrame(x: 500, y: 100, width: 200, height: 200))
    }

    @Test func aPartnerOnTheRightThatRefusesKeepsItsPlaceAndTheWindowComesBack() {
        right.resizeError = .windowRefused
        resize(left, to: wider)
        _ = system.send(.released(Self.press))
        system.tick()
        #expect(right.currentFrame == WindowFrame(x: 500, y: 100, width: 200, height: 200))
        #expect(left.currentFrame == WindowFrame(x: 100, y: 100, width: 400, height: 300))
    }

    @Test func aPartnerThatGivesOtherWidthKeepsItsFarEdge() {
        right.widthStep = 40
        resize(left, to: wider)
        _ = system.send(.released(Self.press))
        system.tick()
        #expect(right.currentFrame == WindowFrame(x: 580, y: 100, width: 120, height: 200))
        #expect(left.currentFrame == WindowFrame(x: 100, y: 100, width: 480, height: 300))
    }

    @Test func aWindowAtThePartnersEdgeAfterTheReleaseIsLeftAlone() {
        resize(left, to: wider)
        _ = system.send(.released(Self.press))
        system.tick()
        #expect(left.moves.isEmpty && left.resizes.isEmpty)
    }

    @Test func thePairGoesOnAfterAResize() {
        resize(left, to: wider)
        _ = system.send(.released(Self.press))
        system.tick()
        _ = system.send(.pressed(Self.press))
        #expect(system.standInRequests == 2)
    }

    @Test func anOuterEdgeResizesOneWindowOnly() {
        resize(left, to: WindowFrame(x: 50, y: 100, width: 450, height: 300))
        #expect(right.moves.isEmpty && right.resizes.isEmpty)
        #expect(!system.isTicking)
    }

    @Test func aPressDuringAFinishPutsTheWindowsExactly() {
        resize(left, to: wider)
        _ = system.send(.released(Self.press))
        _ = system.send(.pressed(Self.press))
        #expect(right.currentFrame == WindowFrame(x: 550, y: 100, width: 150, height: 200))
    }
}
