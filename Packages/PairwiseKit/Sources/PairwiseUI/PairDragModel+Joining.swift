import PairwiseCore

/// Joining two windows and parting them, with Command held from the press (ADR 0035, 0036).
extension PairDragModel {
    /// Parts a window in a pair, and watches where it goes. macOS drags it alone.
    func startJoining(_ number: UInt32, pointer: ScreenPoint) -> String {
        endPair(of: number)
        guard
            let window = system.window(number: number),
            let frame = window.serverFrame() ?? (try? window.frame())
        else { return "no window to join with" }
        drag = .joining(
            PairDrag.Joining(window: window, number: number, frame: frame, pointer: pointer))
        system.startTicking(every: Self.tickInterval) { [weak self] in self?.tick() }
        return "joining"
    }

    /// Keeps the guide on the place the window would join, once it has moved.
    func watch(_ joining: PairDrag.Joining) {
        guard
            let now = joining.window.serverFrame() ?? (try? joining.window.frame()),
            DragHoldRule.isMove(from: joining.frame, to: now)
        else { return }
        let candidates = system.normalWindows().filter { window in
            window.number != joining.number && book.pair(containing: window.number) == nil
        }
        var current = joining
        current.target = JoinRule.target(for: now, pointer: joining.pointer, among: candidates)
        drag = .joining(current)
        if current.target != joining.target { Self.log(current, frame: now, candidates) }
        if let target = current.target {
            system.showJoinGuide(at: target.frame)
        } else {
            system.hideJoinGuide()
        }
    }

    /// The window takes its place beside the other, and the two become a pair. A failure
    /// leaves the window where macOS put it, and no pair.
    func finish(_ joining: PairDrag.Joining) {
        defer { endDrag() }
        Self.logger.info("joining ended, place found: \(joining.target != nil)")
        guard let target = joining.target else { return }
        guard let other = system.window(number: target.other.number) else {
            Self.logger.info("the window to join has no element: \(target.other.number)")
            return
        }
        do {
            try joining.window.resize(to: target.frame.size)
            try joining.window.move(to: target.frame.origin)
            try? joining.window.raise()
            try join(joining.window, to: other, on: target.side)
            system.flashSeam(at: Self.seam(of: target))
        } catch {
            Self.logger.info(
                "the windows did not join: \(String(describing: error), privacy: .public)")
        }
    }

    private static func log(
        _ joining: PairDrag.Joining, frame: WindowFrame, _ candidates: [ScreenWindow]
    ) {
        let found =
            joining.target.map { "\($0.other.number) \($0.side) \($0.other.frame)" } ?? "none"
        logger.info(
            """
            join place: \(found, privacy: .public); window \(String(describing: frame), privacy: .public), \
            pointer \(String(describing: joining.pointer), privacy: .public), \
            \(candidates.count) candidates
            """)
    }

    private static func seam(of target: JoinTarget) -> WindowFrame {
        let x = target.side == .right ? target.other.frame.maxX : target.other.frame.origin.x
        return WindowFrame(
            x: x - seamWidth / 2, y: target.frame.origin.y, width: seamWidth,
            height: target.frame.size.height)
    }
}
