/// Where the seam of a pair can go, as learned from the partner's answers during a drag
/// (ADR 0046). Apps do not tell their limits in advance.
public struct SeamLimits: Equatable, Sendable {
    /// How many times in a row a partner gives the same width for it to count as a limit. An
    /// app that lags changes its width as it catches up.
    public static let answersForALimit = 3
    /// How far a width may be from what was asked and still count as an answer, in points, as
    /// an app can round it to whole characters.
    private static let roundingTolerance = 24.0

    private var least: Double?
    private var most: Double?
    private var lastRefusal: Double?
    private var refusals = 0

    public init() {}

    /// Notes that a partner that was at `start` at the press, asked for the width `asked`,
    /// ended up with `reached`.
    public mutating func note(
        asked: Double, reached: Double, start: WindowFrame, partnerOn side: PairSide
    ) {
        guard abs(reached - asked) > Self.roundingTolerance else {
            lastRefusal = nil
            refusals = 0
            return
        }
        refusals = reached == lastRefusal ? refusals + 1 : 1
        lastRefusal = reached
        guard refusals >= Self.answersForALimit else { return }
        let isAtMinimum = reached > asked
        switch side {
        case .right:
            let seam = start.maxX - reached
            if isAtMinimum { most = seam } else { least = seam }
        case .left:
            let seam = start.origin.x + reached
            if isAtMinimum { least = seam } else { most = seam }
        }
    }

    /// Whether the seam can be at `x`.
    public func allows(seamAt x: Double) -> Bool {
        clamped(seamAt: x) == x
    }

    /// The place closest to `x` where the seam can be.
    public func clamped(seamAt x: Double) -> Double {
        var result = x
        if let least { result = max(result, least) }
        if let most { result = min(result, most) }
        return result
    }
}
