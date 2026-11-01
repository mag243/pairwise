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
}
