import Foundation

/// Which drags the test of holding back may withhold (ADR 0023).
public enum DragHoldRule {
    /// How far down from a window's top a press counts as being on its title bar. A fixed
    /// height does not fit every window, which is enough for a test.
    private static let titleBandHeight = 52.0
    /// How long one drag is held back at most, so input cannot stay blocked.
    private static let longestHold: TimeInterval = 5

    /// Whether a press at `point` is in the top band of a window at `frame`.
    public static func isInTitleBand(_ point: ScreenPoint, of frame: WindowFrame) -> Bool {
        point.x >= frame.origin.x && point.x <= frame.maxX
            && point.y >= frame.origin.y && point.y <= frame.origin.y + titleBandHeight
    }

    /// Whether a drag that started `elapsed` seconds ago may still be held back.
    public static func mayHold(after elapsed: TimeInterval) -> Bool {
        elapsed < longestHold
    }
}
