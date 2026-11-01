import AppKit
import PairwiseCore

extension NSScreen {
    /// All displays in global screen coordinates (see `ScreenPoint`). AppKit's origin is
    /// at the bottom left of the main display, with y growing upwards.
    static var globalFrames: [WindowFrame] {
        let mainHeight = screens.first?.frame.height ?? 0
        return screens.map { screen in
            WindowFrame(
                x: Double(screen.frame.minX), y: Double(mainHeight - screen.frame.maxY),
                width: Double(screen.frame.width), height: Double(screen.frame.height))
        }
    }

    /// `point` in AppKit's coordinates.
    static func appKitPoint(_ point: ScreenPoint) -> CGPoint {
        let mainHeight = screens.first?.frame.height ?? 0
        return CGPoint(x: point.x, y: Double(mainHeight) - point.y)
    }
}
