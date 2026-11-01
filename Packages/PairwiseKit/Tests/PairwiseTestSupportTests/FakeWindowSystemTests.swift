import PairwiseCore
import PairwiseTestSupport
import Testing

@MainActor
@Suite struct FakeWindowSystemTests {
    @Test func aWindowMovesAndRemembersIt() throws {
        let window = FakeWindow(frame: WindowFrame(x: 0, y: 0, width: 10, height: 10))
        try window.move(to: ScreenPoint(x: 5, y: 6))
        #expect(window.moves == [ScreenPoint(x: 5, y: 6)])
        #expect(try window.frame().origin == ScreenPoint(x: 5, y: 6))
    }

    @Test func aRefusedMoveLeavesTheWindowInPlace() {
        let window = FakeWindow(frame: WindowFrame(x: 0, y: 0, width: 10, height: 10))
        window.moveError = .windowRefused
        #expect(throws: WindowSystemError.windowRefused) {
            try window.move(to: ScreenPoint(x: 5, y: 6))
        }
        #expect(window.currentFrame.origin == ScreenPoint(x: 0, y: 0))
    }

    @Test func aTickRunsOnlyWhileTicking() {
        let system = FakeWindowSystem()
        var ticks = 0
        system.startTicking(every: 1) { ticks += 1 }
        system.tick()
        system.stopTicking()
        system.tick()
        #expect(ticks == 1)
    }
}
