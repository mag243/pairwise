import Foundation
import Observation
import PairwiseCore
import os

/// Moves a partner window beside a dragged one, from the pointer, and measures it
/// (ADR 0013). A press notes the window under the pointer; the first tick that sees it
/// moved starts the following; the release ends it, with the partner placed from the
/// dragged window's real frame.
@MainActor
@Observable
public final class FollowModel {
    private static let tickInterval: TimeInterval = 1.0 / 120
    private static let logger = Logger(subsystem: "me.m-domain.pairwise", category: "follow")

    private enum Drag {
        case none
        case pressed(window: any MovableWindow, frame: WindowFrame, pointer: ScreenPoint)
        case following(Following)
    }

    private struct Following {
        let window: any MovableWindow
        let partner: any MovableWindow
        let size: WindowSize
        let grip: DragGrip
        let startTime: TimeInterval
    }

    public private(set) var isAccessibilityGranted: Bool
    public private(set) var isWatching = false
    /// Why the last start or drag did not work; cleared by the next one.
    public private(set) var problem: WindowSystemError?
    /// The measurements of the last drag that moved the partner.
    public private(set) var lastDrag: FollowReport?

    @ObservationIgnored private let system: any WindowSystemProviding
    @ObservationIgnored private var drag = Drag.none
    @ObservationIgnored private var stats = FollowStats()

    public init(system: any WindowSystemProviding) {
        self.system = system
        isAccessibilityGranted = system.isAccessibilityGranted
    }

    /// Reads the permission again; the user grants it elsewhere, in System Settings.
    public func refreshPermission() {
        isAccessibilityGranted = system.isAccessibilityGranted
    }

    /// Asks the system to show the user where to grant the permission.
    public func requestAccessibility() {
        system.requestAccessibility()
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

    /// Stops watching and lets go of any drag.
    public func stop() {
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
                try follow(following)
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
        drag = .following(
            Following(
                window: window,
                partner: try system.partner(for: window),
                size: start.size,
                grip: DragGrip(pointer: pointer, windowOrigin: start.origin),
                startTime: system.uptime
            ))
    }

    private func follow(_ following: Following) throws(WindowSystemError) {
        guard let pointer = system.pointerLocation else { return }
        let target = PartnerPlacement.origin(
            besideWindowAt: following.grip.windowOrigin(forPointer: pointer),
            size: following.size)
        let before = system.uptime
        try following.partner.move(to: target)
        stats.record(
            moveDuration: system.uptime - before,
            pointsBehind: pointer.distance(to: system.pointerLocation ?? pointer))
    }

    private func release() {
        guard case .following(let following) = drag else {
            endDrag()
            return
        }
        lastDrag = stats.report(elapsed: system.uptime - following.startTime)
        logLastDrag()
        do {
            let frame = try following.window.frame()
            try following.partner.move(
                to: PartnerPlacement.origin(besideWindowAt: frame.origin, size: frame.size))
            endDrag()
        } catch {
            fail(error)
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
        drag = .none
    }

    private func logLastDrag() {
        guard let report = lastDrag else { return }
        Self.logger.info(
            """
            drag: \(report.moves) moves, \(report.movesPerSecond) per second, \
            mean \(report.meanMove) s, p95 \(report.percentile95Move) s, \
            longest \(report.longestMove) s, \
            behind mean \(report.meanPointsBehind), most \(report.mostPointsBehind)
            """)
    }
}
