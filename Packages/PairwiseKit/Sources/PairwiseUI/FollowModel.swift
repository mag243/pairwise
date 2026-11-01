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
    private static let placingPatience: TimeInterval = 0.5
    private static let logger = Logger(subsystem: "me.m-domain.pairwise", category: "follow")

    public private(set) var isAccessibilityGranted: Bool
    public private(set) var isScreenRecordingGranted: Bool
    public private(set) var isWatching = false
    /// Why the last start or drag did not work; cleared by the next one.
    public private(set) var problem: WindowSystemError?
    /// The measurements of the last drag that moved the partner.
    public private(set) var lastDrag: FollowReport?

    @ObservationIgnored private let system: any WindowSystemProviding
    @ObservationIgnored private var drag = FollowDrag.none
    @ObservationIgnored private var stats = FollowStats()
    /// Tells a picture that arrives late from the one this drag asked for.
    @ObservationIgnored private var standInRequest = 0

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
        let partner = try system.partner(for: window)
        drag = .following(
            FollowDrag.Following(
                window: window,
                partner: partner,
                size: start.size,
                grip: DragGrip(pointer: pointer, windowOrigin: start.origin),
                startTime: system.uptime
            ))
        requestStandIn(of: partner)
    }

    private func requestStandIn(of partner: any MovableWindow) {
        guard system.isScreenRecordingGranted else { return }
        let request = standInRequest
        system.makeStandIn(of: partner) { [weak self] result in
            guard let self, request == standInRequest else { return }
            receive(result)
        }
    }

    /// A failure leaves the partner following as itself.
    private func receive(_ result: Result<any WindowStandIn, WindowSystemError>) {
        guard case .following(var following) = drag else { return }
        switch result {
        case .failure(let error):
            problem = error
        case .success(let standIn):
            guard let pointer = system.pointerLocation else { return }
            // Showing it before the partner leaves keeps the place from flashing empty.
            standIn.show(at: following.target(forPointer: pointer))
            let now = system.uptime
            following.standIn = standIn
            following.standInDelay = now - following.startTime
            following.startTime = now
            stats = FollowStats()
            drag = .following(following)
        }
    }

    /// A stand-in's move calls no other app, so it need not wait for the next tick. A
    /// partner moving as itself stays on the ticks, or slow calls would queue up.
    private func moveStandIn(toward pointer: ScreenPoint) {
        guard case .following(let following) = drag, following.standIn != nil else { return }
        do {
            try follow(following, pointer: pointer)
        } catch {
            fail(error)
        }
    }

    private func follow(
        _ following: FollowDrag.Following, pointer: ScreenPoint
    ) throws(WindowSystemError) {
        let target = following.target(forPointer: pointer)
        let before = system.uptime
        if let standIn = following.standIn {
            standIn.move(to: target)
        } else {
            try following.partner.move(to: target)
        }
        stats.record(
            moveDuration: system.uptime - before,
            pointsBehind: pointer.distance(to: system.pointerLocation ?? pointer))
        if following.standIn != nil, !following.isParked {
            try park(following)
        }
    }

    private func park(_ following: FollowDrag.Following) throws(WindowSystemError) {
        if let origin = system.parkingOrigin {
            try following.partner.move(to: origin)
        }
        var parked = following
        parked.isParked = true
        drag = .following(parked)
    }

    /// The button is up, so the drag ends whatever the apps answer here, except that a
    /// stand-in stays up while a busy partner may still come back.
    private func release() {
        guard case .following(let following) = drag else {
            endDrag()
            return
        }
        let pointer = system.pointerLocation
        var placement: ScreenPoint?
        var gripOffset: Double?
        do {
            let frame = try following.window.frame()
            placement = PartnerPlacement.origin(besideWindowAt: frame.origin, size: frame.size)
            gripOffset = pointer.map {
                following.grip.windowOrigin(forPointer: $0).distance(to: frame.origin)
            }
        } catch {
            problem = error
            placement = pointer.map(following.target(forPointer:))
        }
        lastDrag = stats.report(
            elapsed: system.uptime - following.startTime,
            standInDelay: following.standInDelay,
            gripOffset: gripOffset)
        lastDrag?.log(to: Self.logger)
        guard let finalTarget = placement else {
            endDrag()
            return
        }
        guard let standIn = following.standIn else {
            moveAtRelease(following.partner, to: finalTarget)
            return
        }
        let placing = FollowDrag.Placing(
            partner: following.partner, standIn: standIn, target: finalTarget,
            deadline: system.uptime + Self.placingPatience)
        drag = .placing(placing)
        place(placing)
    }

    private func moveAtRelease(_ partner: any MovableWindow, to target: ScreenPoint) {
        defer { endDrag() }
        do {
            try partner.move(to: target)
            try? partner.raise()
        } catch {
            problem = error
        }
    }

    private func place(_ placing: FollowDrag.Placing) {
        do {
            try placing.partner.move(to: placing.target)
            // It stays in front as the stand-in was; it is in its place either way.
            try? placing.partner.raise()
            endDrag()
        } catch {
            if error == .windowBusy, system.uptime < placing.deadline { return }
            problem = error
            endDrag()
        }
    }

    /// One last try for a partner that is parked or on its way back, when something other
    /// than the release ends the drag.
    private func putPartnerBack() {
        switch drag {
        case .following(let following) where following.standIn != nil:
            if let target = try? following.placementFromRealFrame() {
                try? following.partner.move(to: target)
            }
        case .placing(let placing):
            try? placing.partner.move(to: placing.target)
        default:
            break
        }
    }

    /// A busy app may answer on the next tick; anything else ends the drag.
    private func fail(_ error: WindowSystemError) {
        if error == .windowBusy, isDragging { return }
        endDrag()
        problem = error
    }

    private var isDragging: Bool {
        if case .none = drag { return false }
        return true
    }

    private func endDrag() {
        system.stopTicking()
        if case .following(let following) = drag { following.standIn?.dismiss() }
        if case .placing(let placing) = drag { placing.standIn.dismiss() }
        standInRequest += 1
        drag = .none
    }
}
