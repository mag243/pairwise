import Foundation
import Observation
import PairwiseCore
import os

/// Moves a window and its partner as one window of Pairwise's own (ADR 0024). A press on
/// another app's title bar starts on a picture of both and holds the drag back; once the
/// pointer has moved and the picture is there, a panel takes over from both windows, and
/// the release puts them where the panel is.
@MainActor
@Observable
public final class PairDragModel {
    private static let tickInterval: TimeInterval = 1.0 / 120
    /// How long a busy app gets to answer at the release, with the panel up.
    private static let placingPatience: TimeInterval = 0.5
    private static let logger = Logger(subsystem: "me.m-domain.pairwise", category: "pair-drag")

    public private(set) var isRunning = false
    /// Why the last start or drag did not work; cleared by the next one.
    public private(set) var problem: WindowSystemError?
    /// The measurements of the last drag that moved the panel.
    public private(set) var lastDrag: FollowReport?

    @ObservationIgnored private let system: any WindowSystemProviding
    @ObservationIgnored private var drag = PairDrag.none
    @ObservationIgnored private var stats = FollowStats()
    /// Tells a picture that arrives late from the one this press asked for.
    @ObservationIgnored private var request = 0

    public init(system: any WindowSystemProviding) {
        self.system = system
    }

    /// Starts taking over drags; a failure lands in `problem`, and all input passes.
    public func start() {
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

    /// Whether `event` passes. Only drags after a press on a title bar are withheld.
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
        guard
            let window = system.window(at: point),
            let frame = window.serverFrame() ?? (try? window.frame()),
            DragHoldRule.isInTitleBand(point, of: frame),
            let partner = try? system.partner(for: window)
        else { return }
        drag = .pressed(
            PairDrag.Pressed(
                window: window, partner: partner, frame: frame, pointer: point,
                startTime: system.uptime, lastPointer: point))
        system.startTicking(every: Self.tickInterval) { [weak self] in self?.tick() }
        let current = request
        system.makePairStandIn(of: window, beside: partner) { [weak self] result in
            guard let self, current == request else { return }
            receive(result)
        }
    }

    private func receive(_ result: Result<any WindowStandIn, WindowSystemError>) {
        guard case .pressed(var pressed) = drag else { return }
        switch result {
        case .failure(let error):
            problem = error
            letDragPass()
        case .success(let standIn):
            pressed.standIn = standIn
            drag = .pressed(pressed)
            if pressed.isDrag { takeOver(pressed, standIn: standIn) }
        }
    }

    private func holdsDrag(at point: ScreenPoint) -> Bool {
        switch drag {
        case .none, .passing, .placing:
            return false
        case .pressed(var pressed):
            guard DragHoldRule.mayWaitForPictures(after: system.uptime - pressed.startTime)
            else {
                if pressed.standIn == nil {
                    problem = .captureFailed
                    letDragPass()
                    return false
                }
                return holds(&pressed, at: point)
            }
            return holds(&pressed, at: point)
        case .moving(var moving):
            let before = system.uptime
            moving.standIn.move(to: moving.origin(forPointer: point))
            stats.record(moveDuration: system.uptime - before, pointsBehind: 0)
            moving.lastPointer = point
            drag = .moving(moving)
            return true
        }
    }

    private func holds(_ pressed: inout PairDrag.Pressed, at point: ScreenPoint) -> Bool {
        pressed.lastPointer = point
        pressed.isDrag = pressed.isDrag || DragHoldRule.isDrag(from: pressed.pointer, to: point)
        drag = .pressed(pressed)
        if pressed.isDrag, let standIn = pressed.standIn {
            takeOver(pressed, standIn: standIn)
        }
        return true
    }

    /// The panel shows before the windows leave, so the place does not flash empty.
    private func takeOver(_ pressed: PairDrag.Pressed, standIn: any WindowStandIn) {
        let now = system.uptime
        let moving = PairDrag.Moving(
            window: pressed.window, partner: pressed.partner, standIn: standIn,
            frame: pressed.frame, pointer: pressed.pointer, startTime: now,
            standInDelay: now - pressed.startTime, lastPointer: pressed.lastPointer)
        standIn.show(at: moving.origin(forPointer: pressed.lastPointer))
        stats = FollowStats()
        drag = .moving(moving)
    }

    /// Calls to the apps happen here and not on an event, since an event that waits holds
    /// up all input.
    private func tick() {
        switch drag {
        case .none, .passing:
            break
        case .pressed(let pressed):
            if !system.isPrimaryButtonDown { release(at: pressed.lastPointer) }
        case .moving(let moving):
            if system.isPrimaryButtonDown {
                park(moving)
            } else {
                release(at: moving.lastPointer)
            }
        case .placing(let placing):
            place(placing)
        }
    }

    private func park(_ moving: PairDrag.Moving) {
        guard !moving.isWindowParked || !moving.isPartnerParked else { return }
        guard let origin = system.parkingOrigin else { return }
        var current = moving
        do {
            if !current.isWindowParked {
                try current.window.move(to: origin)
                current.isWindowParked = true
            }
            if !current.isPartnerParked {
                try current.partner.move(to: origin)
                current.isPartnerParked = true
            }
            drag = .moving(current)
        } catch {
            drag = .moving(current)
            guard error != .windowBusy else { return }
            problem = error
            putWindowsBack()
            endDrag()
        }
    }

    private func release(at point: ScreenPoint) {
        guard case .moving(let moving) = drag else {
            endDrag()
            return
        }
        report(moving)
        let placing = PairDrag.Placing(
            window: moving.window, partner: moving.partner, standIn: moving.standIn,
            target: moving.origin(forPointer: point), width: moving.frame.size.width,
            deadline: system.uptime + Self.placingPatience)
        drag = .placing(placing)
        place(placing)
    }

    /// The partner goes beside the window's actual place, as the system can stop a window
    /// where the panel went (the menu bar).
    private func place(_ placing: PairDrag.Placing) {
        var current = placing
        do {
            if !current.isWindowPlaced {
                try current.window.move(to: current.target)
                current.isWindowPlaced = true
            }
            let origin = (try? current.window.frame().origin) ?? current.target
            try current.partner.move(
                to: ScreenPoint(x: origin.x + current.width, y: origin.y))
            // Raised last, the dragged window ends on top; a failure leaves it in place.
            try? current.partner.raise()
            try? current.window.raise()
            endDrag()
        } catch {
            drag = .placing(current)
            if error == .windowBusy, system.uptime < current.deadline { return }
            problem = error
            endDrag()
        }
    }

    /// One last try for parked windows, when something other than the release ends a drag.
    private func putWindowsBack() {
        switch drag {
        case .moving(let moving):
            let origin = moving.origin(forPointer: moving.lastPointer)
            try? moving.window.move(to: origin)
            try? moving.partner.move(
                to: ScreenPoint(x: origin.x + moving.frame.size.width, y: origin.y))
        case .placing(let placing):
            try? placing.window.move(to: placing.target)
            try? placing.partner.move(
                to: ScreenPoint(x: placing.target.x + placing.width, y: placing.target.y))
        default:
            break
        }
    }

    private func letDragPass() {
        endDrag()
        drag = .passing
    }

    private func endDrag() {
        system.stopTicking()
        if case .moving(let moving) = drag { moving.standIn.dismiss() }
        if case .placing(let placing) = drag { placing.standIn.dismiss() }
        request += 1
        drag = .none
    }

    private func report(_ moving: PairDrag.Moving) {
        lastDrag = stats.report(
            elapsed: system.uptime - moving.startTime, standInDelay: moving.standInDelay)
        guard let lastDrag else { return }
        Self.logger.info(
            """
            drag: \(lastDrag.moves) moves, \(lastDrag.movesPerSecond) per second, \
            mean \(lastDrag.meanMove) s, longest \(lastDrag.longestMove) s, \
            panel after \(moving.standInDelay) s
            """)
    }
}
