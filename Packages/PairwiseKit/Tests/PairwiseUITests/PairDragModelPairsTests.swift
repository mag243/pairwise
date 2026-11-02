import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

@MainActor
@Suite struct PairDragModelPairsTests {
    private static let frame = WindowFrame(x: 300, y: 100, width: 400, height: 300)
    private static let press = ScreenPoint(x: 350, y: 110)
    private static let further = ScreenPoint(x: 390, y: 140)
    private static let moved = ScreenPoint(x: 340, y: 130)

    private let system = FakeWindowSystem()
    private let window = FakeWindow(frame: Self.frame, number: 1)
    private let partner = FakeWindow(
        frame: WindowFrame(x: 0, y: 500, width: 200, height: 250), number: 2)
    private let panel = FakeStandIn()
    private let model: PairDragModel

    init() {
        system.isScreenRecordingGranted = true
        system.windowUnderPointer = window
        model = PairDragModel(system: system)
        model.start()
    }

    /// Presses, lets the picture arrive, and has macOS move the window.
    private func startDrag() {
        _ = system.send(.pressed(Self.press))
        system.finishStandIn(with: .success(panel))
        _ = system.send(.dragged(Self.further))
        window.currentFrame.origin = Self.moved
        system.tick()
    }

    @Test func aWindowInNoPairCostsNothing() {
        _ = system.send(.pressed(Self.press))
        #expect(system.standInRequests == 0)
        #expect(!system.isTicking)
        #expect(system.send(.dragged(Self.further)))
        #expect(model.lastPressOutcome == "not in a pair")
    }

    @Test func noWindowAtThePressPasses() {
        system.windowUnderPointer = nil
        _ = system.send(.pressed(Self.press))
        #expect(system.send(.dragged(Self.further)))
        #expect(model.lastPressOutcome == "no window under the pointer")
    }

    @Test func aPartnerOnTheRightKeepsThePanelAtTheWindow() throws {
        try model.join(window, to: partner, on: .left)
        startDrag()
        #expect(panel.shownAt == Self.moved)
        _ = system.send(.released(Self.further))
        #expect(partner.moves.last == ScreenPoint(x: 740, y: 130))
    }

    @Test func aPartnerOnTheLeftPutsThePanelLeftOfTheWindow() throws {
        try model.join(window, to: partner, on: .right)
        startDrag()
        #expect(panel.shownAt == ScreenPoint(x: 140, y: 130))
        _ = system.send(.dragged(ScreenPoint(x: 400, y: 140)))
        #expect(panel.moves.last == ScreenPoint(x: 150, y: 130))
    }

    @Test func aPartnerOnTheLeftEndsLeftOfTheWindow() throws {
        try model.join(window, to: partner, on: .right)
        startDrag()
        _ = system.send(.released(Self.further))
        #expect(window.moves.last == Self.moved)
        #expect(partner.moves.last == ScreenPoint(x: 140, y: 130))
    }

    @Test func aDragFromThePartnerMovesThePairToo() throws {
        try model.join(window, to: partner, on: .left)
        system.windowUnderPointer = partner
        _ = system.send(.pressed(ScreenPoint(x: 10, y: 510)))
        #expect(system.standInRequests == 1)
    }

    @Test func aPartnerThatHasGoneEndsThePairAndTheDragPasses() throws {
        try model.join(window, to: partner, on: .left)
        partner.isAvailable = false
        _ = system.send(.pressed(Self.press))
        #expect(system.send(.dragged(Self.further)))
        #expect(!system.isTicking)
        partner.isAvailable = true
        _ = system.send(.pressed(Self.press))
        #expect(model.lastPressOutcome == "not in a pair")
    }

    @Test func aDraggedWindowThatIsUnavailableEndsThePair() throws {
        try model.join(window, to: partner, on: .left)
        window.isAvailable = false
        _ = system.send(.pressed(Self.press))
        window.isAvailable = true
        _ = system.send(.pressed(Self.press))
        #expect(model.lastPressOutcome == "not in a pair")
    }

    @Test func aBusyAppLetsTheDragPassAndKeepsThePair() throws {
        try model.join(window, to: partner, on: .left)
        partner.frameError = .windowBusy
        _ = system.send(.pressed(Self.press))
        #expect(system.send(.dragged(Self.further)))
        #expect(model.lastPressOutcome == "a window does not answer")
        partner.frameError = nil
        _ = system.send(.pressed(Self.press))
        #expect(model.lastPressOutcome == "watching")
    }

    @Test func leavingEndsThePair() throws {
        try model.join(window, to: partner, on: .left)
        model.leavePair(of: partner)
        _ = system.send(.pressed(Self.press))
        #expect(model.lastPressOutcome == "not in a pair")
    }

    @Test func afterEndingTheWindowsCanPairAgain() throws {
        try model.join(window, to: partner, on: .left)
        model.leavePair(of: window)
        try model.join(window, to: partner, on: .right)
    }

    @Test func aWindowTheSystemDoesNotKnowCannotJoin() {
        let unknown = FakeWindow(frame: Self.frame)
        #expect(throws: PairError.unknownWindow) {
            try model.join(unknown, to: partner, on: .left)
        }
    }

    @Test func aWindowCannotJoinItself() {
        #expect(throws: PairError.sameWindow) { try model.join(window, to: window, on: .left) }
    }
}
