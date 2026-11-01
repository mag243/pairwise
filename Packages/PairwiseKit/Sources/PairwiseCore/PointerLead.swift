import Foundation

/// Tells how far ahead of a dragged window's known place the window is about to be. The
/// pointer moves first and the window follows shortly after, so how far the pointer moved
/// in the last moments is how far the window is still to go (ADR 0019).
public struct PointerLead: Sendable {
    private var history: [(time: TimeInterval, point: ScreenPoint)] = []

    public init() {}

    /// Notes the pointer at `pointer` at `time`, and returns `place` moved by how far the
    /// pointer went in the last `lookAhead` seconds, or since the first note when that is
    /// more recent.
    public mutating func ahead(
        of place: ScreenPoint, pointer: ScreenPoint, at time: TimeInterval,
        lookingAhead lookAhead: TimeInterval
    ) -> ScreenPoint {
        history.append((time, pointer))
        if let index = history.lastIndex(where: { $0.time <= time - lookAhead }) {
            history.removeFirst(index)
        }
        let earlier = history[0].point
        return ScreenPoint(x: place.x + pointer.x - earlier.x, y: place.y + pointer.y - earlier.y)
    }
}
