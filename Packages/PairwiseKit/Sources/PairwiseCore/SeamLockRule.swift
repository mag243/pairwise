/// Where two windows of a pair meet. Its ends are those of the part both windows share.
/// Invariant: `top` lies above `bottom`.
public struct Seam: Equatable, Sendable {
    /// How far apart two edges may be to still make a seam, in points, as an app can round
    /// a window's place or size.
    private static let tolerance = 4.0

    public let x: Double
    public let top: Double
    public let bottom: Double

    /// Precondition: `top` is less than `bottom`.
    public init(x: Double, top: Double, bottom: Double) {
        precondition(top < bottom, "top is less than bottom")
        self.x = x
        self.top = top
        self.bottom = bottom
    }

    /// The seam of two windows, or `nil` when they do not stand side by side.
    public static func between(left: WindowFrame, right: WindowFrame) -> Seam? {
        let top = max(left.origin.y, right.origin.y)
        let bottom = min(left.maxY, right.maxY)
        guard abs(left.maxX - right.origin.x) <= tolerance, top < bottom else { return nil }
        return Seam(x: left.maxX, top: top, bottom: bottom)
    }

    /// The seam's middle.
    public var middle: ScreenPoint { ScreenPoint(x: x, y: (top + bottom) / 2) }

    /// The seam as an area of `width`, centred on it.
    public func frame(width: Double) -> WindowFrame {
        WindowFrame(x: x - width / 2, y: top, width: width, height: bottom - top)
    }
}

/// A lock on a seam: closed on a pair, to click to end it, and open on two windows side by
/// side, to click to join them (ADR 0044).
public struct SeamLock: Equatable, Sendable {
    /// The two windows, with their sides, whether they are a pair yet or not.
    public let pair: WindowPair
    /// Where the lock shows.
    public let frame: WindowFrame
    public let isClosed: Bool
}

/// When a seam shows its lock.
public enum SeamLockRule {
    /// How close to a seam the pointer brings up the lock, in points.
    private static let showDistance = 16.0
    /// How far from a seam a showing lock stays, in points. Further out than `showDistance`,
    /// so that it does not flicker at the border.
    private static let keepDistance = 28.0
    /// The width and height of the lock, in points.
    private static let lockSize = 28.0

    /// The lock to show with the pointer at `pointer`, among `windows`, frontmost first, or
    /// `nil`. A lock shows only when its two windows are on top both at the pointer and at
    /// the lock's place, so it never lies over another window. An open lock shows only for
    /// windows that `scope` lets join.
    public static func lock(
        pointer: ScreenPoint, pairs: [WindowPair], windows: [ScreenWindow], scope: JoinScope,
        isShowing: Bool
    ) -> SeamLock? {
        let search = Search(
            pointer: pointer, windows: windows,
            distance: isShowing ? keepDistance : showDistance)
        return closedLock(pairs: pairs, search)
            ?? openLock(pairs: pairs, scope: scope, search)
    }

    private struct Search {
        let pointer: ScreenPoint
        let windows: [ScreenWindow]
        let distance: Double
    }

    private static func closedLock(pairs: [WindowPair], _ search: Search) -> SeamLock? {
        for pair in pairs {
            guard
                let left = search.windows.first(where: { $0.number == pair.left }),
                let right = search.windows.first(where: { $0.number == pair.right }),
                let lock = lock(left: left, right: right, isClosed: true, search)
            else { continue }
            return lock
        }
        return nil
    }

    /// The window under the pointer and any free window beside it.
    private static func openLock(
        pairs: [WindowPair], scope: JoinScope, _ search: Search
    ) -> SeamLock? {
        let isFree = { (window: ScreenWindow) in
            !pairs.contains { $0.left == window.number || $0.right == window.number }
        }
        guard
            let top = search.windows.first(where: { $0.frame.contains(search.pointer) }),
            isFree(top)
        else { return nil }
        let others = JoinRule.candidates(for: top.number, among: search.windows, scope: scope)
            .filter(isFree)
        for other in others {
            if let lock = lock(left: top, right: other, isClosed: false, search)
                ?? lock(left: other, right: top, isClosed: false, search)
            {
                return lock
            }
        }
        return nil
    }

    private static func lock(
        left: ScreenWindow, right: ScreenWindow, isClosed: Bool, _ search: Search
    ) -> SeamLock? {
        let pointer = search.pointer
        let pair = WindowPair(left: left.number, right: right.number)
        guard
            let seam = Seam.between(left: left.frame, right: right.frame),
            seam.bottom - seam.top >= lockSize,
            abs(pointer.x - seam.x) <= search.distance,
            pointer.y >= seam.top, pointer.y <= seam.bottom,
            isOnTop(pair, at: pointer, among: search.windows),
            isOnTop(pair, at: seam.middle, among: search.windows)
        else { return nil }
        return SeamLock(pair: pair, frame: frame(at: seam.middle), isClosed: isClosed)
    }

    private static func isOnTop(
        _ pair: WindowPair, at point: ScreenPoint, among windows: [ScreenWindow]
    ) -> Bool {
        guard let top = windows.first(where: { $0.frame.contains(point) }) else { return false }
        return top.number == pair.left || top.number == pair.right
    }

    private static func frame(at middle: ScreenPoint) -> WindowFrame {
        WindowFrame(
            x: middle.x - lockSize / 2, y: middle.y - lockSize / 2, width: lockSize,
            height: lockSize)
    }
}
