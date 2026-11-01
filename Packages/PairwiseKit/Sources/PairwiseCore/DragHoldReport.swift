/// What one drag showed in the test of holding back (ADR 0023).
public struct DragHoldReport: Equatable, Sendable {
    /// How far the pointer is from where it was pressed, in points.
    public let pointerTravel: Double
    /// How far the window is from where it was at the press, in points.
    public let windowTravel: Double
    /// How many drag events were withheld.
    public let heldEvents: Int

    public init(pointerTravel: Double, windowTravel: Double, heldEvents: Int) {
        self.pointerTravel = pointerTravel
        self.windowTravel = windowTravel
        self.heldEvents = heldEvents
    }
}
