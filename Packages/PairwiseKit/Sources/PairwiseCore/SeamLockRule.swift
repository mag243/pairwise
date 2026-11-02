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

/// A lock on a seam, to click to end the pair (ADR 0042).
public struct SeamLock: Equatable, Sendable {
    public let pair: WindowPair
    /// Where the lock shows.
    public let frame: WindowFrame
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
    /// `nil`. A pair shows one only when it is on top both at the pointer and at the lock's
    /// place, so a lock never lies over another window.
    public static func lock(
        pointer: ScreenPoint, pairs: [WindowPair], windows: [ScreenWindow], isShowing: Bool
    ) -> SeamLock? {
        let distance = isShowing ? keepDistance : showDistance
        let frames = Dictionary(windows.map { ($0.number, $0.frame) }) { first, _ in first }
        for pair in pairs {
            guard
                let left = frames[pair.left], let right = frames[pair.right],
                let seam = Seam.between(left: left, right: right),
                abs(pointer.x - seam.x) <= distance,
                pointer.y >= seam.top, pointer.y <= seam.bottom,
                isOnTop(pair, at: pointer, among: windows),
                isOnTop(pair, at: seam.middle, among: windows)
            else { continue }
            return SeamLock(pair: pair, frame: frame(at: seam.middle))
        }
        return nil
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
