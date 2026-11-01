import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

@MainActor
@Suite struct PairDragModelReportTests {
    private static let onTitleBar = ScreenPoint(x: 150, y: 110)
    private static let further = ScreenPoint(x: 190, y: 140)

    private let system = FakeWindowSystem()
    private let window = FakeWindow(frame: WindowFrame(x: 100, y: 100, width: 400, height: 300))
    private let partner = FakeWindow(frame: WindowFrame(x: 0, y: 500, width: 200, height: 200))
    private let panel = FakeStandIn()
    private let model: PairDragModel

    init() {
        system.isScreenRecordingGranted = true
        system.windowUnderPointer = window
        system.partnerWindow = partner
        model = PairDragModel(system: system)
        model.start()
    }

    @Test func aDragShorterThanThePanelPutsThePartnerBesideTheWindow() {
        _ = system.send(.pressed(Self.onTitleBar))
        _ = system.send(.dragged(Self.further))
        window.currentFrame.origin = ScreenPoint(x: 140, y: 130)
        _ = system.send(.released(Self.further))
        #expect(window.moves.isEmpty)
        #expect(partner.moves.last == ScreenPoint(x: 540, y: 130))
    }

    @Test func aClickBeforeThePicturesMovesNothing() {
        _ = system.send(.pressed(Self.onTitleBar))
        _ = system.send(.released(Self.onTitleBar))
        #expect(window.moves.isEmpty)
        #expect(partner.moves.isEmpty)
    }

    @Test func theReportCarriesThePanelsDelay() throws {
        _ = system.send(.pressed(Self.onTitleBar))
        system.uptime = 0.05
        system.finishStandIn(with: .success(panel))
        _ = system.send(.dragged(Self.further))
        window.currentFrame.origin = ScreenPoint(x: 140, y: 130)
        system.tick()
        _ = system.send(.dragged(Self.onTitleBar))
        system.uptime = 1.05
        _ = system.send(.released(Self.onTitleBar))
        let report = try #require(model.lastDrag)
        #expect(report.moves == 1)
        #expect(report.panelDelay == 0.05)
    }

    @Test func theReportCarriesTheLiveFrames() throws {
        _ = system.send(.pressed(Self.onTitleBar))
        system.finishStandIn(with: .success(panel))
        _ = system.send(.dragged(Self.further))
        window.currentFrame.origin = ScreenPoint(x: 140, y: 130)
        system.tick()
        _ = system.send(.dragged(Self.onTitleBar))
        panel.liveFrames = [7, 9]
        system.uptime = 1
        _ = system.send(.released(Self.onTitleBar))
        #expect(try #require(model.lastDrag).liveFrames == [7, 9])
    }
}
