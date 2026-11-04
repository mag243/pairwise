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
    /// When set, `startHoldingDrags` throws this.
    public var watchError: WindowSystemError?
    public var isPrimaryButtonDown = true
    public var liveFramesPerSecond = 0
    public var showsPlaceholders = false
    public private(set) var accessibilityRequests = 0
    public private(set) var screenRecordingRequests = 0
    /// Whether the presses and drags sent carry the join key.
    public var isJoinKeyDown = false
    /// Whether the drags sent carry the key that takes the other's height.
    public var isEqualHeightKeyDown = false
    /// Whether the drags sent carry the key that switches which windows can join.
    public var isScopeKeyDown = false
    /// The windows `normalWindows()` and `window(number:)` know about.
    public var knownWindows: [FakeWindow] = []
    public private(set) var guideFrames: [WindowFrame] = []
    public private(set) var isGuideShowing = false
    public private(set) var seamFlashes: [WindowFrame] = []
    public private(set) var sounds: [PairSound] = []
    /// What survives a crash, kept here as a test goes on with a new model.
    public var parkingRecord: Data?
    /// What is kept between runs, here as a test goes on with a new model.
    public var pairsRecord: Data?
    public private(set) var standInRequests = 0
    public private(set) var normalWindowsRequests = 0
    public var pointerLocation = ScreenPoint(x: 0, y: 0)
    public private(set) var outlineFrames: [WindowFrame] = []
    public private(set) var isOutlineShowing = false
    public private(set) var isJoinChoiceInputWatched = false
    public private(set) var lockFrames: [WindowFrame] = []
    public private(set) var isLockShowing = false
    public private(set) var isLockClosed = false
    public private(set) var windowNumberRequests = 0

    private var holdDecision: (@MainActor (PointerButtonEvent) -> Bool)?
    private var tickHandler: (@MainActor () -> Void)?
    private var pointerHandler: (@MainActor () -> Void)?
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

    public func normalWindows() -> [ScreenWindow] {
        normalWindowsRequests += 1
        return knownWindows.compactMap { window in
            window.windowNumber.map {
                ScreenWindow(number: $0, frame: window.currentFrame, owner: window.owner)
            }
        }
    }

    public func window(number: UInt32) -> (any MovableWindow)? {
        knownWindows.first { $0.windowNumber == number }
    }

    public func showJoinGuide(at frame: WindowFrame) {
        guideFrames.append(frame)
        isGuideShowing = true
    }

    public func hideJoinGuide() {
        isGuideShowing = false
    }

    public func showJoinTargetOutline(at frame: WindowFrame) {
        outlineFrames.append(frame)
        isOutlineShowing = true
    }

    public func hideJoinTargetOutline() {
        isOutlineShowing = false
    }

    public func setJoinChoiceInputWatched(_ isWatched: Bool) {
        isJoinChoiceInputWatched = isWatched
    }

    public func saveParkingRecord(_ record: Data?) {
        parkingRecord = record
    }

    public func loadParkingRecord() -> Data? {
        parkingRecord
    }

    public func savePairsRecord(_ record: Data?) {
        pairsRecord = record
    }

    public func loadPairsRecord() -> Data? {
        pairsRecord
    }

    public func windowIdentities() -> [WindowIdentity] {
        knownWindows.compactMap { window in
            window.windowNumber.map {
                WindowIdentity(
                    number: $0, owner: window.owner, app: window.appID,
                    titleKey: window.titleKey, frame: window.currentFrame)
            }
        }
    }

    public func play(_ sound: PairSound) {
        sounds.append(sound)
    }

    public func flashSeam(at frame: WindowFrame) {
        seamFlashes.append(frame)
    }

    public func showSeamLock(at frame: WindowFrame, isClosed: Bool) {
        lockFrames.append(frame)
        isLockShowing = true
        isLockClosed = isClosed
    }

    public func hideSeamLock() {
        isLockShowing = false
    }

    public func startWatchingPointer(
        every interval: TimeInterval, _ handler: @escaping @MainActor () -> Void
    ) {
        pointerHandler = handler
    }

    public func stopWatchingPointer() {
        pointerHandler = nil
    }

    public var isWatchingPointer: Bool { pointerHandler != nil }

    /// Puts the pointer at `point`, and lets the watching see it.
    public func movePointer(to point: ScreenPoint) {
        pointerLocation = point
        pointerHandler?()
    }

    public func windowNumber(at point: ScreenPoint) -> UInt32? {
        windowNumberRequests += 1
        return windowUnderPointer?.windowNumber
    }

    public func window(at point: ScreenPoint) -> (any MovableWindow)? {
        windowUnderPointer
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
        if case .pressed(let point, _) = event {
            return holdDecision?(.pressed(point, isJoinKeyDown: isJoinKeyDown)) ?? true
        }
        if case .dragged(let point, _, _, _) = event {
            return holdDecision?(
                .dragged(
                    point, isJoinKeyDown: isJoinKeyDown,
                    isEqualHeightKeyDown: isEqualHeightKeyDown, isScopeKeyDown: isScopeKeyDown))
                ?? true
        }
        return holdDecision?(event) ?? true
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
