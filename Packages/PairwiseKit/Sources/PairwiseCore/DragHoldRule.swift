import Foundation

/// What a press turns out to be (ADR 0032), and how long a drag waits for its pictures.
public enum DragHoldRule {
    /// How long a drag is held back while waiting for its pictures.
    private static let longestWaitForPictures: TimeInterval = 1

    /// Whether going from `start` to `now` is a window being moved.
    public static func isMove(from start: WindowFrame, to now: WindowFrame) -> Bool {
        start.origin != now.origin && start.size == now.size
    }

    /// Whether going from `start` to `now` is a window being resized.
    public static func isResize(from start: WindowFrame, to now: WindowFrame) -> Bool {
        start.size != now.size
    }

    /// Whether a drag that started `elapsed` seconds ago may still wait for its pictures.
    public static func mayWaitForPictures(after elapsed: TimeInterval) -> Bool {
        elapsed < longestWaitForPictures
    }
}
