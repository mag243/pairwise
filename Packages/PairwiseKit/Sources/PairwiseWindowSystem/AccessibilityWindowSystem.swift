import AppKit
import ApplicationServices
import PairwiseCore
import os

/// The real window system: the Accessibility API, an event tap, display ticks and
/// ScreenCaptureKit, all on the main actor (ADR 0024).
@MainActor
public final class AccessibilityWindowSystem: WindowSystemProviding {
    private static let logger = Logger(subsystem: "me.m-domain.pairwise", category: "windows")
    private static let defaultLiveFramesPerSecond = 30

    public var partnerBundleIdentifier = "com.apple.finder"
    public var liveFramesPerSecond = AccessibilityWindowSystem.defaultLiveFramesPerSecond
    /// The window `partner(for:)` gives whatever the app, for the stress test (ADR 0027).
    var pinnedPartner: AccessibilityWindow?

    private let access: any SystemAccess
    private var holdingTap: HoldingTap?
    private var ticker: DisplayTicker?
    private var timer: Timer?

    public convenience init() {
        self.init(access: LiveSystemAccess())
    }

    init(access: any SystemAccess) {
        self.access = access
    }

    public var isAccessibilityGranted: Bool { AXIsProcessTrusted() }

    public var isScreenRecordingGranted: Bool { CGPreflightScreenCaptureAccess() }

    public var parkingOrigin: ScreenPoint? {
        PartnerPlacement.parkingOrigin(onDisplays: access.displays())
    }

    public var partnerApps: [PartnerApp] {
        access.regularApps()
            .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }

    public var isPrimaryButtonDown: Bool {
        CGEventSource.buttonState(.combinedSessionState, button: .left)
    }

    public var uptime: TimeInterval { ProcessInfo.processInfo.systemUptime }

    public func requestAccessibility() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    public func requestScreenRecording() {
        CGRequestScreenCaptureAccess()
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
            completion(
                await WindowCapture.standIn(
                    of: [first, second], framesPerSecond: liveFramesPerSecond))
        }
    }

    public func window(at point: ScreenPoint) -> (any MovableWindow)? {
        guard
            let top = WindowServer.topWindow(
                at: point, excludingProcess: access.ownProcess, in: access.onScreenWindows())
        else {
            Self.logger.info("no normal window of another app on top at the pointer")
            return nil
        }
        let app = access.application(top.processID)
        app.limitMessagingTime()
        let elements = app.elements(of: kAXWindowsAttribute)
        let frames = elements.map {
            (try? AccessibilityWindow(element: $0, access: access).frame())
                ?? WindowFrame(x: 0, y: 0, width: 0, height: 0)
        }
        guard let index = WindowMatch.index(of: top.frame, among: frames) else {
            Self.logger.info("the app's \(elements.count) windows do not match the one on top")
            return nil
        }
        return AccessibilityWindow(
            element: elements[index], serverWindowNumber: top.number, access: access)
    }

    public func partner(
        for window: any MovableWindow
    ) throws(WindowSystemError) -> any MovableWindow {
        if let pinnedPartner { return pinnedPartner }
        let dragged = (window as? AccessibilityWindow)?.element
        guard let process = access.processes(bundleIdentifier: partnerBundleIdentifier).first
        else { throw .noPartner }
        let app = access.application(process)
        app.limitMessagingTime()
        let partner = app.elements(of: kAXWindowsAttribute).first { candidate in
            Self.canFollow(candidate) && dragged.map { !$0.isSame(as: candidate) } ?? true
        }
        guard let partner else { throw .noPartner }
        return AccessibilityWindow(element: partner, access: access)
    }

    private static func canFollow(_ window: any AccessibilityElement) -> Bool {
        window.attribute(kAXSubroleAttribute) as? String == kAXStandardWindowSubrole
            && window.attribute(kAXMinimizedAttribute) as? Bool != true
    }

    public func startHoldingDrags(
        _ decide: @escaping @MainActor (PointerButtonEvent) -> Bool
    ) throws(WindowSystemError) {
        stopHoldingDrags()
        let tap = HoldingTap(decide: decide)
        try tap.start()
        holdingTap = tap
        Task { await WindowCapture.prepare() }
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
