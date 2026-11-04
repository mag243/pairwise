/// How scrolling turns into steps through the places to join (ADR 0069).
public struct JoinScroll: Equatable, Sendable {
    /// How far a trackpad's movement goes for one step, in points.
    private static let pointsPerStep = 40.0

    private var collected = 0.0

    public init() {}

    /// The steps for a wheel's event: one, whatever its size, as a wheel's acceleration makes
    /// a single notch count for several lines. Scrolling down is a positive step.
    public mutating func steps(forWheelLines lines: Int) -> Int {
        collected = 0
        return lines == 0 ? 0 : (lines < 0 ? 1 : -1)
    }

    /// The steps for a trackpad's movement of `points`, which is collected between events.
    public mutating func steps(forTrackpadPoints points: Double) -> Int {
        collected -= points
        let steps = Int(collected / Self.pointsPerStep)
        collected -= Double(steps) * Self.pointsPerStep
        return steps
    }
}
