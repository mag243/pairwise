import CoreGraphics
import Foundation
import PairwiseCore
import Testing

@testable import PairwiseWindowSystem

@Suite struct WindowServerTests {
    @Test func aDescriptionGivesItsFrame() {
        let rect = CGRect(x: 10, y: 20, width: 300, height: 200)
        let description: [String: Any] = [
            kCGWindowBounds as String: rect.dictionaryRepresentation
        ]
        #expect(
            WindowServer.frame(from: description)
                == WindowFrame(x: 10, y: 20, width: 300, height: 200))
    }

    @Test func aDescriptionWithoutBoundsGivesNoFrame() {
        #expect(WindowServer.frame(from: [:]) == nil)
    }

    private func description(
        number: Int, process: Int, level: Int = 0, x: Double = 0
    ) -> [String: Any] {
        let rect = CGRect(x: x, y: 0, width: 100, height: 100)
        return [
            kCGWindowBounds as String: rect.dictionaryRepresentation,
            kCGWindowNumber as String: NSNumber(value: number),
            kCGWindowOwnerPID as String: NSNumber(value: process),
            kCGWindowLayer as String: NSNumber(value: level),
        ]
    }

    private static let point = ScreenPoint(x: 50, y: 50)
    private static let own: pid_t = 9

    @Test func theFrontmostWindowAtThePointIsOnTop() {
        let top = WindowServer.topWindow(
            at: Self.point, excludingProcess: Self.own,
            in: [
                description(number: 1, process: 1, x: 500),
                description(number: 2, process: 2),
                description(number: 3, process: 3),
            ])
        #expect(top?.number == 2)
        #expect(top?.processID == 2)
    }

    @Test func nothingAtThePointIsNoWindow() {
        let top = WindowServer.topWindow(
            at: Self.point, excludingProcess: Self.own,
            in: [description(number: 1, process: 1, x: 500)])
        #expect(top == nil)
    }

    @Test func pairwisesOwnWindowOnTopIsNoWindow() {
        let top = WindowServer.topWindow(
            at: Self.point, excludingProcess: Self.own,
            in: [description(number: 1, process: 9), description(number: 2, process: 2)])
        #expect(top == nil)
    }

    @Test func aWindowAtAHigherLevelIsLookedThrough() {
        let top = WindowServer.topWindow(
            at: Self.point, excludingProcess: Self.own,
            in: [description(number: 1, process: 1, level: 25), description(number: 2, process: 2)])
        #expect(top?.number == 2)
    }

    @Test func onlyAHigherLevelAtThePointIsNoWindow() {
        let top = WindowServer.topWindow(
            at: Self.point, excludingProcess: Self.own,
            in: [description(number: 1, process: 1, level: 25)])
        #expect(top == nil)
    }
}
