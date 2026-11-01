/// Where a partner goes beside the window it follows.
public enum PartnerPlacement {
    /// The partner's top left corner: against the right edge of a window at `origin`
    /// with size `size`, with its top level.
    public static func origin(besideWindowAt origin: ScreenPoint, size: WindowSize) -> ScreenPoint {
        ScreenPoint(x: origin.x + size.width, y: origin.y)
    }
}
