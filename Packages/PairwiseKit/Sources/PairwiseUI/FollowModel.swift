import Foundation
import Observation
import PairwiseCore
import os

/// Moves a partner window beside a dragged one and measures it. A press notes the window
/// under the pointer and starts on a picture of the partner; the first tick that sees the
/// window moved starts the following; the release ends it, with the partner placed beside
/// the dragged window. The place comes from the window server, or from the pointer and
/// the grip when it does not tell (ADR 0013, 0018). With the Screen Recording permission,
/// a stand-in takes over from the partner as soon as its picture is there (ADR 0014).
@MainActor
@Observable
public final class FollowModel {
    private static let tickInterval: TimeInterval = 1.0 / 120
    /// How long a busy partner gets to come back at the release, with the stand-in up.
    static let placingPatience: TimeInterval = 0.5
    static let logger = Logger(subsystem: "me.m-domain.pairwise", category: "follow")

    public private(set) var isAccessibilityGranted: Bool
    public private(set) var isScreenRecordingGranted: Bool
    public private(set) var isWatching = false
    /// Why the last start or drag did not work; cleared by the next one.
    public internal(set) var problem: WindowSystemError?
    /// The measurements of the last drag that moved the partner.
    public internal(set) var lastDrag: FollowReport?

    @ObservationIgnored let system: any WindowSystemProviding
    @ObservationIgnored var drag = FollowDrag.none
    @ObservationIgnored var stats = FollowStats()
    /// The partner found at the press, whose picture is on its way.
    @ObservationIgnored var pressPartner: (any MovableWindow)?
    /// A picture that arrived before the press turned out to be a drag.
    @ObservationIgnored var earlyPicture: Result<any WindowStandIn, WindowSystemError>?
    @ObservationIgnored var mostSlip: Double?
    /// Tells a picture that arrives late from the one this drag asked for.
    @ObservationIgnored var standInRequest = 0

    public init(system: any WindowSystemProviding) {
        self.system = system
        isAccessibilityGranted = system.isAccessibilityGranted
        isScreenRecordingGranted = system.isScreenRecordingGranted
    }

    /// Reads the permissions again; the user grants them elsewhere, in System Settings.
    public func refreshPermission() {
        isAccessibilityGranted = system.isAccessibilityGranted
        isScreenRecordingGranted = system.isScreenRecordingGranted
    }

    /// Asks the system to show the user where to grant the permission.
    public func requestAccessibility() {
        system.requestAccessibility()
    }

    /// Asks the system for the permission a stand-in needs.
    public func requestScreenRecording() {
        system.requestScreenRecording()
    }

    /// Starts watching for drags; a failure lands in `problem`.
    public func start() {
        refreshPermission()
        guard isAccessibilityGranted else {
            problem = .accessibilityDenied
            return
        }
        do {
            try system.startWatchingPointer { [weak self] event in self?.handle(event) }
            problem = nil
            isWatching = true
        } catch {
            problem = error
        }
    }

    /// Stops watching and lets go of any drag, with a parked partner put back.
    public func stop() {
        putPartnerBack()
        endDrag()
        system.stopWatchingPointer()
        isWatching = false
    }

    private func handle(_ event: PointerButtonEvent) {
        switch event {
        case .pressed(let point): press(at: point)
        case .released: release()
        }
    }

    private func press(at point: ScreenPoint) {
        putPartnerBack()
        endDrag()
        problem = nil
        guard let window = system.window(at: point) else { return }
        do {
            drag = .pressed(window: window, frame: try window.liveFrame(), pointer: point)
            system.startTicking(every: Self.tickInterval) { [weak self] in self?.tick() }
            prepareStandIn(for: window)
        } catch {
            fail(error)
        }
    }

    private func tick() {
        do {
            switch drag {
            case .none: break
            case .pressed(let window, let frame, let pointer):
                try checkForMove(of: window, from: frame, pointer: pointer)
            case .following(let following):
                try follow(following)
            case .placing(let placing):
                place(placing)
            }
        } catch {
            fail(error)
        }
    }

    private func checkForMove(
        of window: any MovableWindow, from start: WindowFrame, pointer: ScreenPoint
    ) throws(WindowSystemError) {
        guard WindowDragRule.isMove(from: start, to: try window.liveFrame()) else { return }
        stats = FollowStats()
        mostSlip = nil
        let partner: any MovableWindow
        if let pressPartner {
            partner = pressPartner
        } else {
            partner = try system.partner(for: window)
        }
        drag = .following(
            FollowDrag.Following(
                window: window,
                partner: partner,
                size: start.size,
                grip: DragGrip(pointer: pointer, windowOrigin: start.origin),
                startTime: system.uptime
            ))
        if let earlyPicture {
            self.earlyPicture = nil
            receive(earlyPicture)
        }
    }

    /// Moves only when the dragged window's place has changed, so the moves measured are
    /// how often it changed (ADR 0018).
    func follow(_ following: FollowDrag.Following) throws(WindowSystemError) {
        let before = system.uptime
        let pointer = system.pointerLocation
        let serverFrame = following.window.serverFrame()
        noteSlip(of: following, serverFrame: serverFrame, pointer: pointer)
        guard let target = following.target(serverFrame: serverFrame, pointer: pointer) else {
            return
        }
        var current = following
        if target != current.lastTarget {
            if let standIn = current.standIn {
                standIn.move(to: target)
            } else {
                try current.partner.move(to: target)
            }
            let pointerNow = system.pointerLocation
            let behind = pointer.flatMap { start in pointerNow.map(start.distance(to:)) }
            stats.record(moveDuration: system.uptime - before, pointsBehind: behind ?? 0)
            current.lastTarget = target
            drag = .following(current)
        }
        if current.standIn != nil, !current.isParked {
            try park(current)
        }
    }

    private func noteSlip(
        of following: FollowDrag.Following, serverFrame: WindowFrame?, pointer: ScreenPoint?
    ) {
        guard let serverFrame, let pointer else { return }
        let slip = following.grip.windowOrigin(forPointer: pointer).distance(to: serverFrame.origin)
        mostSlip = max(mostSlip ?? 0, slip)
    }

    /// A busy app may answer on the next tick; anything else ends the drag.
    func fail(_ error: WindowSystemError) {
        if error == .windowBusy, isDragging { return }
        endDrag()
        problem = error
    }

    private var isDragging: Bool {
        if case .none = drag { return false }
        return true
    }

    func endDrag() {
        system.stopTicking()
        if case .following(let following) = drag { following.standIn?.dismiss() }
        if case .placing(let placing) = drag { placing.standIn.dismiss() }
        standInRequest += 1
        pressPartner = nil
        earlyPicture = nil
        drag = .none
    }
}
