import Foundation

/// A short sound that says what became of a pair (ADR 0051).
public enum PairSound: Equatable, Sendable {
    case join
    case part
}

/// What Pairwise needs from the system to take over a drag.
@MainActor
public protocol WindowSystemProviding: AnyObject {
    /// Whether Pairwise has the Accessibility permission.
    var isAccessibilityGranted: Bool { get }

    /// Whether Pairwise has the Screen Recording permission, which a stand-in needs.
    var isScreenRecordingGranted: Bool { get }

    /// Where a partner waits out of sight, or `nil` when the system names no displays.
    var parkingOrigin: ScreenPoint? { get }

    /// How many live frames a second a new stand-in asks for per window; 0 keeps it still.
    var liveFramesPerSecond: Int { get set }

    /// Whether the left mouse button is down now, asked of the system and not of an event.
    var isPrimaryButtonDown: Bool { get }

    /// Where the pointer is now, asked of the system.
    var pointerLocation: ScreenPoint { get }

    /// A monotonic time in seconds, for measuring.
    var uptime: TimeInterval { get }

    /// Asks the system to show the user where to grant the Accessibility permission.
    func requestAccessibility()

    /// Asks the system for the Screen Recording permission.
    func requestScreenRecording()

    /// Makes one stand-in of `first` and `second` side by side, tops level, not yet shown.
    /// Its origin is that of `first`. Calls `completion` later, never during this call.
    func makePairStandIn(
        of first: any MovableWindow, beside second: any MovableWindow,
        completion: @escaping @MainActor (Result<any WindowStandIn, WindowSystemError>) -> Void
    )

    /// The normal windows on screen of other apps, frontmost first.
    func normalWindows() -> [ScreenWindow]

    /// The window with this number, or `nil` when it has gone.
    func window(number: UInt32) -> (any MovableWindow)?

    /// Shows where a window will land, or moves that guide there.
    func showJoinGuide(at frame: WindowFrame)

    /// Takes the guide away, if it shows.
    func hideJoinGuide()

    /// Plays `sound`.
    func play(_ sound: PairSound)

    /// Lights up a seam briefly.
    func flashSeam(at frame: WindowFrame)

    /// Shows a lock at `frame`, or moves or changes it. It takes no mouse events: the hold
    /// sees a press on it first (ADR 0044).
    func showSeamLock(at frame: WindowFrame, isClosed: Bool)

    /// Takes the lock away, if it shows.
    func hideSeamLock()

    /// Calls `handler` every `interval` seconds until `stopWatchingPointer`. It costs little
    /// and asks no app, unlike what `handler` may go on to do.
    /// Postcondition: earlier watching has ended.
    func startWatchingPointer(
        every interval: TimeInterval, _ handler: @escaping @MainActor () -> Void)

    /// Ends the watching; no call to the handler follows.
    func stopWatchingPointer()

    /// The number of the normal window on top at `point`, or `nil` when there is none or it
    /// is one of Pairwise's own. Asks no app.
    func windowNumber(at point: ScreenPoint) -> UInt32?

    /// The window under `point`, or `nil` when there is none Pairwise may follow.
    func window(at point: ScreenPoint) -> (any MovableWindow)?

    /// Asks `decide` about each press, drag and release of the left mouse button; an event
    /// it answers `false` for does not reach any app. Input passes when this fails.
    /// Postcondition: an earlier hold has ended.
    func startHoldingDrags(
        _ decide: @escaping @MainActor (PointerButtonEvent) -> Bool
    ) throws(WindowSystemError)

    /// Ends the hold; all input passes.
    func stopHoldingDrags()

    /// Calls `handler` once per display frame until `stopTicking`, or every `interval`
    /// seconds when the display cannot say.
    /// Postcondition: earlier ticking has ended.
    func startTicking(every interval: TimeInterval, _ handler: @escaping @MainActor () -> Void)

    /// Ends the ticking; no call to the handler follows.
    func stopTicking()
}
