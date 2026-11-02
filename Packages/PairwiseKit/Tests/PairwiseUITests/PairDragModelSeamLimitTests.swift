import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

/// A seam that stops where a window will go no further, found under the panel (ADR 0048).
@MainActor
@Suite struct PairDragModelSeamLimitTests {
    private static let press = ScreenPoint(x: 500, y: 200)
    private static let lookInterval = 0.1

    private let system = FakeWindowSystem()
    private let panel = FakeStandIn()
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

    /// Starts a resize with the seam going to each of `seams`, with a look at each.
    private func resize(through seams: [Double]) {
        system.windowUnderPointer = left
        _ = system.send(.pressed(Self.press))
        system.finishStandIn(with: .success(panel))
        left.currentFrame = WindowFrame(x: 100, y: 100, width: 410, height: 300)
        system.tick()
        for seam in seams {
            _ = system.send(.dragged(ScreenPoint(x: seam, y: 200)))
            system.uptime += Self.lookInterval
            system.tick()
        }
    }

    private func release(atX x: Double) {
        _ = system.send(.released(ScreenPoint(x: x, y: 200)))
        system.tick()
    }

    @Test func aPartnersMinimumStopsTheSeamInThePanel() {
        right.minimumWidth = 150
        resize(through: [520, 590, 620, 640])
        #expect(panel.seams.last == 450)
    }

    @Test func thePointerComingBackBringsTheSeamAlong() {
        right.minimumWidth = 150
        resize(through: [520, 590, 620, 640])
        _ = system.send(.dragged(ScreenPoint(x: 520, y: 200)))
        #expect(panel.seams.last == 420)
    }

    @Test func aHeldWindowsMinimumStopsTheSeam() {
        left.minimumWidth = 350
        resize(through: [480, 400, 380, 360])
        #expect(panel.seams.last == 350)
    }

    @Test func aPartnersMaximumStopsTheSeam() {
        right.maximumWidth = 250
        resize(through: [480, 400, 380, 360])
        #expect(panel.seams.last == 350)
    }

    @Test func aHeldWindowsMaximumStopsTheSeam() {
        left.maximumWidth = 450
        resize(through: [520, 590, 620, 640])
        #expect(panel.seams.last == 450)
    }

    @Test func aWindowThatRoundsDoesNotStopTheSeam() {
        right.widthStep = 8
        resize(through: [520, 530, 540, 550])
        #expect(panel.seams.last == 450)
        _ = system.send(.dragged(ScreenPoint(x: 600, y: 200)))
        #expect(panel.seams.last == 500)
    }

    /// A terminal rounds its width to whole characters.
    @Test func aPressedWindowThatRoundsLeavesNoGap() {
        left.widthStep = 7
        resize(through: [520, 530, 540])
        release(atX: 540)
        #expect(
            right.currentFrame.origin.x == left.currentFrame.origin.x + left.currentFrame.size.width
        )
        #expect(left.currentFrame.origin.x == 100)
        #expect(right.currentFrame.origin.x + right.currentFrame.size.width == 700)
    }

    @Test func twoWindowsThatRoundLeaveNoGap() {
        left.widthStep = 7
        right.widthStep = 11
        resize(through: [520, 530, 540])
        release(atX: 540)
        #expect(
            right.currentFrame.origin.x == left.currentFrame.origin.x + left.currentFrame.size.width
        )
    }

    @Test func aReleaseAtALimitLeavesTheWindowsAgainstEachOther() {
        right.minimumWidth = 150
        resize(through: [520, 590, 620, 640])
        release(atX: 640)
        #expect(left.currentFrame == WindowFrame(x: 100, y: 100, width: 450, height: 300))
        #expect(right.currentFrame == WindowFrame(x: 550, y: 100, width: 150, height: 200))
    }

    @Test func aReleaseBeforeALimitIsFoundStillStopsAtIt() {
        right.minimumWidth = 150
        resize(through: [520])
        _ = system.send(.dragged(ScreenPoint(x: 640, y: 200)))
        release(atX: 640)
        #expect(left.currentFrame == WindowFrame(x: 100, y: 100, width: 450, height: 300))
        #expect(right.currentFrame == WindowFrame(x: 550, y: 100, width: 150, height: 200))
    }

    @Test func aWindowThatRoundsKeepsItsFarEdgeAndTheOtherMeetsIt() {
        right.widthStep = 40
        resize(through: [550])
        release(atX: 550)
        #expect(right.currentFrame == WindowFrame(x: 580, y: 100, width: 120, height: 200))
        #expect(left.currentFrame == WindowFrame(x: 100, y: 100, width: 480, height: 300))
    }

    @Test func aPartnerThatRefusesKeepsItsPlaceAndTheWindowComesBack() {
        right.resizeError = .windowRefused
        resize(through: [520])
        release(atX: 520)
        #expect(right.currentFrame == WindowFrame(x: 500, y: 100, width: 200, height: 200))
        #expect(left.currentFrame == WindowFrame(x: 100, y: 100, width: 400, height: 300))
    }
}
