import Foundation
import Observation
import PairwiseCore
import os

/// The test of whether a window drag can be held back (ADR 0023): withholds the drag
/// events after a press on another app's title bar, and reports whether the window moved.
@MainActor
@Observable
public final class DragHoldTest {
    private static let logger = Logger(subsystem: "me.m-domain.pairwise", category: "drag-test")

    private struct Hold {
        let window: any MovableWindow
        let frame: WindowFrame
        let pointer: ScreenPoint
        let startTime: TimeInterval
        var heldEvents = 0
    }

    public private(set) var isRunning = false
    /// Why the test did not start.
    public private(set) var problem: WindowSystemError?
    /// What the last drag showed.
    public private(set) var lastReport: DragHoldReport?

    @ObservationIgnored private let system: any WindowSystemProviding
    @ObservationIgnored private var hold: Hold?

    public init(system: any WindowSystemProviding) {
        self.system = system
    }

    /// Starts holding back; a failure lands in `problem`.
    public func start() {
        guard system.isAccessibilityGranted else {
            problem = .accessibilityDenied
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

    /// Stops holding back; all input passes.
    public func stop() {
        system.stopHoldingDrags()
        hold = nil
        isRunning = false
    }

    /// Whether `event` passes. Only drags after a press on a title bar are withheld.
    private func decide(_ event: PointerButtonEvent) -> Bool {
        switch event {
        case .pressed(let point):
            press(at: point)
            return true
        case .dragged:
            return !holdsDrag()
        case .released(let point):
            release(at: point)
            return true
        }
    }

    private func press(at point: ScreenPoint) {
        hold = nil
        guard
            let window = system.window(at: point),
            let frame = window.serverFrame() ?? (try? window.frame()),
            DragHoldRule.isInTitleBand(point, of: frame)
        else { return }
        hold = Hold(window: window, frame: frame, pointer: point, startTime: system.uptime)
    }

    private func holdsDrag() -> Bool {
        guard var current = hold else { return false }
        guard DragHoldRule.mayHold(after: system.uptime - current.startTime) else { return false }
        current.heldEvents += 1
        hold = current
        return true
    }

    private func release(at point: ScreenPoint) {
        defer { hold = nil }
        guard
            let hold, hold.heldEvents > 0,
            let frame = hold.window.serverFrame() ?? (try? hold.window.frame())
        else { return }
        let report = DragHoldReport(
            pointerTravel: hold.pointer.distance(to: point),
            windowTravel: hold.frame.origin.distance(to: frame.origin),
            heldEvents: hold.heldEvents)
        lastReport = report
        Self.logger.info(
            """
            pointer moved \(report.pointerTravel), window moved \(report.windowTravel), \
            held back \(report.heldEvents)
            """)
    }
}
