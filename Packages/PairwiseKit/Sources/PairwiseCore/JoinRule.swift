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

    /// The place for a window at `frame` to join one of `windows`, frontmost first, with the
    /// pointer at `pointer`. The frontmost window under the pointer comes first, on the side
    /// of the half the pointer is in, whatever the size of the dragged window (ADR 0038).
    /// Otherwise the closest edge within the snap distance, or `nil`. The window takes the
    /// other's height and top.
    public static func target(
        for frame: WindowFrame, pointer: ScreenPoint, among windows: [ScreenWindow]
    ) -> JoinTarget? {
        if let window = windows.first(where: { $0.frame.contains(pointer) }) {
            let centre = window.frame.origin.x + window.frame.size.width / 2
            return target(
                width: frame.size.width, beside: window, on: pointer.x >= centre ? .right : .left)
        }
        return
            windows
            .filter { overlapVertically($0.frame, frame) }
            .flatMap { window in
                [
                    (window, PairSide.right, abs(frame.origin.x - window.frame.maxX)),
                    (window, PairSide.left, abs(frame.maxX - window.frame.origin.x)),
                ]
            }
            .filter { $0.2 <= snapDistance }
            .min { $0.2 < $1.2 }
            .map { window, side, _ in target(width: frame.size.width, beside: window, on: side) }
    }

    private static func target(
        width: Double, beside window: ScreenWindow, on side: PairSide
    ) -> JoinTarget {
        JoinTarget(
            other: window, side: side,
            frame: joinedFrame(width: width, beside: window.frame, on: side))
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
