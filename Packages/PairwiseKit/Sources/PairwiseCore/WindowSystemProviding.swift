import Foundation

/// What Pairwise needs from the system to follow a drag.
@MainActor
public protocol WindowSystemProviding: AnyObject {
    /// Whether Pairwise has the Accessibility permission.
    var isAccessibilityGranted: Bool { get }

    /// The pointer's location now, or `nil` when the system does not tell.
    var pointerLocation: ScreenPoint? { get }

    /// A monotonic time in seconds, for measuring.
    var uptime: TimeInterval { get }

    /// Asks the system to show the user where to grant the Accessibility permission.
    func requestAccessibility()

    /// The window under `point`, or `nil` when there is none Pairwise may follow.
    func window(at point: ScreenPoint) -> (any MovableWindow)?

    /// A window to follow `window`, not `window` itself.
    func partner(for window: any MovableWindow) throws(WindowSystemError) -> any MovableWindow

    /// Calls `handler` for each press and release of the left mouse button, without
    /// holding up or changing the input.
    /// Postcondition: an earlier watch has ended.
    func startWatchingPointer(
        _ handler: @escaping @MainActor (PointerButtonEvent) -> Void
    ) throws(WindowSystemError)

    /// Ends the watch; no call to the handler follows.
    func stopWatchingPointer()

    /// Calls `handler` every `interval` seconds until `stopTicking`.
    /// Postcondition: earlier ticking has ended.
    func startTicking(every interval: TimeInterval, _ handler: @escaping @MainActor () -> Void)

    /// Ends the ticking; no call to the handler follows.
    func stopTicking()
}
