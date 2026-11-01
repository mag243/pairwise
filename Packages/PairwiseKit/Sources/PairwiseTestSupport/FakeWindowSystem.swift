import Foundation
import PairwiseCore

/// A window system in memory: tests set what is on the screen and send the button
/// events and the ticks by hand, so nothing needs a permission or waits on real time.
@MainActor
public final class FakeWindowSystem: WindowSystemProviding {
    public var isAccessibilityGranted = true
    public var isScreenRecordingGranted = false
    public var parkingOrigin: ScreenPoint? = ScreenPoint(x: 9999, y: 9999)
    public var uptime: TimeInterval = 0
    /// The window `window(at:)` returns, wherever is asked.
    public var windowUnderPointer: FakeWindow?
    /// The window `partner(for:)` returns; without one it throws `noPartner`.
    public var partnerWindow: FakeWindow?
    /// When set, `startHoldingDrags` throws this.
    public var watchError: WindowSystemError?
    public var partnerApps: [PartnerApp] = []
    public var isPrimaryButtonDown = true
    public var partnerBundleIdentifier = "com.apple.finder"
    public private(set) var accessibilityRequests = 0
    public private(set) var screenRecordingRequests = 0
    public private(set) var standInRequests = 0

    private var holdDecision: (@MainActor (PointerButtonEvent) -> Bool)?
    private var tickHandler: (@MainActor () -> Void)?
    private var standInCompletion:
        (@MainActor (Result<any WindowStandIn, WindowSystemError>) -> Void)?

    public init() {}

    public var isTicking: Bool { tickHandler != nil }

    public func requestAccessibility() {
        accessibilityRequests += 1
    }

    public func requestScreenRecording() {
        screenRecordingRequests += 1
    }

    public func makePairStandIn(
        of first: any MovableWindow, beside second: any MovableWindow,
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

    public func startHoldingDrags(
        _ decide: @escaping @MainActor (PointerButtonEvent) -> Bool
    ) throws(WindowSystemError) {
        if let watchError { throw watchError }
        holdDecision = decide
    }

    public func stopHoldingDrags() {
        holdDecision = nil
    }

    public var isHolding: Bool { holdDecision != nil }

    /// Sends `event` through the hold, and returns whether it passes.
    public func send(_ event: PointerButtonEvent) -> Bool {
        holdDecision?(event) ?? true
    }

    public func startTicking(
        every interval: TimeInterval, _ handler: @escaping @MainActor () -> Void
    ) {
        tickHandler = handler
    }

    public func stopTicking() {
        tickHandler = nil
    }

    /// Gives the last requested stand-in, or the reason there is none.
    public func finishStandIn(with result: Result<any WindowStandIn, WindowSystemError>) {
        standInCompletion?(result)
    }

    /// Runs one tick, when ticking.
    public func tick() {
        tickHandler?()
    }
}
