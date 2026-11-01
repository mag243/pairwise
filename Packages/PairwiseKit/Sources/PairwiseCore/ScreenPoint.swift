import Foundation

/// A point in global screen coordinates, with the origin at the top left of the
/// main display and y growing downwards.
public struct ScreenPoint: Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    /// The straight-line distance to `other`, in points.
    public func distance(to other: ScreenPoint) -> Double {
        hypot(other.x - x, other.y - y)
    }
}
