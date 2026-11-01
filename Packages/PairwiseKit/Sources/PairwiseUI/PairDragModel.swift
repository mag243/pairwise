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
    private static let tickInterval: TimeInterval = 1.0 / 120
    /// How long a busy app gets to answer at the release, with the panel up.
    static let placingPatience: TimeInterval = 0.5
    /// How long the panel stays over placed windows, for their apps to draw them.
    static let settleTime: TimeInterval = 0.05
    /// How long the system may take to report a pressed button as down.
    private static let buttonReportTime: TimeInterval = 0.25
    static let logger = Logger(subsystem: "me.m-domain.pairwise", category: "pair-drag")

    /// The running apps a partner can come from; read again by `refreshPermissions`.
    public internal(set) var partnerApps: [PartnerApp]
    /// The app the next drag takes its partner from.
    public var partnerBundleIdentifier: String {
        didSet { system.partnerBundleIdentifier = partnerBundleIdentifier }
    }

    /// How many live frames a second the pictures show during a drag; 0 keeps them still.
    public var liveFramesPerSecond: Int {
        didSet { system.liveFramesPerSecond = liveFramesPerSecond }
    }

    public internal(set) var isAccessibilityGranted: Bool
    public internal(set) var isScreenRecordingGranted: Bool
    public private(set) var isRunning = false
    /// Why the last start or drag did not work; cleared by the next one.
    public internal(set) var problem: WindowSystemError?
    /// What became of the last press, in words for the log and the stress test.
    public private(set) var lastPressOutcome = ""
    /// The measurements of the last drag that moved the panel.
    public internal(set) var lastDrag: DragReport?

    @ObservationIgnored let system: any WindowSystemProviding
    @ObservationIgnored var drag = PairDrag.none
    @ObservationIgnored var stats = DragStats()
    @ObservationIgnored private var hasSeenButtonDown = false
    @ObservationIgnored private var pressTime: TimeInterval = 0
    /// Tells a picture that arrives late from the one this press asked for.
    @ObservationIgnored var request = 0

    public init(system: any WindowSystemProviding) {
        self.system = system
        partnerApps = system.partnerApps
        partnerBundleIdentifier = system.partnerBundleIdentifier
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
        guard system.isScreenRecordingGranted else {
            problem = .screenRecordingDenied
            return
        }
        do {
            try system.startHoldingDrags { [weak self] event in self?.decide(event) ?? true }
            problem = nil
            isRunning = true
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
    }

    /// Whether `event` passes. Only drag events after the window has moved are withheld.
    private func decide(_ event: PointerButtonEvent) -> Bool {
        switch event {
        case .pressed(let point):
            press(at: point)
            return true
        case .dragged(let point):
            return !holdsDrag(at: point)
        case .released(let point):
            release(at: point)
            return true
        }
    }

    private func press(at point: ScreenPoint) {
        putWindowsBack()
        endDrag()
        problem = nil
        let before = system.uptime
        hasSeenButtonDown = false
        pressTime = before
        let outcome = takeOverPress(at: point)
        lastPressOutcome = outcome
        let elapsed = system.uptime - before
        Self.logger.info("press: \(outcome, privacy: .public), deciding took \(elapsed) s")
    }

    /// Says what became of the press, for the log.
    private func takeOverPress(at point: ScreenPoint) -> String {
        guard let window = system.window(at: point) else { return "no window under the pointer" }
        guard let frame = window.serverFrame() ?? (try? window.frame()) else {
            return "the window gave no frame"
        }
        guard let partner = try? system.partner(for: window) else { return "no partner" }
        drag = .pressed(
            PairDrag.Pressed(
                window: window, partner: partner, startTime: system.uptime, frame: frame,
                pointer: point, lastPointer: point))
        system.startTicking(every: Self.tickInterval) { [weak self] in self?.tick() }
        let current = request
        system.makePairStandIn(of: window, beside: partner) { [weak self] result in
            guard let self, current == request else { return }
            receive(result)
        }
        return "watching"
    }

    private func receive(_ result: Result<any WindowStandIn, WindowSystemError>) {
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

    private func holdsDrag(at point: ScreenPoint) -> Bool {
        switch drag {
        case .none, .passing, .placing, .settling:
            return false
        case .pressed(var pressed):
            pressed.lastPointer = point
            drag = .pressed(pressed)
            guard pressed.hasWindowMoved else { return false }
            let elapsed = system.uptime - pressed.startTime
            if pressed.standIn == nil, !DragHoldRule.mayWaitForPictures(after: elapsed) {
                Self.logger.info("pictures took too long: the drag passes")
                problem = .captureFailed
                letDragPass()
                return false
            }
            return true
        case .moving(var moving):
            let before = system.uptime
            moving.standIn.move(to: moving.origin(forPointer: point))
            stats.record(moveDuration: system.uptime - before)
            moving.lastPointer = point
            drag = .moving(moving)
            return true
        }
    }

    /// Sees what macOS made of the press. Without the window server's place this asks the
    /// app, as for any window it does not tell about.
    private func watch(_ pressed: PairDrag.Pressed) {
        guard
            !pressed.hasWindowMoved,
            let now = pressed.window.serverFrame() ?? (try? pressed.window.frame())
        else { return }
        if DragHoldRule.isResize(from: pressed.frame, to: now) {
            letDragPass()
        } else if DragHoldRule.isMove(from: pressed.frame, to: now) {
            var moved = pressed
            moved.hasWindowMoved = true
            moved.frame = now
            moved.pointer = pressed.lastPointer
            drag = .pressed(moved)
            if let standIn = moved.standIn { takeOver(moved, standIn: standIn) }
        }
    }

    /// The panel shows before the windows leave, so the place does not flash empty.
    private func takeOver(_ pressed: PairDrag.Pressed, standIn: any WindowStandIn) {
        let now = system.uptime
        let moving = PairDrag.Moving(
            window: pressed.window, partner: pressed.partner, standIn: standIn,
            frame: pressed.frame, pointer: pressed.pointer, startTime: now,
            panelDelay: now - pressed.startTime, lastPointer: pressed.lastPointer)
        standIn.show(at: moving.origin(forPointer: pressed.lastPointer))
        stats = DragStats()
        drag = .moving(moving)
    }

    /// Calls to the apps happen here and not on an event, since an event that waits holds
    /// up all input.
    private func tick() {
        switch drag {
        case .none, .passing:
            break
        case .pressed(let pressed):
            if isButtonLetGo {
                release(at: pressed.lastPointer)
            } else {
                watch(pressed)
            }
        case .moving(let moving):
            if isButtonLetGo {
                release(at: moving.lastPointer)
            } else {
                park(moving)
            }
        case .placing(let placing):
            place(placing)
        case .settling(_, let until):
            if system.uptime >= until { endDrag() }
        }
    }

    /// A release the tap missed. The tap sees a press before the system counts the button
    /// as down, so up means let go only once it has been down, or after some time.
    private var isButtonLetGo: Bool {
        if system.isPrimaryButtonDown {
            hasSeenButtonDown = true
            return false
        }
        return hasSeenButtonDown || system.uptime - pressTime >= Self.buttonReportTime
    }
}
