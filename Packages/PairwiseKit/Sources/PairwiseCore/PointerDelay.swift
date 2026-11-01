import Foundation

/// Gives where the pointer was a short time ago. Pairwise sees the pointer before the
/// window server has moved the dragged window, so a stand-in going straight to the
/// pointer's place runs ahead of that window (ADR 0017).
public struct PointerDelay: Sendable {
    private var history: [(time: TimeInterval, point: ScreenPoint)] = []

    public init() {}

    /// Notes the pointer at `point` at `time`, and returns where it was `delay` seconds
    /// before, or the oldest place known when that is further back than the notes go.
    public mutating func place(
        of point: ScreenPoint, at time: TimeInterval, holdingBack delay: TimeInterval
    ) -> ScreenPoint {
        history.append((time, point))
        if let index = history.lastIndex(where: { $0.time <= time - delay }) {
            history.removeFirst(index)
        }
        return history[0].point
    }
}
