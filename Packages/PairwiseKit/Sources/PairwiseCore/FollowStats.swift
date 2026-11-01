import Foundation

/// Collects the measurements of the moves of one drag.
public struct FollowStats: Sendable {
    private static let percentile = 0.95

    private var durations: [TimeInterval] = []
    private var pointsBehind: [Double] = []

    public init() {}

    /// Records one move: how long it took, and how far the pointer travelled meanwhile.
    public mutating func record(moveDuration: TimeInterval, pointsBehind behind: Double) {
        durations.append(moveDuration)
        pointsBehind.append(behind)
    }

    /// The report for a drag that lasted `elapsed` seconds, or `nil` when there is
    /// nothing to report: no moves, or no time.
    public func report(elapsed: TimeInterval) -> FollowReport? {
        guard !durations.isEmpty, elapsed > 0 else { return nil }
        let sorted = durations.sorted()
        let count = Double(durations.count)
        let rank = Int((Self.percentile * count).rounded(.up)) - 1
        return FollowReport(
            moves: durations.count,
            movesPerSecond: count / elapsed,
            meanMove: durations.reduce(0, +) / count,
            percentile95Move: sorted[rank],
            longestMove: sorted[sorted.count - 1],
            meanPointsBehind: pointsBehind.reduce(0, +) / count,
            mostPointsBehind: pointsBehind.max() ?? 0
        )
    }
}
