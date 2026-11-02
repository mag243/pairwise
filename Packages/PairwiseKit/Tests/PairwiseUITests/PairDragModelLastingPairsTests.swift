import Foundation
import PairwiseCore
import PairwiseTestSupport
import PairwiseUI
import Testing

/// Pairs that survive a quit, a crash or a restart (ADR 0054).
@MainActor
@Suite struct PairDragModelLastingPairsTests {
    private static let far = ScreenPoint(x: 2000, y: 2000)
    private static let press = ScreenPoint(x: 150, y: 110)

    private let system = FakeWindowSystem()
    private let left = FakeWindow(
        frame: WindowFrame(x: 100, y: 100, width: 400, height: 200), number: 1)
    private let right = FakeWindow(
        frame: WindowFrame(x: 500, y: 100, width: 200, height: 200), number: 2)
    private let model: PairDragModel

    init() {
        left.owner = 40
        right.owner = 41
        left.appID = "app.one"
        right.appID = "app.two"
        system.isScreenRecordingGranted = true
        system.isPrimaryButtonDown = false
        system.windowUnderPointer = left
        system.knownWindows = [left, right]
        model = PairDragModel(system: system)
        model.start()
    }

    private var saved: SavedPairs? {
        system.pairsRecord.flatMap(SavedPairs.init(data:))
    }

    private func look(after seconds: Double = 1) {
        system.uptime += seconds
        system.movePointer(to: Self.far)
    }

    /// Joins and saves, and starts a new model, as after a quit.
    private func joinAndRestart() throws -> PairDragModel {
        try model.join(left, to: right, on: .left)
        look()
        return restarted()
    }

    private func restarted() -> PairDragModel {
        let next = PairDragModel(system: system)
        next.start()
        return next
    }

    /// Whether a press on the left window starts a pair's drag.
    private var isPaired: Bool {
        let before = system.standInRequests
        system.isPrimaryButtonDown = true
        _ = system.send(.pressed(Self.press))
        system.isPrimaryButtonDown = false
        _ = system.send(.released(Self.press))
        return system.standInRequests > before
    }

    @Test func aJoinIsSaved() throws {
        try model.join(left, to: right, on: .left)
        look()
        #expect(saved?.pairs.first?.left.number == 1)
        #expect(saved?.pairs.first?.right.number == 2)
    }

    @Test func aSaveIsNotDoneOnTheJoinItself() throws {
        try model.join(left, to: right, on: .left)
        #expect(system.pairsRecord == nil)
    }

    @Test func aPartingLeavesNothingSaved() throws {
        try model.join(left, to: right, on: .left)
        look()
        model.leavePair(of: left)
        look()
        #expect(system.pairsRecord == nil)
    }

    @Test func theEndOfADragSavesTheNewPlace() throws {
        let panel = FakeStandIn()
        try model.join(left, to: right, on: .left)
        look()
        system.isPrimaryButtonDown = true
        _ = system.send(.pressed(Self.press))
        system.finishStandIn(with: .success(panel))
        _ = system.send(.dragged(ScreenPoint(x: 190, y: 140)))
        left.currentFrame.origin = ScreenPoint(x: 140, y: 130)
        system.tick()
        system.tick()
        _ = system.send(.released(ScreenPoint(x: 190, y: 140)))
        system.uptime += 1
        system.tick()
        system.isPrimaryButtonDown = false
        look()
        #expect(saved?.pairs.first?.left.frame.origin == ScreenPoint(x: 140, y: 130))
    }

    @Test func aWindowOffTheScreenKeepsWhatWasSavedForIt() throws {
        try model.join(left, to: right, on: .left)
        look()
        let before = left.currentFrame
        system.knownWindows = [right]
        // Leaving the list says nothing about where the pair belongs.
        model.stop()
        #expect(saved?.pairs.first?.left.frame == before)
    }

    @Test func aRestartBringsThePairBack() throws {
        // The hold knows the model only weakly, so a test keeps it.
        withExtendedLifetime(try joinAndRestart()) {
            #expect(isPaired)
        }
    }

    @Test func aRestartMovesNoWindow() throws {
        _ = try joinAndRestart()
        #expect(left.moves.isEmpty && right.moves.isEmpty)
        #expect(left.resizes.isEmpty && right.resizes.isEmpty)
    }

    @Test func aPairNoLongerSideBySideStaysApart() throws {
        try model.join(left, to: right, on: .left)
        look()
        right.currentFrame.origin.x = 900
        withExtendedLifetime(restarted()) {
            #expect(!isPaired)
            #expect(right.moves.isEmpty)
        }
    }

    @Test func aWindowThatComesLaterBringsThePairBack() throws {
        try model.join(left, to: right, on: .left)
        look()
        system.knownWindows = []
        let next = restarted()
        #expect(saved?.pairs.count == 1)
        system.knownWindows = [left, right]
        system.uptime += 1
        system.movePointer(to: Self.far)
        withExtendedLifetime(next) {
            #expect(isPaired)
        }
    }

    @Test func aPairNotFoundInTimeIsForgotten() throws {
        try model.join(left, to: right, on: .left)
        look()
        system.knownWindows = []
        let next = restarted()
        withExtendedLifetime(next) {
            look(after: 121)
            #expect(system.pairsRecord == nil)
        }
    }

    @Test func aRecordThatCannotBeReadIsThrownAway() {
        system.pairsRecord = Data("no".utf8)
        _ = restarted()
        #expect(system.pairsRecord == nil)
    }

    @Test func aTestRunNeitherReadsNorWrites() throws {
        let test = PairDragModel(system: system)
        test.keepsPairs = false
        test.start()
        try test.join(left, to: right, on: .left)
        look()
        #expect(system.pairsRecord == nil)
    }

    @Test func aStopSavesWhatIsLeftToSave() throws {
        try model.join(left, to: right, on: .left)
        model.stop()
        #expect(saved?.pairs.count == 1)
    }
}
