import AppKit
import PairwiseCore
import Testing

@testable import PairwiseWindowSystem

@Suite struct ScreenCoordinateTests {
    @Test func theMainDisplayStartsAtTheTop() {
        let frames = NSScreen.globalFrames(of: [CGRect(x: 0, y: 0, width: 1440, height: 900)])
        #expect(frames == [WindowFrame(x: 0, y: 0, width: 1440, height: 900)])
    }

    @Test func aDisplayBelowHasAGreaterY() {
        let frames = NSScreen.globalFrames(of: [
            CGRect(x: 0, y: 0, width: 1440, height: 900),
            CGRect(x: 0, y: -600, width: 1000, height: 600),
        ])
        #expect(frames[1] == WindowFrame(x: 0, y: 900, width: 1000, height: 600))
    }

    @Test func noDisplaysGiveNoFrames() {
        #expect(NSScreen.globalFrames(of: []).isEmpty)
    }

    @Test func aPointFlipsAgainstTheMainDisplay() {
        let point = NSScreen.appKitPoint(ScreenPoint(x: 10, y: 100), mainHeight: 900)
        #expect(point == CGPoint(x: 10, y: 800))
    }

    @Test func aFrameFlipsAgainstTheMainDisplay() {
        let frame = NSScreen.appKitFrame(
            WindowFrame(x: 10, y: 100, width: 50, height: 200), mainHeight: 900)
        #expect(frame == CGRect(x: 10, y: 600, width: 50, height: 200))
    }
}
