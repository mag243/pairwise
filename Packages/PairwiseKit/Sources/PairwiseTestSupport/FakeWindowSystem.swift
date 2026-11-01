import Foundation
import PairwiseCore

/// A window system in memory: tests set what is on the screen and drive the pointer
/// and the ticks by hand, so nothing needs a permission or waits on real time.
@MainActor
public final class FakeWindowSystem: WindowSystemProviding {
    public var isAccessibilityGranted = true
    public var isScreenRecordingGranted = false
    public var parkingOrigin: ScreenPoint? = ScreenPoint(x: 9999, y: 9999)
    public var pointerLocation: ScreenPoint?
    public var uptime: TimeInterval = 0
    /// The window `window(at:)` returns, wherever is asked.
    public var windowUnderPointer: FakeWindow?
    /// The window `partner(for:)` returns; without one it throws `noPartner`.
    public var partnerWindow: FakeWindow?
    /// When set, `startWatchingPointer` throws this.
    public var watchError: WindowSystemError?
    public var partnerApps: [PartnerApp] = []
    public var partnerBundleIdentifier = "com.apple.finder"
    public private(set) var accessibilityRequests = 0
    public private(set) var screenRecordingRequests = 0
    public private(set) var standInRequests = 0

    private var pointerHandler: (@MainActor (PointerButtonEvent) -> Void)?
    private var tickHandler: (@MainActor () -> Void)?
    private var standInCompletion:
        (@MainActor (Result<any WindowStandIn, WindowSystemError>) -> Void)?

    public init() {}

    public var isWatching: Bool { pointerHandler != nil }
    public var isTicking: Bool { tickHandler != nil }

    public func requestAccessibility() {
        accessibilityRequests += 1
    }

    public func requestScreenRecording() {
        screenRecordingRequests += 1
    }

    public func makeStandIn(
        of window: any MovableWindow,
        completion: @escaping @MainActor (Result<any WindowStandIn, WindowSystemError>) -> Void
    ) {
        standInRequests += 1
        standInCompletion = completion
    }

    public func window(at point: ScreenPoint) -> (any MovableWindow)? {
        windowUnderPointer
    }

    public func partner(
        for window: any MovableWindow
    ) throws(WindowSystemError) -> any MovableWindow {
        guard let partnerWindow else { throw .noPartner }
        return partnerWindow
    }

    public func startWatchingPointer(
        _ handler: @escaping @MainActor (PointerButtonEvent) -> Void
    ) throws(WindowSystemError) {
        if let watchError { throw watchError }
        pointerHandler = handler
    }

    public func stopWatchingPointer() {
        pointerHandler = nil
    }

    public func startTicking(
        every interval: TimeInterval, _ handler: @escaping @MainActor () -> Void
    ) {
        tickHandler = handler
    }

    public func stopTicking() {
        tickHandler = nil
    }

    /// Presses the button at `point`, with the pointer there.
    public func press(at point: ScreenPoint) {
        pointerLocation = point
        pointerHandler?(.pressed(point))
    }

    /// Releases the button at `point`, with the pointer there.
    public func release(at point: ScreenPoint) {
        pointerLocation = point
        pointerHandler?(.released(point))
    }

    /// Gives the last requested stand-in, or the reason there is none.
    public func finishStandIn(with result: Result<any WindowStandIn, WindowSystemError>) {
        standInCompletion?(result)
    }

    /// Hands over the last completion, to call after a later request has been made.
    public func takeStandInCompletion() -> (
        @MainActor (Result<any WindowStandIn, WindowSystemError>) -> Void
    )? {
        defer { standInCompletion = nil }
        return standInCompletion
    }

    /// Runs one tick, when ticking.
    public func tick() {
        tickHandler?()
    }
}
