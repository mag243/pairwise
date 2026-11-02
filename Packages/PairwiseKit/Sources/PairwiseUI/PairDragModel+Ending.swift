import Foundation
import PairwiseCore

/// Parking the windows, and everything that ends a drag.
extension PairDragModel {
    func park(_ moving: PairDrag.Moving) {
        guard !moving.isWindowParked || !moving.isPartnerParked else { return }
        guard let origin = system.parkingOrigin else { return }
        var current = moving
        do {
            if !current.isWindowParked {
                try current.window.move(to: origin)
                current.isWindowParked = true
            }
            if !current.isPartnerParked {
                try current.partner.window.move(to: origin)
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

    func release(at point: ScreenPoint) {
        if case .joining(let joining) = drag {
            finish(joining)
            return
        }
        guard case .moving(let moving) = drag else {
            if case .pressed(let pressed) = drag {
                placePartnerAfterShortDrag(pressed)
                Self.logger.info(
                    "released with no panel, moved \(pressed.hasWindowMoved), pictures \(pressed.standIn != nil)"
                )
            }
            endDrag()
            return
        }
        report(moving)
        let placing = PairDrag.Placing(
            window: moving.window, partner: moving.partner, standIn: moving.standIn,
            target: moving.origin(forPointer: point), size: moving.frame.size,
            deadline: system.uptime + Self.placingPatience)
        drag = .placing(placing)
        place(placing)
    }

    /// The partner goes beside the window's actual place, as the system can stop a window
    /// where the panel went (the menu bar).
    func place(_ placing: PairDrag.Placing) {
        var current = placing
        do {
            if !current.isWindowPlaced {
                try current.window.move(to: current.target)
                current.isWindowPlaced = true
            }
            let origin = (try? current.window.frame().origin) ?? current.target
            try current.partner.window.move(
                to: place(of: current.partner, beside: origin, current.size))
            // Raised last, the dragged window ends on top; a failure leaves it in place.
            try? current.partner.window.raise()
            try? current.window.raise()
            drag = .settling(standIn: current.standIn, until: system.uptime + Self.settleTime)
        } catch {
            drag = .placing(current)
            if error == .windowBusy, system.uptime < current.deadline { return }
            problem = error
            endDrag()
        }
    }

    /// The drag was over before the panel came. macOS has moved the window, if anything, so
    /// the partner goes beside it. A window that has not moved was a click.
    func placePartnerAfterShortDrag(_ pressed: PairDrag.Pressed) {
        guard
            let now = pressed.window.serverFrame() ?? (try? pressed.window.frame()),
            pressed.hasWindowMoved || DragHoldRule.isMove(from: pressed.frame, to: now)
        else { return }
        try? pressed.partner.window.move(
            to: place(of: pressed.partner, beside: now.origin, now.size))
        try? pressed.partner.window.raise()
        try? pressed.window.raise()
    }

    /// One last try for parked windows, when something other than the release ends a drag.
    func putWindowsBack() {
        switch drag {
        case .moving(let moving):
            let origin = moving.origin(forPointer: moving.lastPointer)
            try? moving.window.move(to: origin)
            try? moving.partner.window.move(
                to: place(of: moving.partner, beside: origin, moving.frame.size))
        case .placing(let placing):
            try? placing.window.move(to: placing.target)
            try? placing.partner.window.move(
                to: place(of: placing.partner, beside: placing.target, placing.size))
        default:
            break
        }
    }

    private func place(
        of partner: PairDrag.Partner, beside origin: ScreenPoint, _ size: WindowSize
    ) -> ScreenPoint {
        PartnerPlacement.origin(
            besideWindowAt: origin, size: size, partnerSize: partner.size, on: partner.side)
    }

    func letDragPass() {
        endDrag()
        drag = .passing
    }

    func endDrag() {
        system.stopTicking()
        if case .moving(let moving) = drag { moving.standIn.dismiss() }
        if case .placing(let placing) = drag { placing.standIn.dismiss() }
        if case .joining = drag { system.hideJoinGuide() }
        if case .settling(let standIn, _) = drag { standIn.dismiss() }
        request += 1
        drag = .none
    }

    func report(_ moving: PairDrag.Moving) {
        lastDrag = stats.report(
            elapsed: system.uptime - moving.startTime, panelDelay: moving.panelDelay,
            liveFrames: moving.standIn.liveFrames)
        guard let lastDrag else { return }
        Self.logger.info(
            """
            drag: \(lastDrag.moves) moves, \(lastDrag.movesPerSecond) per second, \
            mean \(lastDrag.meanMove) s, longest \(lastDrag.longestMove) s, \
            panel after \(moving.panelDelay) s, \
            live frames \(lastDrag.liveFrames, privacy: .public)
            """)
    }
}
