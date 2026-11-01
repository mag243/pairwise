import Foundation

/// Sees the pointer come to rest during a drag. An app reports its window's place late
/// while the window moves, so comparing places is only fair once the pointer has stopped
/// (ADR 0016).
public struct StillPointer: Sendable {
    /// Long enough for an app to have reported where its window came to rest.
    private static let settleTime: TimeInterval = 0.1

    private var location: ScreenPoint?
    private var since: TimeInterval = 0
    private var hasReported = false

    public init() {}

    /// Whether the pointer has just come to rest: true once per stop.
    public mutating func hasSettled(at point: ScreenPoint, time: TimeInterval) -> Bool {
        guard point == location else {
            location = point
            since = time
            hasReported = false
            return false
        }
        guard !hasReported, time - since >= Self.settleTime else { return false }
        hasReported = true
        return true
    }
}
