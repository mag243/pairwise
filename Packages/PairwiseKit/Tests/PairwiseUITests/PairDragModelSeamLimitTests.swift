import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

/// A seam that stops where a window will go no further (ADR 0046).
@MainActor
@Suite struct PairDragModelSeamLimitTests {
    private static let press = ScreenPoint(x: 500, y: 200)

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

    /// Presses on `held`, and has macOS take its seam through `edges`, a tick for each.
    private func resize(_ held: FakeWindow, through frames: [WindowFrame]) {
        system.windowUnderPointer = held
        _ = system.send(.pressed(Self.press))
        for frame in frames {
            held.currentFrame = frame
            system.tick()
        }
        system.tick()
    }

    private func leftFrames(widths: [Double]) -> [WindowFrame] {
        widths.map { WindowFrame(x: 100, y: 100, width: $0, height: 300) }
    }

    private func rightFrames(xs: [Double]) -> [WindowFrame] {
        xs.map { WindowFrame(x: $0, y: 100, width: 700 - $0, height: 200) }
    }

    private func dragPasses(toX x: Double) -> Bool {
        system.send(.dragged(ScreenPoint(x: x, y: 200)))
    }

    /// Past a partner's minimum of 150: the seam can go no further right than 550.
    private func resizePastTheMinimumOnTheRight() {
        right.minimumWidth = 150
        resize(left, through: leftFrames(widths: [450, 480, 500, 520, 540, 560]))
    }

    @Test func aPartnersMinimumWithholdsTheDragPastIt() {
        resizePastTheMinimumOnTheRight()
        #expect(!dragPasses(toX: 560))
    }

    @Test func aPartnersMinimumLetsTheDragUpToIt() {
        resizePastTheMinimumOnTheRight()
        #expect(dragPasses(toX: 550))
    }

    @Test func thePointerComingBackGoesOnWithTheDrag() {
        resizePastTheMinimumOnTheRight()
        _ = dragPasses(toX: 560)
        #expect(dragPasses(toX: 520))
    }

    @Test func aHeldWindowPastTheLimitComesBackBeforeTheRelease() {
        resizePastTheMinimumOnTheRight()
        #expect(left.currentFrame.maxX == 550)
    }

    @Test func aPartnerAtItsLimitKeepsItsFarEdgeBeforeTheRelease() {
        resizePastTheMinimumOnTheRight()
        #expect(right.currentFrame == WindowFrame(x: 550, y: 100, width: 150, height: 200))
    }

    @Test func aPartnerOnTheLeftStopsTheSeamAtItsMinimum() {
        left.minimumWidth = 350
        resize(right, through: rightFrames(xs: [460, 440, 420, 400, 380]))
        #expect(right.currentFrame.origin.x == 450)
        #expect(!dragPasses(toX: 440))
        #expect(dragPasses(toX: 450))
    }

    @Test func aPartnerOnTheRightStopsTheSeamAtItsMaximum() {
        right.maximumWidth = 250
        resize(left, through: leftFrames(widths: [380, 340, 320, 300, 280, 260]))
        #expect(left.currentFrame.maxX == 450)
        #expect(!dragPasses(toX: 440))
        #expect(dragPasses(toX: 450))
    }

    @Test func aPartnerOnTheLeftStopsTheSeamAtItsMaximum() {
        left.maximumWidth = 450
        resize(right, through: rightFrames(xs: [520, 560, 580, 600, 620]))
        #expect(right.currentFrame.origin.x == 550)
        #expect(!dragPasses(toX: 560))
        #expect(dragPasses(toX: 550))
    }

    @Test func aPartnerThatRoundsDoesNotStopTheSeam() {
        right.widthStep = 8
        resize(left, through: leftFrames(widths: [450, 460, 470, 480, 490, 500]))
        #expect(dragPasses(toX: 600))
    }

    @Test func aPartnerWithoutALimitDoesNotStopTheSeam() {
        resize(left, through: leftFrames(widths: [450, 480, 500]))
        #expect(dragPasses(toX: 620))
    }

    @Test func theReleaseAtALimitLeavesTheWindowsAgainstEachOther() {
        resizePastTheMinimumOnTheRight()
        _ = system.send(.released(Self.press))
        system.tick()
        #expect(left.currentFrame.maxX == right.currentFrame.origin.x)
        #expect(right.currentFrame.maxX == 700)
    }
}
