import PairwiseCore

/// A stand-in in memory, which records what was done to it.
@MainActor
public final class FakeStandIn: WindowStandIn {
    public private(set) var shownAt: ScreenPoint?
    public private(set) var stillShownAt: ScreenPoint?
    public private(set) var seams: [Double] = []
    public private(set) var moves: [ScreenPoint] = []
    public private(set) var isDismissed = false
    public var liveFrames: [Int] = []
    /// Runs during each move, to let a test advance time.
    public var duringMove: (() -> Void)?

    public init() {}

    public func show(at origin: ScreenPoint) {
        shownAt = origin
    }

    public func showStill(at origin: ScreenPoint) {
        stillShownAt = origin
    }

    public func setSeam(atOffset offset: Double) {
        seams.append(offset)
    }

    public func move(to origin: ScreenPoint) {
        moves.append(origin)
        duringMove?()
    }

    public func dismiss() {
        isDismissed = true
    }
}
