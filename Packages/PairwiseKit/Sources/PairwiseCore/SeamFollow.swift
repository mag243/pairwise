/// How a partner follows a window being resized at their seam (ADR 0045).
public enum SeamFollow {
    /// The furthest a growing partner reaches under the held window while it is being resized,
    /// in points, so that lagging behind shows no gap (ADR 0047).
    public static let reachUnderHeldWindow = 40.0
    /// How many frames of the seam's travel a partner reaches ahead, about its lag.
    private static let framesAhead = 3.0
    /// What is left of a reach after a tick, so that it is gone soon after the seam stands.
    private static let reachKept = 0.7
    /// The width below which a partner is not asked to go, in points. Apps have their own,
    /// larger minimum.
    public static let smallestWidth = 1.0

    /// The reach for a partner whose width has just changed by `widthChange`, after the reach
    /// `current`, in whole points. A shrinking partner has none, and a still seam lets it fade.
    public static func reach(after current: Double, widthChange: Double) -> Double {
        guard widthChange >= 0 else { return 0 }
        // A point left would round to itself, and never be gone.
        let kept = current <= 1 ? 0 : (current * reachKept).rounded()
        return max(min(widthChange * framesAhead, reachUnderHeldWindow), kept)
    }

    /// Whether going from `start` to `now` moves the edge of the window where its partner is.
    public static func movesSeam(
        from start: WindowFrame, to now: WindowFrame, partnerOn side: PairSide
    ) -> Bool {
        side == .right ? start.maxX != now.maxX : start.origin.x != now.origin.x
    }

    /// The frame for a partner that was at `start` at the press: against the seam of `held`,
    /// `reach` points under it, and with its far edge where it was.
    public static func partnerFrame(
        start: WindowFrame, partnerOn side: PairSide, beside held: WindowFrame, reach: Double
    ) -> WindowFrame {
        switch side {
        case .right:
            let width = max(start.maxX - (held.maxX - reach), smallestWidth)
            return WindowFrame(
                x: start.maxX - width, y: start.origin.y, width: width,
                height: start.size.height)
        case .left:
            let width = max(held.origin.x + reach - start.origin.x, smallestWidth)
            return WindowFrame(
                x: start.origin.x, y: start.origin.y, width: width, height: start.size.height)
        }
    }

    /// The frame for a partner that was at `start` at the press and has `width`, as its app may
    /// have refused or rounded what was asked: its far edge stays where it was.
    public static func partnerFrame(
        start: WindowFrame, partnerOn side: PairSide, withWidth width: Double
    ) -> WindowFrame {
        let x = side == .right ? start.maxX - width : start.origin.x
        return WindowFrame(x: x, y: start.origin.y, width: width, height: start.size.height)
    }

    /// The frame for `held` that meets `partner`, with its far edge where it is.
    public static func heldFrame(
        _ held: WindowFrame, meeting partner: WindowFrame, partnerOn side: PairSide
    ) -> WindowFrame {
        heldFrame(held, seamAt: side == .right ? partner.origin.x : partner.maxX, partnerOn: side)
    }

    /// The frame for `held` with the seam at `x`, and its far edge where it is.
    public static func heldFrame(
        _ held: WindowFrame, seamAt x: Double, partnerOn side: PairSide
    ) -> WindowFrame {
        switch side {
        case .right:
            return WindowFrame(
                x: held.origin.x, y: held.origin.y, width: x - held.origin.x,
                height: held.size.height)
        case .left:
            return WindowFrame(
                x: x, y: held.origin.y, width: held.maxX - x, height: held.size.height)
        }
    }

    /// Where the seam of `held` is.
    public static func seam(of held: WindowFrame, partnerOn side: PairSide) -> Double {
        side == .right ? held.maxX : held.origin.x
    }
}
