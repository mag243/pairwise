import Foundation
import Observation
import PairwiseCore
import os

/// Moves a window and its partner as one window of Pairwise's own (ADR 0024). A press on
/// another app's window starts on a picture of both, and its drag events pass. Once macOS
/// has moved the window, they are held back (ADR 0032), and with the picture there a panel
/// takes over from both windows; the release puts them where the panel is. Without the Screen Recording permission
/// nothing is taken over, and macOS drags the one window (ADR 0028).
@MainActor
@Observable
public final class PairDragModel {
    static let tickInterval: TimeInterval = 1.0 / 120
    /// How long a busy app gets to answer at the release, with the panel up.
    /// How wide a seam lights up, in points.
    static let seamWidth = 6.0
    static let placingPatience: TimeInterval = 0.5
    /// How long the panel stays over placed windows, for their apps to draw them.
    static let settleTime: TimeInterval = 0.05
    /// How long the system may take to report a pressed button as down.
    private static let buttonReportTime: TimeInterval = 0.25
    static let logger = Logger(subsystem: "me.m-domain.pairwise", category: "pair-drag")

    /// How many live frames a second the pictures show during a drag; 0 keeps them still.
    public var liveFramesPerSecond: Int {
        didSet { system.liveFramesPerSecond = liveFramesPerSecond }
    }

    /// Which windows the join key joins; the scope key gives the other choice (ADR 0043).
    public var joinScope = JoinScope.anyWindow
    /// Whether a join and a parting by the user make a sound (ADR 0051).
    public var playsSounds = true

    public internal(set) var isAccessibilityGranted: Bool
    public internal(set) var isScreenRecordingGranted: Bool
    public private(set) var isRunning = false
    /// Why the last start or drag did not work; cleared by the next one.
    public internal(set) var problem: WindowSystemError?
    /// What became of the last press, in words for the log and the stress test.
    public internal(set) var lastPressOutcome = ""
    /// The measurements of the last drag that moved the panel.
    public internal(set) var lastDrag: DragReport?

    @ObservationIgnored let system: any WindowSystemProviding
    /// The window of this press, when it is in no pair: the join key can still come during
    /// the drag (ADR 0039).
    @ObservationIgnored var freeWindowPressed: UInt32?
    @ObservationIgnored var book = PairBook()
    /// The windows in `book`, by number.
    @ObservationIgnored var pairedWindows: [UInt32: any MovableWindow] = [:]
    @ObservationIgnored var drag = PairDrag.none
    @ObservationIgnored var stats = DragStats()
    @ObservationIgnored var lockWatch = SeamLockWatch()
    @ObservationIgnored var togetherWatch = TogetherWatch()
    /// Whether a record of parked windows is kept (ADR 0053).
    @ObservationIgnored var isParkingRecorded = false
    @ObservationIgnored var hasSeenButtonDown = false
    @ObservationIgnored private var pressTime: TimeInterval = 0
    /// Tells a picture that arrives late from the one this press asked for.
    @ObservationIgnored var request = 0

    public init(system: any WindowSystemProviding) {
        self.system = system
        liveFramesPerSecond = system.liveFramesPerSecond
        isAccessibilityGranted = system.isAccessibilityGranted
        isScreenRecordingGranted = system.isScreenRecordingGranted
    }

    /// Starts taking over drags; a failure lands in `problem`, and all input passes.
    public func start() {
        refreshPermissions()
        guard system.isAccessibilityGranted else {
            problem = .accessibilityDenied
            return
        }
        putBackParkedWindows()
        guard system.isScreenRecordingGranted else {
            problem = .screenRecordingDenied
            return
        }
        do {
            try system.startHoldingDrags { [weak self] event in self?.decide(event) ?? true }
            problem = nil
            isRunning = true
            updatePointerWatching()
        } catch {
            problem = error
        }
    }

    /// Stops taking over drags, with parked windows put back; all input passes.
    public func stop() {
        putWindowsBack()
        endDrag()
        system.stopHoldingDrags()
        isRunning = false
        updatePointerWatching()
    }

    /// Whether `event` passes. Only drag events after the window has moved are withheld.
    private func decide(_ event: PointerButtonEvent) -> Bool {
        switch event {
        case .pressed(let point, let isJoinKeyDown):
            if pressLock(at: point) { return false }
            press(at: point, isJoinKeyDown: isJoinKeyDown)
            return true
        case .dragged(let point, let isJoinKeyDown, let isEqualHeightKeyDown, let isScopeKeyDown):
            return !holdsDrag(
                at: point, isJoinKeyDown: isJoinKeyDown,
                isEqualHeightKeyDown: isEqualHeightKeyDown, isScopeKeyDown: isScopeKeyDown)
        case .released(let point):
            if releaseLock(at: point) { return false }
            release(at: point)
            return true
        case .keysChanged(let isJoinKeyDown, let isEqualHeightKeyDown, let isScopeKeyDown):
            keysChanged(
                isJoinKeyDown: isJoinKeyDown, isEqualHeightKeyDown: isEqualHeightKeyDown,
                isScopeKeyDown: isScopeKeyDown)
            return true
        }
    }

    private func press(at point: ScreenPoint, isJoinKeyDown: Bool) {
        putWindowsBack()
        endDrag()
        problem = nil
        let before = system.uptime
        hasSeenButtonDown = false
        pressTime = before
        freeWindowPressed = nil
        let outcome = takeOverPress(at: point, isJoinKeyDown: isJoinKeyDown)
        lastPressOutcome = outcome
        let elapsed = system.uptime - before
        Self.logger.info("press: \(outcome, privacy: .public), deciding took \(elapsed) s")
    }

    /// Says what became of the press, for the log. A window in no pair costs only the window
    /// number, as most presses are on such windows (ADR 0033).
    private func takeOverPress(at point: ScreenPoint, isJoinKeyDown: Bool) -> String {
        guard let number = system.windowNumber(at: point) else {
            return "no window under the pointer"
        }
        if isJoinKeyDown { return startJoining(number, pointer: point) }
        guard
            let partnerEntry = book.partner(of: number),
            let window = pairedWindows[number],
            let partnerWindow = pairedWindows[partnerEntry.window]
        else {
            freeWindowPressed = number
            return "not in a pair"
        }
        guard window.isAvailable, partnerWindow.isAvailable else {
            endPair(of: number)
            return "the pair ended: a window is gone, minimized or full screen"
        }
        guard
            let partnerFrame = partnerWindow.serverFrame() ?? (try? partnerWindow.frame()),
            let frame = window.serverFrame() ?? (try? window.frame())
        else { return "a window does not answer" }
        let partner = PairDrag.Partner(
            window: partnerWindow, origin: partnerFrame.origin, size: partnerFrame.size,
            side: partnerEntry.side)
        drag = .pressed(
            PairDrag.Pressed(
                number: number, window: window, partner: partner, startTime: system.uptime,
                frame: frame,
                pointer: point, lastPointer: point))
        system.startTicking(every: Self.tickInterval) { [weak self] in self?.tick() }
        let current = request
        let first = partner.side == .right ? window : partnerWindow
        let second = partner.side == .right ? partnerWindow : window
        system.makePairStandIn(of: first, beside: second) { [weak self] result in
            guard let self, current == request else { return }
            receive(result)
        }
        return "watching"
    }

    private func receive(_ result: Result<any WindowStandIn, WindowSystemError>) {
        if case .resizingSeam(let resizing) = drag {
            receive(result, for: resizing)
            return
        }
        guard case .pressed(var pressed) = drag else { return }
        let elapsed = system.uptime - pressed.startTime
        Self.logger.info(
            "pictures after \(elapsed) s, window moved already \(pressed.hasWindowMoved)")
        switch result {
        case .failure(let error):
            Self.logger.info("no pictures: \(String(describing: error), privacy: .public)")
            problem = error
            letDragPass()
        case .success(let standIn):
            pressed.standIn = standIn
            drag = .pressed(pressed)
            if pressed.hasWindowMoved { takeOver(pressed, standIn: standIn) }
        }
    }

    /// Sees what macOS made of the press. Without the window server's place this asks the
    /// app, as for any window it does not tell about.
    private func watch(_ pressed: PairDrag.Pressed) {
        if !pressed.hasWindowMoved, startFollowingSeamIfPartnerIsHeld(pressed) { return }
        guard
            !pressed.hasWindowMoved,
            let now = pressed.window.serverFrame() ?? (try? pressed.window.frame())
        else { return }
        if DragHoldRule.isResize(from: pressed.frame, to: now) {
            if SeamFollow.movesSeam(from: pressed.frame, to: now, partnerOn: pressed.partner.side) {
                startFollowingSeam(pressed)
            } else {
                letDragPass()
            }
        } else if DragHoldRule.isMove(from: pressed.frame, to: now) {
            var moved = pressed
            moved.hasWindowMoved = true
            drag = .pressed(moved)
            if let standIn = moved.standIn { takeOver(moved, standIn: standIn) }
        }
    }

    /// The panel shows before the windows leave, so the place does not flash empty.
    private func takeOver(_ pressed: PairDrag.Pressed, standIn: any WindowStandIn) {
        let now = system.uptime
        let moving = PairDrag.Moving(
            number: pressed.number, window: pressed.window, partner: pressed.partner,
            standIn: standIn,
            frame: pressed.frame, pointer: pressed.pointer, startTime: now,
            panelDelay: now - pressed.startTime, lastPointer: pressed.lastPointer)
        standIn.show(at: moving.panelOrigin(forPointer: pressed.lastPointer))
        stats = DragStats()
        drag = .moving(moving)
    }

    /// Calls to the apps happen here and not on an event, since an event that waits holds
    /// up all input.
    func tick() {
        switch drag {
        case .none, .passing, .clickingLock:
            break
        case .closingLock(let lock):
            closeLock(lock)
        case .resizingSeam(let resizing):
            tick(resizing)
        case .pressed(let pressed):
            tick(pressed)
        case .moving(let moving):
            tick(moving)
        case .joining(let joining):
            if isButtonLetGo {
                release(at: joining.pointer)
            } else {
                watch(joining)
            }
        case .placing(let placing):
            place(placing)
        case .settling(_, let until):
            if system.uptime >= until { endDrag() }
        }
    }

    private func tick(_ pressed: PairDrag.Pressed) {
        if isButtonLetGo {
            release(at: pressed.lastPointer)
        } else {
            watch(pressed)
        }
    }

    private func tick(_ moving: PairDrag.Moving) {
        if isButtonLetGo {
            release(at: moving.lastPointer)
        } else if moving.wantsParting {
            part(moving)
        } else {
            park(moving)
        }
    }

    /// A release the tap missed. The tap sees a press before the system counts the button
    /// as down, so up means let go only once it has been down, or after some time.
    var isButtonLetGo: Bool {
        if system.isPrimaryButtonDown {
            hasSeenButtonDown = true
            return false
        }
        return hasSeenButtonDown || system.uptime - pressTime >= Self.buttonReportTime
    }
}
