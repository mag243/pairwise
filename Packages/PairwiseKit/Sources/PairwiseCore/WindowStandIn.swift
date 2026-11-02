/// Pictures of windows, in a window of Pairwise's own, that move without waiting on
/// another app (ADR 0024). Not visible until `show`.
@MainActor
public protocol WindowStandIn: AnyObject {
    /// Shows the stand-in with its top left corner at `origin`.
    func show(at origin: ScreenPoint)

    /// Shows the stand-in with its top left corner at `origin`, for a resize at the seam: live
    /// frames, when it has them, may have other sizes than the pictures (ADR 0049).
    func showForSeam(at origin: ScreenPoint)

    /// Puts the seam between two pictures at `offset` from the left edge, each picture keeping
    /// its far edge, as a resize at the seam does (ADR 0048).
    func setSeam(atOffset offset: Double)

    /// Moves the stand-in's top left corner to `origin`.
    func move(to origin: ScreenPoint)

    /// Takes the stand-in off the screen for good.
    func dismiss()

    /// How many live frames showed a change so far, per window pictured.
    var liveFrames: [Int] { get }
}
