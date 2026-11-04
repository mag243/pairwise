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
    /// How far ahead of the moving edge the other edge may lie, in points.
    private static let snapDistance = 24.0
    /// How far the moving edge may have passed the other edge, in points, as a fast drag
    /// goes past the snap distance between two events.
    private static let passDistance = 48.0
    /// How much of an edge has to show past the windows in front of it, in points: less is
    /// hard to see, with the dragged window near it.
    private static let minimumVisibleEdge = 20.0

    /// An edge of another window that faces the moving edge.
    private struct FacingEdge {
        let side: PairSide
        let position: Double
        /// How far it lies ahead of the moving edge: below zero, the moving edge has passed it.
        let distance: Double
    }

    /// An edge that counts, with what orders it among the others.
    private struct NearEdge {
        let place: JoinPlace
        let isVisible: Bool
        let holdsPointer: Bool
        let distance: Double
        let order: Int

        func comesBefore(_ other: NearEdge) -> Bool {
            if holdsPointer != other.holdsPointer { return holdsPointer }
            return (distance, order) < (other.distance, other.order)
        }
    }

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
    /// pointer at `pointer`: the first of `choices`, or `nil`. The window takes the other's
    /// top, and its height only when `takingHeight` (ADR 0040).
    public static func target(
        for frame: WindowFrame, pointer: ScreenPoint, among windows: [ScreenWindow],
        takingHeight: Bool, heading: MoveDirection?,
        isJoinable: (ScreenWindow) -> Bool = { _ in true }
    ) -> JoinTarget? {
        let places = choices(
            for: frame, pointer: pointer, among: windows, heading: heading, isJoinable: isJoinable)
        return places.first.flatMap { $0 }.map {
            target(at: $0, for: frame, takingHeight: takingHeight)
        }
    }

    /// Where a window at `frame`, moving in `heading`, could join (ADR 0069). `windows` are all
    /// others on screen, frontmost first, also those that are not joinable, as they hide what
    /// is behind them. These are the joinable windows with an edge that counts: first those
    /// whose edge shows, then the hidden ones. A `nil` first says that only hidden edges count.
    /// Without a direction there are none.
    public static func choices(
        for frame: WindowFrame, pointer: ScreenPoint, among windows: [ScreenWindow],
        heading: MoveDirection?, isJoinable: (ScreenWindow) -> Bool
    ) -> [JoinPlace?] {
        guard let heading else { return [] }
        let edges = windows.enumerated().compactMap { index, window -> NearEdge? in
            guard isJoinable(window), overlapVertically(window.frame, frame) else { return nil }
            let facing = edge(of: window, for: frame, heading: heading)
            guard (-passDistance...snapDistance).contains(facing.distance) else { return nil }
            return NearEdge(
                place: JoinPlace(other: window, side: facing.side),
                isVisible: showsEdge(
                    at: facing.position, of: window.frame, within: frame,
                    behind: windows.prefix(index)),
                holdsPointer: window.frame.origin.y <= pointer.y && pointer.y < window.frame.maxY,
                distance: abs(facing.distance), order: index)
        }.sorted { $0.comesBefore($1) }
        let visible = edges.filter(\.isVisible).map(\.place)
        let hidden = edges.filter { !$0.isVisible }.map(\.place)
        return (visible.isEmpty && !hidden.isEmpty ? [nil] : visible) + hidden
    }

    /// The place for a window at `frame` at the place chosen, with the other's height only
    /// when `takingHeight`.
    public static func target(
        at place: JoinPlace, for frame: WindowFrame, takingHeight: Bool
    ) -> JoinTarget {
        target(
            size: WindowSize(
                width: frame.size.width,
                height: takingHeight ? place.other.frame.size.height : frame.size.height),
            beside: place.other, on: place.side)
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

    /// The edge of `window` facing the moving edge of a window at `frame`.
    private static func edge(
        of window: ScreenWindow, for frame: WindowFrame, heading: MoveDirection
    ) -> FacingEdge {
        switch heading {
        case .left:
            return FacingEdge(
                side: .right, position: window.frame.maxX,
                distance: frame.origin.x - window.frame.maxX)
        case .right:
            return FacingEdge(
                side: .left, position: window.frame.origin.x,
                distance: window.frame.origin.x - frame.maxX)
        }
    }

    /// Whether the vertical edge at `position` of a window at `frame` shows past `fronts`,
    /// within the height of the dragged window at `dragged`.
    private static func showsEdge(
        at position: Double, of frame: WindowFrame, within dragged: WindowFrame,
        behind fronts: ArraySlice<ScreenWindow>
    ) -> Bool {
        let covers =
            fronts
            .filter { $0.frame.origin.x < position && position < $0.frame.maxX }
            .map(\.frame)
            .sorted { $0.origin.y < $1.origin.y }
        var reached = max(frame.origin.y, dragged.origin.y)
        for cover in covers {
            if cover.origin.y - reached >= minimumVisibleEdge { return true }
            reached = max(reached, cover.maxY)
        }
        return min(frame.maxY, dragged.maxY) - reached >= minimumVisibleEdge
    }

    private static func overlapVertically(_ first: WindowFrame, _ second: WindowFrame) -> Bool {
        first.origin.y < second.maxY && second.origin.y < first.maxY
    }
}
