/// Where a partner goes beside the window it follows, and where it waits out of sight.
public enum PartnerPlacement {
    /// How much of a parked window stays on screen; the system keeps a window reachable.
    private static let parkedVisibleEdge = 1.0

    /// The partner's top left corner: against the right edge of a window at `origin`
    /// with size `size`, with its top level.
    public static func origin(besideWindowAt origin: ScreenPoint, size: WindowSize) -> ScreenPoint {
        ScreenPoint(x: origin.x + size.width, y: origin.y)
    }

    /// The partner's top left corner on `side` of a window at `origin` with size `size`, with
    /// its top level.
    public static func origin(
        besideWindowAt origin: ScreenPoint, size: WindowSize, partnerSize: WindowSize,
        on side: PairSide
    ) -> ScreenPoint {
        switch side {
        case .right: ScreenPoint(x: origin.x + size.width, y: origin.y)
        case .left: ScreenPoint(x: origin.x - partnerSize.width, y: origin.y)
        }
    }

    /// The top left corner of a parked partner: at the bottom right of all `displays`,
    /// or `nil` without displays. Display frames are in global screen coordinates.
    public static func parkingOrigin(onDisplays displays: [WindowFrame]) -> ScreenPoint? {
        guard
            let right = displays.map(\.maxX).max(),
            let bottom = displays.map(\.maxY).max()
        else { return nil }
        return ScreenPoint(x: right - parkedVisibleEdge, y: bottom - parkedVisibleEdge)
    }
}
