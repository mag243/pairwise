/// A normal window on screen, as the window server knows it.
public struct ScreenWindow: Equatable, Sendable {
    public let number: UInt32
    public let frame: WindowFrame
    /// The process that owns the window: two windows of one process are of the same app.
    public let owner: Int32

    public init(number: UInt32, frame: WindowFrame, owner: Int32 = 0) {
        self.number = number
        self.frame = frame
        self.owner = owner
    }
}

/// Which windows a dragged window may join (ADR 0043).
public enum JoinScope: String, CaseIterable, Sendable {
    case anyWindow
    case sameApp

    /// This scope, or the other while the key that switches it is down.
    public func switched(if isKeyDown: Bool) -> JoinScope {
        guard isKeyDown else { return self }
        return self == .anyWindow ? .sameApp : .anyWindow
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

    /// The windows among `windows` that window `number` may join in `scope`. Without knowing
    /// its app, a window has none within one app.
    public static func candidates(
        for number: UInt32, among windows: [ScreenWindow], scope: JoinScope
    ) -> [ScreenWindow] {
        let others = windows.filter { $0.number != number }
        guard scope == .sameApp else { return others }
        guard let dragged = windows.first(where: { $0.number == number }) else { return [] }
        return others.filter { $0.owner == dragged.owner }
    }

    /// The place for a window at `frame` to join one of `windows`, frontmost first, with the
    /// pointer at `pointer`. The frontmost window under the pointer comes first, on the side
    /// of the half the pointer is in, whatever the size of the dragged window (ADR 0038).
    /// Otherwise the closest edge within the snap distance, or `nil`. The window takes the
    /// other's top, and its height only when `takingHeight` (ADR 0040).
    public static func target(
        for frame: WindowFrame, pointer: ScreenPoint, among windows: [ScreenWindow],
        takingHeight: Bool
    ) -> JoinTarget? {
        let height = { (window: ScreenWindow) in
            takingHeight ? window.frame.size.height : frame.size.height
        }
        if let window = windows.first(where: { $0.frame.contains(pointer) }) {
            let centre = window.frame.origin.x + window.frame.size.width / 2
            return target(
                size: WindowSize(width: frame.size.width, height: height(window)), beside: window,
                on: pointer.x >= centre ? .right : .left)
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
            .map { window, side, _ in
                target(
                    size: WindowSize(width: frame.size.width, height: height(window)),
                    beside: window, on: side)
            }
    }

    /// The place for a window at `frame`, keeping its size, on `side` of `window`, tight
    /// against it and with its top.
    public static func target(
        joining frame: WindowFrame, beside window: ScreenWindow, on side: PairSide
    ) -> JoinTarget {
        target(size: frame.size, beside: window, on: side)
    }

    private static func target(
        size: WindowSize, beside window: ScreenWindow, on side: PairSide
    ) -> JoinTarget {
        JoinTarget(
            other: window, side: side,
            frame: WindowFrame(
                x: side == .right ? window.frame.maxX : window.frame.origin.x - size.width,
                y: window.frame.origin.y, width: size.width, height: size.height))
    }

    private static func overlapVertically(_ first: WindowFrame, _ second: WindowFrame) -> Bool {
        first.origin.y < second.maxY && second.origin.y < first.maxY
    }
}
