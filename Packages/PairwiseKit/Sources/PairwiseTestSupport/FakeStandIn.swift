import PairwiseCore

/// A stand-in in memory, which records what was done to it.
@MainActor
public final class FakeStandIn: WindowStandIn {
    public private(set) var shownAt: ScreenPoint?
    public private(set) var moves: [ScreenPoint] = []
    public private(set) var isDismissed = false
    /// Runs during each move, to let a test advance time.
    public var duringMove: (() -> Void)?

    public init() {}

    public func show(at origin: ScreenPoint) {
        shownAt = origin
    }

    public func move(to origin: ScreenPoint) {
        moves.append(origin)
        duringMove?()
    }

    public func dismiss() {
        isDismissed = true
    }
}
