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
    /// How long a seam stays lit after two windows join.
    private static let seamFlashTime = Duration.milliseconds(400)
    /// The system's sounds for a join and a parting (ADR 0051).
    private static let joinSoundName = "Pop"
    private static let partSoundName = "Tink"
    /// How much later the pointer's timer may fire, for the system to save energy.
    private static let pointerTimerTolerance = 0.02

    public var liveFramesPerSecond = AccessibilityWindowSystem.defaultLiveFramesPerSecond
    private let access: any SystemAccess
    /// The only windows that count as normal windows, for the join test, so that it cannot
    /// join a window of the user's (ADR 0027).
    var onlyNormalWindows: Set<UInt32>?
    private let capture: WindowCapture
    private let makeMark: () -> any ScreenMark
    private let makeLock: () -> any SeamLockMark
    private let parkingRecordURL: URL
    private let makeHold: (@escaping @MainActor (PointerButtonEvent) -> Bool) -> any PointerHold
    private var joinGuide: (any ScreenMark)?
    private var seamLock: (any SeamLockMark)?
    private var pointerTimer: Timer?
    private var holdingTap: (any PointerHold)?
    private var ticker: DisplayTicker?
    private var timer: Timer?

    public convenience init() {
        self.init(access: LiveSystemAccess(), captureService: LiveCaptureService())
    }

    init(
        access: any SystemAccess, captureService: any CaptureService,
        makeMark: @escaping () -> any ScreenMark = { JoinMarkPanel() },
        makeLock: @escaping () -> any SeamLockMark = { SeamLockPanel() },
        makeHold: @escaping (@escaping @MainActor (PointerButtonEvent) -> Bool) -> any PointerHold =
            { HoldingTap(decide: $0) },
        parkingRecordURL: URL = AccessibilityWindowSystem.defaultParkingRecordURL
    ) {
        self.parkingRecordURL = parkingRecordURL
        self.access = access
        self.makeMark = makeMark
        self.makeLock = makeLock
        self.makeHold = makeHold
        capture = WindowCapture(service: captureService)
    }

    /// In the app's folder in Application Support, where a new run finds it (ADR 0053).
    static let defaultParkingRecordURL = URL.applicationSupportDirectory
        .appending(path: "me.m-domain.pairwise", directoryHint: .isDirectory)
        .appending(path: "parked-windows.json")

    public var isAccessibilityGranted: Bool { AXIsProcessTrusted() }

    public var isScreenRecordingGranted: Bool { CGPreflightScreenCaptureAccess() }

    public var parkingOrigin: ScreenPoint? {
        PartnerPlacement.parkingOrigin(onDisplays: access.displays())
    }

    public var isPrimaryButtonDown: Bool {
        CGEventSource.buttonState(.combinedSessionState, button: .left)
    }

    public var pointerLocation: ScreenPoint { access.pointerLocation }

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
                await capture.standIn(
                    of: [first, second], framesPerSecond: liveFramesPerSecond))
        }
    }

    public func windowNumber(at point: ScreenPoint) -> UInt32? {
        WindowServer.topWindow(
            at: point, excludingProcess: access.ownProcess, in: access.onScreenWindows()
        )?.number
    }

    public func window(at point: ScreenPoint) -> (any MovableWindow)? {
        guard
            let top = WindowServer.topWindow(
                at: point, excludingProcess: access.ownProcess, in: access.onScreenWindows())
        else {
            Self.logger.info("no normal window of another app on top at the pointer")
            return nil
        }
        return element(of: top)
    }

    public func normalWindows() -> [ScreenWindow] {
        WindowServer.normalWindows(
            excludingProcess: access.ownProcess, in: access.onScreenWindows()
        )
        .filter { onlyNormalWindows?.contains($0.number) ?? true }
        .map { ScreenWindow(number: $0.number, frame: $0.frame, owner: $0.processID) }
    }

    public func window(number: UInt32) -> (any MovableWindow)? {
        access.windowDescription(number)
            .flatMap(WindowServer.window(from:))
            .flatMap(element(of:))
    }

    /// The Accessibility window for a window the window server named: the one of its app
    /// with its size and the closest origin.
    private func element(of window: WindowServer.OnScreenWindow) -> AccessibilityWindow? {
        let app = access.application(window.processID)
        app.limitMessagingTime()
        let elements = app.elements(of: kAXWindowsAttribute)
        let frames = elements.map {
            (try? AccessibilityWindow(element: $0, access: access).frame())
                ?? WindowFrame(x: 0, y: 0, width: 0, height: 0)
        }
        guard let index = WindowMatch.index(of: window.frame, among: frames) else {
            Self.logger.info("the app's \(elements.count) windows do not match the one on top")
            return nil
        }
        return AccessibilityWindow(
            element: elements[index], serverWindowNumber: window.number, access: access)
    }

    public func showJoinGuide(at frame: WindowFrame) {
        let guide = joinGuide ?? makeMark()
        joinGuide = guide
        guide.show(at: frame)
    }

    public func hideJoinGuide() {
        joinGuide?.hide()
        joinGuide = nil
    }

    public func saveParkingRecord(_ record: Data?) {
        do {
            guard let record else {
                if FileManager.default.fileExists(atPath: parkingRecordURL.path) {
                    try FileManager.default.removeItem(at: parkingRecordURL)
                }
                return
            }
            try FileManager.default.createDirectory(
                at: parkingRecordURL.deletingLastPathComponent(),
                withIntermediateDirectories: true)
            try record.write(to: parkingRecordURL, options: .atomic)
        } catch {
            Self.logger.info(
                "the parking record failed: \(String(describing: error), privacy: .public)")
        }
    }

    public func loadParkingRecord() -> Data? {
        try? Data(contentsOf: parkingRecordURL)
    }

    public func play(_ sound: PairSound) {
        let name = sound == .join ? Self.joinSoundName : Self.partSoundName
        NSSound(named: name)?.play()
    }

    public func flashSeam(at frame: WindowFrame) {
        let mark = makeMark()
        mark.show(at: frame)
        Task {
            try? await Task.sleep(for: Self.seamFlashTime)
            mark.hide()
        }
    }

    public func showSeamLock(at frame: WindowFrame, isClosed: Bool) {
        let lock = seamLock ?? makeLock()
        seamLock = lock
        lock.show(at: frame, isClosed: isClosed)
    }

    public func hideSeamLock() {
        seamLock?.hide()
        seamLock = nil
    }

    public func startWatchingPointer(
        every interval: TimeInterval, _ handler: @escaping @MainActor () -> Void
    ) {
        stopWatchingPointer()
        let timer = Timer(timeInterval: interval, repeats: true) { _ in
            // The timer is on the main run loop, added below.
            MainActor.assumeIsolated { handler() }
        }
        timer.tolerance = Self.pointerTimerTolerance
        RunLoop.main.add(timer, forMode: .common)
        pointerTimer = timer
    }

    public func stopWatchingPointer() {
        pointerTimer?.invalidate()
        pointerTimer = nil
    }

    public func startHoldingDrags(
        _ decide: @escaping @MainActor (PointerButtonEvent) -> Bool
    ) throws(WindowSystemError) {
        stopHoldingDrags()
        let tap = makeHold(decide)
        try tap.start()
        holdingTap = tap
        Task { await capture.prepare() }
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
