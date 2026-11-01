import Foundation

/// The measurements of one drag. Durations are in seconds.
public struct DragReport: Equatable, Sendable {
    /// How many times the panel was moved.
    public let moves: Int
    /// The moves per second over the whole drag.
    public let movesPerSecond: Double
    /// The mean duration of one move.
    public let meanMove: TimeInterval
    /// The duration that 95 % of the moves stayed within.
    public let percentile95Move: TimeInterval
    /// The longest move.
    public let longestMove: TimeInterval
    /// How long the panel took to appear after the press.
    public let panelDelay: TimeInterval
    /// How many live frames showed a change during the drag, per window.
    public let liveFrames: [Int]
}
