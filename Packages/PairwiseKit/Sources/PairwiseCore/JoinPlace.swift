/// A window to join, and the side of it the dragged window would be on.
public struct JoinPlace: Equatable, Sendable {
    public let other: ScreenWindow
    public let side: PairSide

    public init(other: ScreenWindow, side: PairSide) {
        self.other = other
        self.side = side
    }
}
