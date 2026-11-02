import AppKit
import PairwiseCore

extension NSScreen {
    /// `frames` of displays, in AppKit's coordinates with the main display first, in global
    /// screen coordinates (see `ScreenPoint`). AppKit's origin is at the bottom left of the
    /// main display, with y growing upwards.
    static func globalFrames(of frames: [CGRect]) -> [WindowFrame] {
        let mainHeight = frames.first?.height ?? 0
        return frames.map { frame in
            WindowFrame(
                x: Double(frame.minX), y: Double(mainHeight - frame.maxY),
                width: Double(frame.width), height: Double(frame.height))
        }
    }

    /// `frame` in AppKit's coordinates, on displays with a main display `mainHeight` high.
    static func appKitFrame(_ frame: WindowFrame, mainHeight: CGFloat) -> CGRect {
        CGRect(
            x: frame.origin.x, y: Double(mainHeight) - frame.maxY, width: frame.size.width,
            height: frame.size.height)
    }

    /// `frame` in AppKit's coordinates.
    static func appKitFrame(_ frame: WindowFrame) -> CGRect {
        appKitFrame(frame, mainHeight: screens.first?.frame.height ?? 0)
    }

    /// `point` in AppKit's coordinates, on displays with a main display `mainHeight` high.
    static func appKitPoint(_ point: ScreenPoint, mainHeight: CGFloat) -> CGPoint {
        CGPoint(x: point.x, y: Double(mainHeight) - point.y)
    }

    /// `point` in AppKit's coordinates.
    static func appKitPoint(_ point: ScreenPoint) -> CGPoint {
        appKitPoint(point, mainHeight: screens.first?.frame.height ?? 0)
    }
}
