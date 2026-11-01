import AppKit
import ApplicationServices
import PairwiseCore

/// The real window system: the Accessibility API, a listen-only event tap, display ticks and
/// ScreenCaptureKit, all on the main actor (ADR 0013, 0014).
@MainActor
public final class AccessibilityWindowSystem: WindowSystemProviding {
    public var partnerBundleIdentifier = "com.apple.finder"

    private let systemWide = AXUIElementCreateSystemWide()
    private var tap: PointerTap?
    private var holdingTap: HoldingTap?
    private var ticker: DisplayTicker?
    private var timer: Timer?

    public init() {
        systemWide.limitMessagingTime()
    }

    public var isAccessibilityGranted: Bool { AXIsProcessTrusted() }

    public var isScreenRecordingGranted: Bool { CGPreflightScreenCaptureAccess() }

    public var parkingOrigin: ScreenPoint? {
        PartnerPlacement.parkingOrigin(onDisplays: NSScreen.globalFrames)
    }

    public var partnerApps: [PartnerApp] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0 != .current }
            .compactMap { app in
                guard let identifier = app.bundleIdentifier else { return nil }
                return PartnerApp(
                    bundleIdentifier: identifier, name: app.localizedName ?? identifier)
            }
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public var isPrimaryButtonDown: Bool {
        CGEventSource.buttonState(.combinedSessionState, button: .left)
    }

    public var pointerLocation: ScreenPoint? {
        CGEvent(source: nil).map { ScreenPoint($0.location) }
    }

    public var uptime: TimeInterval { ProcessInfo.processInfo.systemUptime }

    public func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    public func requestScreenRecording() {
        CGRequestScreenCaptureAccess()
    }

    public func makeStandIn(
        of window: any MovableWindow,
        completion: @escaping @MainActor (Result<any WindowStandIn, WindowSystemError>) -> Void
    ) {
        Task { @MainActor in
            guard let window = window as? AccessibilityWindow else {
                completion(.failure(.captureFailed))
                return
            }
            completion(await WindowCapture.standIn(of: [window]))
        }
    }

    public func makePairStandIn(
        of first: any MovableWindow, beside second: any MovableWindow,
        completion: @escaping @MainActor (Result<any WindowStandIn, WindowSystemError>) -> Void
    ) {
        Task { @MainActor in
            guard
                let first = first as? AccessibilityWindow,
                let second = second as? AccessibilityWindow
            else {
                completion(.failure(.captureFailed))
                return
            }
            completion(await WindowCapture.standIn(of: [first, second]))
        }
    }

    public func window(at point: ScreenPoint) -> (any MovableWindow)? {
        var hit: AXUIElement?
        let result = AXUIElementCopyElementAtPosition(
            systemWide, Float(point.x), Float(point.y), &hit)
        guard result == .success, let hit else { return nil }
        // A call from Pairwise to itself would wait on the thread that has to answer it.
        guard hit.processID != ProcessInfo.processInfo.processIdentifier else { return nil }
        let isWindow = hit.attribute(kAXRoleAttribute) as? String == kAXWindowRole
        let element = isWindow ? hit : hit.elementAttribute(kAXWindowAttribute)
        return element.map(AccessibilityWindow.init(element:))
    }

    public func partner(
        for window: any MovableWindow
    ) throws(WindowSystemError) -> any MovableWindow {
        let dragged = (window as? AccessibilityWindow)?.element
        let apps = NSRunningApplication.runningApplications(
            withBundleIdentifier: partnerBundleIdentifier)
        guard let app = apps.first else { throw .noPartner }
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        appElement.limitMessagingTime()
        let windows = appElement.attribute(kAXWindowsAttribute) as? [AXUIElement] ?? []
        let partner = windows.first { candidate in
            Self.canFollow(candidate) && dragged.map { !CFEqual($0, candidate) } ?? true
        }
        guard let partner else { throw .noPartner }
        return AccessibilityWindow(element: partner)
    }

    private static func canFollow(_ window: AXUIElement) -> Bool {
        window.attribute(kAXSubroleAttribute) as? String == kAXStandardWindowSubrole
            && window.attribute(kAXMinimizedAttribute) as? Bool != true
    }

    public func startWatchingPointer(
        _ handler: @escaping @MainActor (PointerButtonEvent) -> Void
    ) throws(WindowSystemError) {
        stopWatchingPointer()
        let tap = PointerTap(handler: handler)
        try tap.start()
        self.tap = tap
    }

    public func stopWatchingPointer() {
        tap?.stop()
        tap = nil
    }

    public func startHoldingDrags(
        _ decide: @escaping @MainActor (PointerButtonEvent) -> Bool
    ) throws(WindowSystemError) {
        stopHoldingDrags()
        let tap = HoldingTap(decide: decide)
        try tap.start()
        holdingTap = tap
    }

    public func stopHoldingDrags() {
        holdingTap?.stop()
        holdingTap = nil
    }

    public func startTicking(
        every interval: TimeInterval, _ handler: @escaping @MainActor () -> Void
    ) {
        stopTicking()
        if let ticker = DisplayTicker(handler: handler) {
            self.ticker = ticker
            return
        }
        let timer = Timer(timeInterval: interval, repeats: true) { _ in
            // The timer is on the main run loop, added below.
            MainActor.assumeIsolated { handler() }
        }
        timer.tolerance = 0
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    public func stopTicking() {
        ticker?.stop()
        ticker = nil
        timer?.invalidate()
        timer = nil
    }
}
