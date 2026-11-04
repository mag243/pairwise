import PairwiseCore

/// Joining two windows and parting them, with Command held from the press (ADR 0035, 0036).
extension PairDragModel {
    /// Parts a window in a pair, and watches where it goes. macOS drags it alone.
    func startJoining(
        _ number: UInt32, pointer: ScreenPoint, pressX: Double? = nil, held: PairDrag.Held? = nil
    ) -> String {
        if book.pair(containing: number) != nil { sound(.part) }
        endPair(of: number)
        guard
            let window = system.window(number: number),
            let frame = window.serverFrame() ?? (try? window.frame())
        else { return "no window to join with" }
        // The direction counts from the press, so that the key can come with the window at an edge.
        var heading = DragHeading(startingAt: pressX ?? pointer.x)
        heading.update(x: pointer.x)
        drag = .joining(
            PairDrag.Joining(
                window: window, number: number, frame: frame, pointer: pointer, heading: heading,
                held: held))
        system.setJoinChoiceInputWatched(true)
        system.startTicking(every: Self.tickInterval) { [weak self] in self?.tick() }
        return "joining"
    }

    /// The join key came during the drag of a pair, before the panel took over. While macOS
    /// is dragging, the events go on passing; once they are withheld, as the window has moved,
    /// Pairwise moves it from here on. Says whether the events are withheld.
    func part(_ pressed: PairDrag.Pressed, at point: ScreenPoint) -> Bool {
        let held =
            pressed.hasWindowMoved
            ? PairDrag.Held(frame: pressed.frame, pointer: pressed.pointer) : nil
        endDrag()
        lastPressOutcome = startJoining(
            pressed.number, pointer: point, pressX: pressed.pointer.x, held: held)
        return held != nil
    }

    /// The join key came with the panel up. The dragged window goes where the panel shows it
    /// and the partner back to where it was, both before the panel comes down, so that no
    /// place flashes empty. A busy app stays where it is, as the drag goes on regardless.
    func part(_ moving: PairDrag.Moving) {
        try? moving.window.move(to: moving.origin(forPointer: moving.lastPointer))
        try? moving.partner.window.move(to: moving.partner.origin)
        forgetParking()
        endDrag()
        lastPressOutcome = startJoining(
            moving.number, pointer: moving.lastPointer, pressX: moving.pointer.x,
            held: PairDrag.Held(frame: moving.frame, pointer: moving.pointer))
    }

    /// The join key came during the drag of a window in no pair.
    func startJoiningFreeWindow(at point: ScreenPoint) {
        guard let number = freeWindowPressed else { return }
        freeWindowPressed = nil
        lastPressOutcome = startJoining(number, pointer: point, pressX: freeWindowPressX)
        hasSeenButtonDown = true
    }

    /// A key changed, perhaps with the pointer standing still. The next tick acts on it.
    /// Elsewhere the next drag event carries the same keys (ADR 0041).
    func keysChanged(isJoinKeyDown: Bool, isEqualHeightKeyDown: Bool, isScopeKeyDown: Bool) {
        switch drag {
        case .joining(var joining):
            joining.isKeyDown = isJoinKeyDown
            joining.isTakingHeight = isEqualHeightKeyDown
            joining.isScopeKeyDown = isScopeKeyDown
            drag = .joining(joining)
        case .moving(var moving):
            moving.wantsParting = moving.wantsParting || isJoinKeyDown
            drag = .moving(moving)
        default:
            break
        }
    }

    /// Keeps the guide on the place the window would join, once it has moved.
    func watch(_ joining: PairDrag.Joining) {
        var joining = joining
        moveHeldWindow(&joining)
        joining.heading.update(x: joining.pointer.x)
        guard joining.isKeyDown else {
            dropJoinPlace(of: joining)
            return
        }
        guard
            let now = joining.window.serverFrame() ?? (try? joining.window.frame()),
            DragHoldRule.isMove(from: joining.frame, to: now)
        else {
            drag = .joining(joining)
            return
        }
        let windows = system.normalWindows()
        let candidates = JoinRule.candidates(
            for: joining.number, among: windows,
            scope: joinScope.switched(if: joining.isScopeKeyDown)
        ).filter { book.pair(containing: $0.number) == nil }
        let joinable = Set(candidates.map(\.number))
        var current = joining
        current.pick.update(
            to: JoinRule.choices(
                for: now, pointer: joining.pointer,
                among: windows.filter { $0.number != joining.number },
                heading: joining.heading.direction, isJoinable: { joinable.contains($0.number) }))
        current.target = current.pick.place.map {
            JoinRule.target(at: $0, for: now, takingHeight: joining.isTakingHeight)
        }
        drag = .joining(current)
        if current.target != joining.target { Self.log(current, frame: now, candidates) }
        if let target = current.target {
            system.showJoinGuide(at: target.frame)
            system.showJoinTargetOutline(at: target.other.frame)
        } else {
            hideJoinMarks()
        }
    }

    /// The key is up: nothing joins, and going through the windows starts anew, with the key
    /// pressed again (ADR 0069).
    private func dropJoinPlace(of joining: PairDrag.Joining) {
        var current = joining
        current.target = nil
        current.pick = JoinPick()
        drag = .joining(current)
        hideJoinMarks()
    }

    /// Goes through the places to join by the steps of an input, which the next tick shows.
    /// Says whether the input is Pairwise's own: only while the join key is down in a join.
    func chooseJoinPlace(steps: (inout JoinScroll) -> Int) -> Bool {
        guard case .joining(var joining) = drag, joining.isKeyDown else { return false }
        joining.pick.advance(by: steps(&joining.scroll))
        drag = .joining(joining)
        return true
    }

    func hideJoinMarks() {
        system.hideJoinGuide()
        system.hideJoinTargetOutline()
    }

    private func moveHeldWindow(_ joining: inout PairDrag.Joining) {
        guard var held = joining.held else { return }
        let place = held.origin(forPointer: joining.pointer)
        guard place != held.lastPlace else { return }
        try? joining.window.move(to: place)
        held.lastPlace = place
        joining.held = held
    }

    /// The window takes its place beside the other, and the two become a pair. A failure
    /// leaves the window where it is, and no pair. A window with no place to join stays where
    /// macOS or the pointer took it.
    func finish(_ joining: PairDrag.Joining) {
        defer { endDrag() }
        // A key let go since the last tick counts, though the tick has not cleared the place.
        let place = joining.isKeyDown ? joining.target : nil
        Self.logger.info("joining ended, place found: \(place != nil)")
        guard let target = place else {
            var last = joining
            moveHeldWindow(&last)
            return
        }
        guard let other = system.window(number: target.other.number) else {
            Self.logger.info("the window to join has no element: \(target.other.number)")
            return
        }
        do {
            if joining.isTakingHeight { try joining.window.resize(to: target.frame.size) }
            try joining.window.move(to: target.frame.origin)
            try join(joining.window, to: other, on: target.side)
            // Raised last, the dragged window ends on top; a failure leaves it where it is.
            try? other.raise()
            try? joining.window.raise()
            sound(.join)
            if let seam = Self.seam(of: target) {
                system.flashSeam(at: seam.frame(width: Self.seamWidth))
            }
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

    static func seam(of target: JoinTarget) -> Seam? {
        target.side == .right
            ? Seam.between(left: target.other.frame, right: target.frame)
            : Seam.between(left: target.frame, right: target.other.frame)
    }
}
