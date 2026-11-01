import Foundation

/// Which presses Pairwise takes over as a drag of its own (ADR 0024).
public enum DragHoldRule {
    /// How far down from a window's top a press counts as being on its title bar. A fixed
    /// height does not fit every window, which is enough for a spike.
    private static let titleBandHeight = 52.0
    /// How far the pointer moves before a press counts as a drag, in points.
    private static let dragDistance = 3.0
    /// How long a drag is held back while waiting for its pictures.
    private static let longestWaitForPictures: TimeInterval = 1

    /// Whether a press at `point` is in the top band of a window at `frame`.
    public static func isInTitleBand(_ point: ScreenPoint, of frame: WindowFrame) -> Bool {
        point.x >= frame.origin.x && point.x <= frame.maxX
            && point.y >= frame.origin.y && point.y <= frame.origin.y + titleBandHeight
    }

    /// Whether the pointer at `point` has left a press at `press` far enough to be a drag.
    public static func isDrag(from press: ScreenPoint, to point: ScreenPoint) -> Bool {
        press.distance(to: point) >= dragDistance
    }

    /// Whether a drag that started `elapsed` seconds ago may still wait for its pictures.
    public static func mayWaitForPictures(after elapsed: TimeInterval) -> Bool {
        elapsed < longestWaitForPictures
    }
}
