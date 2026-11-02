import Foundation
import PairwiseCore

/// What a resize at the seam needs to know (ADR 0048, 0049).
extension PairDrag.ResizingSeam {
    /// Where the seam belongs for the pointer's last place, within the limits found.
    var seam: Double {
        let wanted = seamAtPress + lastPointerX - pointerXAtPress
        return partnerLimits.clamped(seamAt: heldLimits.clamped(seamAt: wanted))
    }

    /// The left window at the press, whose origin is that of the panel.
    private var leftWindow: WindowFrame { side == .right ? heldStart : partnerStart }

    var panelOrigin: ScreenPoint { leftWindow.origin }

    /// How far from the panel's left edge the seam is.
    var seamOffset: Double { seam - leftWindow.origin.x }

    func heldFrame(seamAt x: Double) -> WindowFrame {
        SeamFollow.frame(start: heldStart, on: side.opposite, seamAt: x)
    }

    func partnerFrame(seamAt x: Double) -> WindowFrame {
        SeamFollow.frame(start: partnerStart, on: side, seamAt: x)
    }
}

/// A pair being resized at the seam, with its pictures in a panel and both windows parked
/// (ADR 0048, 0049).
extension PairDragModel {
    /// How often both windows get their widths for the seam, in seconds.
    private static let seamLookInterval: TimeInterval = 0.05

    /// macOS has moved the seam of the pressed window.
    func startFollowingSeam(_ pressed: PairDrag.Pressed) {
        let partner = WindowFrame(origin: pressed.partner.origin, size: pressed.partner.size)
        let side = pressed.partner.side
        startFollowing(
            PairDrag.ResizingSeam(
                window: pressed.window, partner: pressed.partner.window, heldStart: pressed.frame,
                partnerStart: partner, side: side,
                seamAtPress: SeamFollow.seam(of: pressed.frame, partnerOn: side),
                pointerXAtPress: pressed.pointer.x, startTime: pressed.startTime,
                lastPointerX: pressed.lastPointer.x, lastLook: system.uptime),
            standIn: pressed.standIn)
    }

    /// The grip of a window's edge reaches past the window, so a press on one window of a pair
    /// can resize the other at the seam. That other window is the one held, then. Says whether
    /// this is such a press.
    func startFollowingSeamIfPartnerIsHeld(_ pressed: PairDrag.Pressed) -> Bool {
        let held = pressed.partner.window
        let start = WindowFrame(origin: pressed.partner.origin, size: pressed.partner.size)
        let side = pressed.partner.side.opposite
        guard
            let now = held.serverFrame() ?? (try? held.frame()),
            DragHoldRule.isResize(from: start, to: now),
            SeamFollow.movesSeam(from: start, to: now, partnerOn: side)
        else { return false }
        startFollowing(
            PairDrag.ResizingSeam(
                window: held, partner: pressed.window, heldStart: start,
                partnerStart: pressed.frame, side: side,
                seamAtPress: SeamFollow.seam(of: start, partnerOn: side),
                pointerXAtPress: pressed.pointer.x, startTime: pressed.startTime,
                lastPointerX: pressed.lastPointer.x, lastLook: system.uptime),
            standIn: pressed.standIn)
        return true
    }

    /// The press's ticks go on, and its pictures may still come.
    private func startFollowing(_ resizing: PairDrag.ResizingSeam, standIn: (any WindowStandIn)?) {
        drag = .resizingSeam(resizing)
        if let standIn { show(standIn, for: resizing) }
    }

    private func show(_ standIn: any WindowStandIn, for resizing: PairDrag.ResizingSeam) {
        var current = resizing
        current.standIn = standIn
        standIn.setSeam(atOffset: current.seamOffset)
        standIn.showForSeam(at: current.panelOrigin)
        drag = .resizingSeam(current)
    }

    /// The pictures of the press have come. Without them, macOS goes on resizing the window.
    func receive(
        _ result: Result<any WindowStandIn, WindowSystemError>, for resizing: PairDrag.ResizingSeam
    ) {
        switch result {
        case .success(let standIn):
            if resizing.isPassing { standIn.dismiss() } else { show(standIn, for: resizing) }
        case .failure(let error):
            Self.logger.info("no pictures: \(String(describing: error), privacy: .public)")
            problem = error
            letEventsPass(resizing)
        }
    }

    private func letEventsPass(_ resizing: PairDrag.ResizingSeam) {
        var current = resizing
        current.isPassing = true
        drag = .resizingSeam(current)
    }

    /// Calls no app, as this runs on an event: the seam moves in the panel alone. Says whether
    /// the event is withheld.
    func holds(_ resizing: PairDrag.ResizingSeam, at point: ScreenPoint) -> Bool {
        var current = resizing
        current.lastPointerX = point.x
        drag = .resizingSeam(current)
        current.standIn?.setSeam(atOffset: current.seamOffset)
        return !current.isPassing
    }

    func tick(_ resizing: PairDrag.ResizingSeam) {
        if resizing.isReleased || isButtonLetGo {
            finishSeam(resizing)
        } else if resizing.standIn != nil {
            lookAtSeam(parked(resizing))
        } else if !resizing.isPassing,
            !DragHoldRule.mayWaitForPictures(after: system.uptime - resizing.startTime)
        {
            Self.logger.info("pictures took too long: the resize passes")
            problem = .captureFailed
            letEventsPass(resizing)
        }
    }

    /// A window that is busy gets another try on a later tick. One that refuses stays where
    /// it is, under the panel.
    private func parked(_ resizing: PairDrag.ResizingSeam) -> PairDrag.ResizingSeam {
        guard !resizing.isHeldParked || !resizing.isPartnerParked,
            let origin = system.parkingOrigin
        else { return resizing }
        recordParking(of: [
            WindowToPark(window: resizing.window, frame: resizing.heldStart),
            WindowToPark(window: resizing.partner, frame: resizing.partnerStart),
        ])
        var current = resizing
        if !current.isHeldParked { current.isHeldParked = Self.park(current.window, at: origin) }
        if !current.isPartnerParked {
            current.isPartnerParked = Self.park(current.partner, at: origin)
        }
        drag = .resizingSeam(current)
        return current
    }

    private static func park(_ window: any MovableWindow, at origin: ScreenPoint) -> Bool {
        do {
            try window.move(to: origin)
            return true
        } catch {
            return error != .windowBusy
        }
    }

    /// Gives both windows their widths for the seam, which also shows a window's limit. Their
    /// places do not matter while parked.
    private func lookAtSeam(_ resizing: PairDrag.ResizingSeam) {
        guard system.uptime - resizing.lastLook >= Self.seamLookInterval else { return }
        var current = resizing
        current.lastLook = system.uptime
        let seam = current.seam
        guard seam != current.lastAskedSeam else {
            drag = .resizingSeam(current)
            return
        }
        current.lastAskedSeam = seam
        let held = current.heldFrame(seamAt: seam)
        let partner = current.partnerFrame(seamAt: seam)
        try? current.window.resize(to: held.size)
        try? current.partner.resize(to: partner.size)
        if let reached = try? current.window.frame() {
            current.heldLimits.note(
                asked: held.size.width, reached: reached.size.width, start: current.heldStart,
                partnerOn: current.side.opposite)
        }
        if let reached = try? current.partner.frame() {
            current.partnerLimits.note(
                asked: partner.size.width, reached: reached.size.width,
                start: current.partnerStart, partnerOn: current.side)
        }
        current.standIn?.setSeam(atOffset: current.seamOffset)
        drag = .resizingSeam(current)
    }

    /// Both windows come back, exactly to the seam. A window with another width than asked, at its
    /// minimum or maximum or rounding it, keeps its far edge, and the other meets it. Without
    /// pictures, macOS has resized the held window, and the partner goes beside it.
    func finishSeam(_ resizing: PairDrag.ResizingSeam) {
        var seam = resizing.seam
        if resizing.isPassing {
            guard let held = try? resizing.window.frame() else {
                endDrag()
                return
            }
            seam = SeamFollow.seam(of: held, partnerOn: resizing.side)
        } else {
            Self.apply(resizing.heldFrame(seamAt: seam), to: resizing.window, from: nil)
        }
        Self.apply(resizing.partnerFrame(seamAt: seam), to: resizing.partner, from: nil)
        meet(resizing, seamAsked: seam)
        forgetParking()
        if let standIn = resizing.standIn {
            drag = .settling(standIn: standIn, until: system.uptime + Self.settleTime)
        } else {
            endDrag()
        }
    }

    /// Each window keeps its far edge at the width it took, and the other meets it. Two windows
    /// that both round may not fit that way, as a terminal takes only whole characters.
    private func meet(_ resizing: PairDrag.ResizingSeam, seamAsked seam: Double) {
        guard let reachedHeld = try? resizing.window.frame() else { return }
        let held = SeamFollow.frame(
            start: resizing.heldStart, on: resizing.side.opposite,
            withWidth: reachedHeld.size.width)
        Self.apply(held, to: resizing.window, from: reachedHeld)
        let heldSeam = SeamFollow.seam(of: held, partnerOn: resizing.side)
        if heldSeam != seam {
            Self.apply(resizing.partnerFrame(seamAt: heldSeam), to: resizing.partner, from: nil)
        }
        guard let reached = try? resizing.partner.frame() else { return }
        let partner = SeamFollow.frame(
            start: resizing.partnerStart, on: resizing.side, withWidth: reached.size.width)
        Self.apply(partner, to: resizing.partner, from: reached)
        let met = SeamFollow.seam(of: partner, partnerOn: resizing.side.opposite)
        guard met != heldSeam else { return }
        Self.apply(resizing.heldFrame(seamAt: met), to: resizing.window, from: held)
        closeGap(resizing)
    }

    /// The last resort when the widths do not fit: no gap, with the partner's far edge a little
    /// off, by less than the step of the window's rounding.
    private func closeGap(_ resizing: PairDrag.ResizingSeam) {
        guard let held = try? resizing.window.frame(), let partner = try? resizing.partner.frame()
        else { return }
        let seam = SeamFollow.seam(of: held, partnerOn: resizing.side)
        let x = resizing.side == .right ? seam : seam - partner.size.width
        guard x != partner.origin.x else { return }
        try? resizing.partner.move(to: ScreenPoint(x: x, y: partner.origin.y))
    }

    /// Asks only for what changes, as each call takes the app time.
    private static func apply(
        _ frame: WindowFrame, to window: any MovableWindow, from last: WindowFrame?
    ) {
        if frame.origin != last?.origin { try? window.move(to: frame.origin) }
        if frame.size != last?.size { try? window.resize(to: frame.size) }
    }
}
