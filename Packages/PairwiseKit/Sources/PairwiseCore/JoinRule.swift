/// A normal window on screen, as the window server knows it.
public struct ScreenWindow: Equatable, Sendable {
    public let number: UInt32
    public let frame: WindowFrame

    public init(number: UInt32, frame: WindowFrame) {
        self.number = number
        self.frame = frame
    }
}

/// Where a dragged window would join another (ADR 0035).
public struct JoinTarget: Equatable, Sendable {
    /// The window it would join.
    public let other: ScreenWindow
    /// The side of `other` the dragged window would be on.
    public let side: PairSide
    /// The dragged window's frame once joined.
    public let frame: WindowFrame
}

/// When a dragged window is close enough to another window's edge to join.
public enum JoinRule {
    /// How far apart two edges may be to join, in points.
    private static let snapDistance = 24.0

    /// The closest place for a window at `frame` to join one of `windows`, or `nil` when none
    /// is close enough. A window over another counts as close, on the side of its centre
    /// (ADR 0037). The window takes the other's height and top.
    public static func target(for frame: WindowFrame, among windows: [ScreenWindow]) -> JoinTarget?
    {
        windows
            .filter { overlapVertically($0.frame, frame) }
            .map { window in
                let isRight = centre(of: frame) >= centre(of: window.frame)
                let gap =
                    isRight
                    ? frame.origin.x - window.frame.maxX : window.frame.origin.x - frame.maxX
                return (window, isRight ? PairSide.right : .left, gap)
            }
            .filter { $0.2 <= snapDistance }
            .min { abs($0.2) < abs($1.2) }
            .map { window, side, _ in
                JoinTarget(
                    other: window, side: side,
                    frame: joinedFrame(width: frame.size.width, beside: window.frame, on: side))
            }
    }

    private static func centre(of frame: WindowFrame) -> Double {
        frame.origin.x + frame.size.width / 2
    }

    private static func overlapVertically(_ first: WindowFrame, _ second: WindowFrame) -> Bool {
        first.origin.y < second.maxY && second.origin.y < first.maxY
    }

    private static func joinedFrame(
        width: Double, beside other: WindowFrame, on side: PairSide
    ) -> WindowFrame {
        WindowFrame(
            x: side == .right ? other.maxX : other.origin.x - width, y: other.origin.y,
            width: width, height: other.size.height)
    }
}
