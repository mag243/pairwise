import PairwiseCore

/// A window of a pair being resized at the seam, with its partner following (ADR 0045).
extension PairDragModel {
    /// macOS goes on resizing the window, so its events pass from here on.
    func startFollowingSeam(_ pressed: PairDrag.Pressed) {
        endDrag()
        let partner = WindowFrame(origin: pressed.partner.origin, size: pressed.partner.size)
        drag = .resizingSeam(
            PairDrag.ResizingSeam(
                window: pressed.window, partner: pressed.partner.window,
                partnerStart: partner, side: pressed.partner.side))
        system.startTicking(every: Self.tickInterval) { [weak self] in self?.tick() }
    }

    func tick(_ resizing: PairDrag.ResizingSeam) {
        if resizing.isReleased || isButtonLetGo {
            finishSeam(resizing)
        } else {
            followSeam(resizing)
        }
    }

    /// A busy app catches up on a later tick.
    private func followSeam(_ resizing: PairDrag.ResizingSeam) {
        guard let held = resizing.window.serverFrame() ?? (try? resizing.window.frame()) else {
            return
        }
        let target = SeamFollow.partnerFrame(
            start: resizing.partnerStart, partnerOn: resizing.side, beside: held,
            reach: SeamFollow.reachUnderHeldWindow)
        guard target != resizing.lastPartnerFrame else { return }
        Self.apply(target, to: resizing.partner, from: resizing.lastPartnerFrame)
        var current = resizing
        current.lastPartnerFrame = target
        drag = .resizingSeam(current)
    }

    /// Both windows go exactly against each other. A partner with another width than asked,
    /// at its minimum or maximum or rounding it, keeps its far edge, and the held window
    /// comes back to meet it.
    func finishSeam(_ resizing: PairDrag.ResizingSeam) {
        defer { endDrag() }
        guard let held = try? resizing.window.frame() else { return }
        let target = SeamFollow.partnerFrame(
            start: resizing.partnerStart, partnerOn: resizing.side, beside: held, reach: 0)
        Self.apply(target, to: resizing.partner, from: resizing.lastPartnerFrame)
        guard let reached = try? resizing.partner.frame() else { return }
        let partner = SeamFollow.partnerFrame(
            start: resizing.partnerStart, partnerOn: resizing.side,
            withWidth: reached.size.width)
        Self.apply(partner, to: resizing.partner, from: reached)
        let meeting = SeamFollow.heldFrame(held, meeting: partner, partnerOn: resizing.side)
        if meeting != held { Self.apply(meeting, to: resizing.window, from: held) }
    }

    /// Asks only for what changes, as each call takes the app time.
    private static func apply(
        _ frame: WindowFrame, to window: any MovableWindow, from last: WindowFrame?
    ) {
        if frame.origin != last?.origin { try? window.move(to: frame.origin) }
        if frame.size != last?.size { try? window.resize(to: frame.size) }
    }
}
