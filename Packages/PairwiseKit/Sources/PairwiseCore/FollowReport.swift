import Foundation

/// The measurements of one drag. Durations are in seconds.
public struct FollowReport: Equatable, Sendable {
    /// How many times the partner was moved.
    public let moves: Int
    /// The moves per second over the whole drag.
    public let movesPerSecond: Double
    /// The mean duration of one move.
    public let meanMove: TimeInterval
    /// The duration that 95 % of the moves stayed within.
    public let percentile95Move: TimeInterval
    /// The longest move.
    public let longestMove: TimeInterval
    /// How far the pointer travelled during a move, on average, in points.
    public let meanPointsBehind: Double
    /// How far the pointer travelled during a move, at most, in points.
    public let mostPointsBehind: Double
    /// How long the stand-in took to appear after the drag was seen, or `nil` when the
    /// drag had none. With a stand-in, the moves above are the stand-in's.
    public let standInDelay: TimeInterval?
    /// How far the place worked out from the grip was from the dragged window's real
    /// place at the release, in points, or `nil` when the window did not tell.
    public let gripOffset: Double?
}
