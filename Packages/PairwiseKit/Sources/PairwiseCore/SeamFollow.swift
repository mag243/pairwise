/// Where the windows of a pair go when their seam moves (ADR 0048).
public enum SeamFollow {
    /// The width below which a window is not asked to go, in points. Apps have their own,
    /// larger minimum.
    public static let smallestWidth = 1.0

    /// Whether going from `start` to `now` moves the edge of the window where its partner is.
    public static func movesSeam(
        from start: WindowFrame, to now: WindowFrame, partnerOn side: PairSide
    ) -> Bool {
        side == .right ? start.maxX != now.maxX : start.origin.x != now.origin.x
    }

    /// Where the seam of `window` is.
    public static func seam(of window: WindowFrame, partnerOn side: PairSide) -> Double {
        side == .right ? window.maxX : window.origin.x
    }

    /// The frame for a window that was at `start` at the press, on `side` of the seam, with
    /// the seam at `x` and its far edge where it was.
    public static func frame(start: WindowFrame, on side: PairSide, seamAt x: Double) -> WindowFrame
    {
        let width = side == .right ? start.maxX - x : x - start.origin.x
        return frame(start: start, on: side, withWidth: max(width, smallestWidth))
    }

    /// The frame for a window that was at `start` at the press, on `side` of the seam, with
    /// `width` and its far edge where it was.
    public static func frame(start: WindowFrame, on side: PairSide, withWidth width: Double)
        -> WindowFrame
    {
        let x = side == .right ? start.maxX - width : start.origin.x
        return WindowFrame(x: x, y: start.origin.y, width: width, height: start.size.height)
    }
}
