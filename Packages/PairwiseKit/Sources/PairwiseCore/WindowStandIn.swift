/// Pictures of windows, in a window of Pairwise's own, that move without waiting on
/// another app (ADR 0024). Not visible until `show`.
@MainActor
public protocol WindowStandIn: AnyObject {
    /// Shows the stand-in with its top left corner at `origin`.
    func show(at origin: ScreenPoint)

    /// Moves the stand-in's top left corner to `origin`.
    func move(to origin: ScreenPoint)

    /// Takes the stand-in off the screen for good.
    func dismiss()
}
