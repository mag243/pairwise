/// Why something asked of the window system did not happen. None of these is a
/// programmer error: they come from the user's settings or from what other apps do.
public enum WindowSystemError: Error, Equatable, Sendable {
    /// Pairwise does not have the Accessibility permission.
    case accessibilityDenied
    /// The system would not give Pairwise an event tap.
    case eventTapUnavailable
    /// The window has closed.
    case windowGone
    /// The window's app does not allow the window to be moved.
    case windowRefused
    /// The window's app did not answer in time; a later try may work.
    case windowBusy
    /// There is no window to follow the dragged one.
    case noPartner
}
