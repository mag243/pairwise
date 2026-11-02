import PairwiseCore

/// A window of a pair being resized at the seam, with its partner following (ADR 0045, 0046).
extension PairDragModel {
    /// macOS goes on resizing the window, so its events pass, up to a limit of the partner.
    func startFollowingSeam(_ pressed: PairDrag.Pressed) {
        let partner = WindowFrame(origin: pressed.partner.origin, size: pressed.partner.size)
        let side = pressed.partner.side
        startFollowing(
            PairDrag.ResizingSeam(
                window: pressed.window, partner: pressed.partner.window, partnerStart: partner,
                side: side, seamAtPress: SeamFollow.seam(of: pressed.frame, partnerOn: side),
                pointerXAtPress: pressed.pointer.x, lastExactWidth: partner.size.width))
    }

    /// The grip of a window's edge reaches past the window, so a press on one window of a pair
    /// can resize the other at the seam. That other window is the one held, then. Says whether
    /// this is such a press.
    func startFollowingSeamIfPartnerIsHeld(_ pressed: PairDrag.Pressed) -> Bool {
        let held = pressed.partner.window
        let start = WindowFrame(origin: pressed.partner.origin, size: pressed.partner.size)
        let side: PairSide = pressed.partner.side == .right ? .left : .right
        guard
            let now = held.serverFrame() ?? (try? held.frame()),
            DragHoldRule.isResize(from: start, to: now),
            SeamFollow.movesSeam(from: start, to: now, partnerOn: side)
        else { return false }
        startFollowing(
            PairDrag.ResizingSeam(
                window: held, partner: pressed.window, partnerStart: pressed.frame, side: side,
                seamAtPress: SeamFollow.seam(of: start, partnerOn: side),
                pointerXAtPress: pressed.pointer.x, lastExactWidth: pressed.frame.size.width))
        return true
    }

    private func startFollowing(_ resizing: PairDrag.ResizingSeam) {
        endDrag()
        drag = .resizingSeam(resizing)
        system.startTicking(every: Self.tickInterval) { [weak self] in self?.tick() }
    }

    func tick(_ resizing: PairDrag.ResizingSeam) {
        if resizing.isReleased || isButtonLetGo {
            finishSeam(resizing)
        } else {
            followSeam(resizing)
        }
    }

    /// A busy app catches up on a later tick. A held window past a limit comes back first,
    /// with its events withheld, so that macOS does not take it further.
    private func followSeam(_ resizing: PairDrag.ResizingSeam) {
        guard let now = resizing.window.serverFrame() ?? (try? resizing.window.frame()) else {
            return
        }
        var current = resizing
        let held = heldWithinLimits(now, resizing)
        let exact = SeamFollow.partnerFrame(
            start: resizing.partnerStart, partnerOn: resizing.side, beside: held, reach: 0)
        // Coming back to a limit is not growing: the seam stands still there.
        current.reach =
            held != now
            ? 0
            : SeamFollow.reach(
                after: current.reach, widthChange: exact.size.width - current.lastExactWidth)
        current.lastExactWidth = exact.size.width
        let target = SeamFollow.partnerFrame(
            start: resizing.partnerStart, partnerOn: resizing.side, beside: held,
            reach: current.reach)
        if target != current.lastPartnerFrame {
            Self.apply(target, to: resizing.partner, from: current.lastPartnerFrame)
            current.lastPartnerFrame = target
            if let reached = try? resizing.partner.frame() {
                current.limits.note(
                    asked: target.size.width, reached: reached.size.width,
                    start: resizing.partnerStart, partnerOn: resizing.side)
            }
        }
        drag = .resizingSeam(current)
    }

    private func heldWithinLimits(
        _ held: WindowFrame, _ resizing: PairDrag.ResizingSeam
    ) -> WindowFrame {
        let seam = SeamFollow.seam(of: held, partnerOn: resizing.side)
        let allowed = resizing.limits.clamped(seamAt: seam)
        guard allowed != seam else { return held }
        let frame = SeamFollow.heldFrame(held, seamAt: allowed, partnerOn: resizing.side)
        Self.apply(frame, to: resizing.window, from: held)
        return frame
    }

    /// Both windows go exactly against each other, as the last correction. A partner with
    /// another width than asked, at its minimum or maximum or rounding it, keeps its far edge,
    /// and the held window comes back to meet it.
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
