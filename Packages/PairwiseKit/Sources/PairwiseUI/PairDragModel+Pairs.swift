import PairwiseCore

/// Which windows are pairs (ADR 0033).
extension PairDragModel {
    /// Makes a pair of `window` and `other`, with `window` on `side` of it.
    public func join(
        _ window: any MovableWindow, to other: any MovableWindow, on side: PairSide
    ) throws(PairError) {
        guard let number = window.windowNumber, let otherNumber = other.windowNumber else {
            throw .unknownWindow
        }
        try book.join(number, to: otherNumber, on: side)
        pairedWindows[number] = window
        pairedWindows[otherNumber] = other
        updatePointerWatching()
    }

    /// Ends the pair that `window` is in, if any.
    public func leavePair(of window: any MovableWindow) {
        if let number = window.windowNumber { endPair(of: number) }
    }

    func endPair(of number: UInt32) {
        if let partner = book.partner(of: number) { pairedWindows[partner.window] = nil }
        pairedWindows[number] = nil
        book.end(pairContaining: number)
        if let pair = lockWatch.lock?.pair, pair.left == number || pair.right == number {
            hideLock()
        }
        updatePointerWatching()
    }
}
