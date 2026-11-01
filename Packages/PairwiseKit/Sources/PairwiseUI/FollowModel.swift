import Foundation
import Observation
import PairwiseCore
import os

/// Moves a partner window beside a dragged one, from the pointer, and measures it
/// (ADR 0013). A press notes the window under the pointer; the first tick that sees it
/// moved starts the following; the release ends it, with the partner placed from the
/// dragged window's real frame. With the Screen Recording permission, a stand-in takes
/// over from the partner as soon as its picture arrives (ADR 0014).
@MainActor
@Observable
public final class FollowModel {
    private static let tickInterval: TimeInterval = 1.0 / 120
    /// How long a busy partner gets to come back at the release, with the stand-in up.
    static let placingPatience: TimeInterval = 0.5
    static let logger = Logger(subsystem: "me.m-domain.pairwise", category: "follow")

    /// How long a stand-in stays behind the pointer, in seconds (ADR 0017).
    public var standInHoldBack: TimeInterval = 1.0 / 60

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
    @ObservationIgnored var stillPointer = StillPointer()
    @ObservationIgnored var pointerDelay = PointerDelay()
    @ObservationIgnored var gripOffset: Double?
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
        case .dragged(let point): moveStandIn(toward: point)
        case .released: release()
        }
    }

    private func press(at point: ScreenPoint) {
        putPartnerBack()
        endDrag()
        problem = nil
        guard let window = system.window(at: point) else { return }
        do {
            drag = .pressed(window: window, frame: try window.frame(), pointer: point)
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
                if let pointer = system.pointerLocation {
                    try follow(following, pointer: pointer)
                    measureGrip(of: following, pointer: pointer)
                }
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
        guard WindowDragRule.isMove(from: start, to: try window.frame()) else { return }
        stats = FollowStats()
        stillPointer = StillPointer()
        pointerDelay = PointerDelay()
        gripOffset = nil
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

    func follow(
        _ following: FollowDrag.Following, pointer: ScreenPoint
    ) throws(WindowSystemError) {
        let before = system.uptime
        if let standIn = following.standIn {
            let heldBack = pointerDelay.place(
                of: pointer, at: before, holdingBack: standInHoldBack)
            standIn.move(to: following.target(forPointer: heldBack))
        } else {
            try following.partner.move(to: following.target(forPointer: pointer))
        }
        stats.record(
            moveDuration: system.uptime - before,
            pointsBehind: pointer.distance(to: system.pointerLocation ?? pointer))
        if following.standIn != nil, !following.isParked {
            try park(following)
        }
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
