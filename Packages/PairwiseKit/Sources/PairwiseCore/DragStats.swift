import Foundation

/// Collects the measurements of the moves of one drag.
public struct DragStats: Sendable {
    private static let percentile = 0.95

    private var durations: [TimeInterval] = []

    public init() {}

    /// Records how long one move took.
    public mutating func record(moveDuration: TimeInterval) {
        durations.append(moveDuration)
    }

    /// The report for a drag that lasted `elapsed` seconds, or `nil` when there is
    /// nothing to report: no moves, or no time.
    public func report(
        elapsed: TimeInterval, panelDelay: TimeInterval, liveFrames: [Int] = []
    ) -> DragReport? {
        guard !durations.isEmpty, elapsed > 0 else { return nil }
        let sorted = durations.sorted()
        let count = Double(durations.count)
        let rank = Int((Self.percentile * count).rounded(.up)) - 1
        return DragReport(
            moves: durations.count,
            movesPerSecond: count / elapsed,
            meanMove: durations.reduce(0, +) / count,
            percentile95Move: sorted[rank],
            longestMove: sorted[sorted.count - 1],
            panelDelay: panelDelay,
            liveFrames: liveFrames
        )
    }
}
