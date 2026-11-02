import Foundation
import PairwiseCore

/// What the model knows of the lock on a seam (ADR 0042).
struct SeamLockWatch {
    var isWatching = false
    /// The lock that shows.
    var lock: SeamLock?
    /// Where the pointer was at the last look at the windows.
    var lastPointer: ScreenPoint?
}

/// The lock on a seam: it shows near the pointer, and a click on it ends the pair.
extension PairDragModel {
    /// How often the pointer is looked at while a pair exists, in seconds.
    private static let pointerInterval: TimeInterval = 0.1

    /// Watches the pointer while Pairwise runs and a pair exists, and otherwise costs nothing.
    func updatePointerWatching() {
        let wanted = isRunning && !book.pairs.isEmpty
        guard wanted != lockWatch.isWatching else { return }
        lockWatch.isWatching = wanted
        if wanted {
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
        let pointer = system.pointerLocation
        guard pointer != lockWatch.lastPointer || lockWatch.lock != nil else { return }
        lockWatch.lastPointer = pointer
        let lock = SeamLockRule.lock(
            pointer: pointer, pairs: book.pairs, windows: system.normalWindows(),
            isShowing: lockWatch.lock != nil)
        guard lock != lockWatch.lock else { return }
        if let lock {
            lockWatch.lock = lock
            system.showSeamLock(at: lock.frame)
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

    /// Says whether a release ends a click on the lock. Only a release on the lock ends the
    /// pair, as with any button.
    func releaseLock(at point: ScreenPoint) -> Bool {
        guard case .clickingLock(let lock) = drag else { return false }
        drag = .none
        if lock.frame.contains(point) {
            endPair(of: lock.pair.left)
            system.flashOpenSeamLock(at: lock.frame)
        }
        return true
    }
}
