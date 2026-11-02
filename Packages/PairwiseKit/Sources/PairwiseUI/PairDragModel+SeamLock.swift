import Foundation
import PairwiseCore

/// What the model knows of the lock on a seam (ADR 0044).
struct SeamLockWatch {
    var isWatching = false
    /// The lock that shows.
    var lock: SeamLock?
    /// Where the pointer was at the last look at the windows.
    var lastPointer: ScreenPoint?
}

/// The lock on a seam: it shows near the pointer, and a click on it parts or joins.
extension PairDragModel {
    /// How often the pointer is looked at while Pairwise runs, in seconds.
    private static let pointerInterval: TimeInterval = 0.1

    /// Watches the pointer while Pairwise runs, and otherwise costs nothing.
    func updatePointerWatching() {
        guard isRunning != lockWatch.isWatching else { return }
        lockWatch.isWatching = isRunning
        if isRunning {
            system.startWatchingPointer(every: Self.pointerInterval) { [weak self] in
                self?.lookAtPointer()
            }
        } else {
            system.stopWatchingPointer()
            hideLock()
        }
    }

    /// Reads the window list only when the pointer has moved or a lock shows, as a lock can
    /// have to go under a still pointer.
    private func lookAtPointer() {
        if case .clickingLock = drag { return }
        guard case .none = drag, !system.isPrimaryButtonDown else {
            hideLock()
            return
        }
        lookAtPairs()
        let pointer = system.pointerLocation
        guard pointer != lockWatch.lastPointer || lockWatch.lock != nil else { return }
        updateLock(forPointerAt: pointer)
    }

    private func updateLock(forPointerAt pointer: ScreenPoint) {
        lockWatch.lastPointer = pointer
        let lock = SeamLockRule.lock(
            pointer: pointer, pairs: book.pairs, windows: system.normalWindows(),
            scope: joinScope, isShowing: lockWatch.lock != nil)
        guard lock != lockWatch.lock else { return }
        if let lock {
            lockWatch.lock = lock
            system.showSeamLock(at: lock.frame, isClosed: lock.isClosed)
        } else {
            hideLock()
        }
    }

    /// Takes the lock away. The next look at the pointer decides anew, also if it stays still.
    func hideLock() {
        lockWatch.lastPointer = nil
        guard lockWatch.lock != nil else { return }
        lockWatch.lock = nil
        system.hideSeamLock()
    }

    /// Says whether a press is on the lock, and so Pairwise's own. Any other press takes the
    /// lock away.
    func pressLock(at point: ScreenPoint) -> Bool {
        guard let lock = lockWatch.lock else { return false }
        guard lock.frame.contains(point) else {
            hideLock()
            return false
        }
        drag = .clickingLock(lock)
        lastPressOutcome = "the lock"
        return true
    }

    /// Says whether a release ends a click on the lock. Only a release on the lock acts, as
    /// with any button. Ending a pair asks no app, and the lock turns open at once.
    func releaseLock(at point: ScreenPoint) -> Bool {
        guard case .clickingLock(let lock) = drag else { return false }
        drag = .none
        guard lock.frame.contains(point) else { return true }
        if lock.isClosed {
            sound(.part)
            endPair(of: lock.pair.left)
            updateLock(forPointerAt: point)
        } else {
            drag = .closingLock(lock)
            system.startTicking(every: Self.tickInterval) { [weak self] in self?.tick() }
        }
        return true
    }

    /// Joins the windows of an open lock. The one further back goes tight against the one in
    /// front, with its top, as a pair's tops are level. A failure leaves them as they are.
    func closeLock(_ lock: SeamLock) {
        defer {
            endDrag()
            updateLock(forPointerAt: system.pointerLocation)
        }
        let windows = system.normalWindows()
        guard
            let front = windows.first(where: {
                $0.number == lock.pair.left || $0.number == lock.pair.right
            }),
            let back = windows.first(where: {
                $0.number != front.number
                    && ($0.number == lock.pair.left || $0.number == lock.pair.right)
            }),
            let backWindow = system.window(number: back.number),
            let frontWindow = system.window(number: front.number)
        else { return }
        let side: PairSide = back.number == lock.pair.left ? .left : .right
        let target = JoinRule.target(joining: back.frame, beside: front, on: side)
        do {
            if target.frame != back.frame { try backWindow.move(to: target.frame.origin) }
            try join(backWindow, to: frontWindow, on: side)
            // Raised last, the window in front stays there; a failure leaves it where it is.
            try? backWindow.raise()
            try? frontWindow.raise()
            sound(.join)
            if let seam = Self.seam(of: target) {
                system.flashSeam(at: seam.frame(width: Self.seamWidth))
            }
        } catch {
            Self.logger.info(
                "the lock did not join: \(String(describing: error), privacy: .public)")
        }
    }
}
