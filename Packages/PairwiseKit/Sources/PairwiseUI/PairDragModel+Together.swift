import Foundation
import PairwiseCore

/// What the model remembers of the windows of its pairs (ADR 0052).
struct TogetherWatch {
    var lastLook: TimeInterval = 0
    /// The frontmost window at the last look, as a change of it is what starts a raise.
    var lastTop: UInt32?
    /// The left windows of pairs of which both windows have been seen minimized.
    var minimized: Set<UInt32> = []
}

/// A pair that comes forward and minimizes as one window (ADR 0052).
extension PairDragModel {
    /// How often the windows of pairs are looked at, in seconds.
    private static let togetherInterval: TimeInterval = 0.25

    /// Reads the window list, without asking any app, and asks an app only about a window of
    /// a pair that left the list.
    func lookAtPairs() {
        keepPairsUpToDate()
        guard !book.pairs.isEmpty,
            system.uptime - togetherWatch.lastLook >= Self.togetherInterval
        else { return }
        togetherWatch.lastLook = system.uptime
        let windows = system.normalWindows()
        let onScreen = Set(windows.map(\.number))
        for pair in book.pairs { updatePresence(of: pair, onScreen: onScreen) }
        bringForward(among: windows)
    }

    /// Once per change of the frontmost window, so that an app that refuses is left alone.
    private func bringForward(among windows: [ScreenWindow]) {
        let top = windows.first?.number
        guard top != togetherWatch.lastTop else { return }
        togetherWatch.lastTop = top
        guard
            let raise = PairWatch.partnerToBringForward(windows: windows, pairs: book.pairs),
            let window = pairedWindows[raise.window],
            let partner = pairedWindows[raise.partner]
        else { return }
        // Raised last, the window stays on top and keeps focus.
        try? partner.raise()
        try? window.raise()
    }

    private func updatePresence(of pair: WindowPair, onScreen: Set<UInt32>) {
        guard let left = pairedWindows[pair.left], let right = pairedWindows[pair.right] else {
            return
        }
        switch (onScreen.contains(pair.left), onScreen.contains(pair.right)) {
        case (true, true):
            togetherWatch.minimized.remove(pair.left)
        case (false, false):
            // A window on another Space is off the list too, and is not minimized.
            if left.isMinimized, right.isMinimized { togetherWatch.minimized.insert(pair.left) }
        case (true, false):
            update(shown: left, hidden: right, of: pair)
        case (false, true):
            update(shown: right, hidden: left, of: pair)
        }
    }

    /// While the shown window's own minimizing is under way, it is still on the list, and only
    /// a pair that was seen minimized as a whole can be coming back.
    private func update(
        shown: any MovableWindow, hidden: any MovableWindow, of pair: WindowPair
    ) {
        if togetherWatch.minimized.contains(pair.left) {
            try? hidden.setMinimized(false)
        } else if hidden.isMinimized {
            try? shown.setMinimized(true)
        } else if !hidden.isAvailable {
            endPair(of: pair.left)
        }
    }
}
