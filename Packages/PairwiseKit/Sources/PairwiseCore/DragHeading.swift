/// A horizontal direction of movement.
public enum MoveDirection: Equatable, Sendable {
    case left
    case right
}

/// The direction a drag is going in, from where the pointer has been (ADR 0070).
public struct DragHeading: Equatable, Sendable {
    /// How far the pointer has to go to set or turn the direction, in points: less is a
    /// trembling hand.
    private static let turnDistance = 12.0

    /// The direction, or `nil` until the pointer has gone far enough. It stays while the
    /// pointer stands still.
    public private(set) var direction: MoveDirection?
    /// The furthest place in the current direction, from where a turn is measured.
    private var furthest: Double

    /// Precondition: `x` is where the pointer is when the drag starts being watched.
    public init(startingAt x: Double) {
        furthest = x
    }

    /// Takes the pointer's place of the moment.
    public mutating func update(x: Double) {
        switch direction {
        case .right where x > furthest, .left where x < furthest:
            furthest = x
        case .right where furthest - x >= Self.turnDistance:
            direction = .left
            furthest = x
        case .left where x - furthest >= Self.turnDistance:
            direction = .right
            furthest = x
        case nil where abs(x - furthest) >= Self.turnDistance:
            direction = x > furthest ? .right : .left
            furthest = x
        default:
            break
        }
    }
}
