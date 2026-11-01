import Foundation

/// What Pairwise needs from the system to follow a drag.
@MainActor
public protocol WindowSystemProviding: AnyObject {
    /// Whether Pairwise has the Accessibility permission.
    var isAccessibilityGranted: Bool { get }

    /// Whether Pairwise has the Screen Recording permission, which a stand-in needs.
    var isScreenRecordingGranted: Bool { get }

    /// Where a partner waits out of sight, or `nil` when the system names no displays.
    var parkingOrigin: ScreenPoint? { get }

    /// The pointer's location now, or `nil` when the system does not tell.
    var pointerLocation: ScreenPoint? { get }

    /// A monotonic time in seconds, for measuring.
    var uptime: TimeInterval { get }

    /// Asks the system to show the user where to grant the Accessibility permission.
    func requestAccessibility()

    /// Asks the system for the Screen Recording permission.
    func requestScreenRecording()

    /// Makes a stand-in of `window`, not yet shown, and calls `completion` with it later,
    /// never during this call. The system takes a moment to give a picture.
    func makeStandIn(
        of window: any MovableWindow,
        completion: @escaping @MainActor (Result<any WindowStandIn, WindowSystemError>) -> Void
    )

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
