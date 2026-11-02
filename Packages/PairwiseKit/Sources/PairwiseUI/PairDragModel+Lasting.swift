import Foundation
import PairwiseCore

/// What the model keeps track of for pairs that last (ADR 0054).
struct LastingPairs {
    /// Saved pairs whose windows have not been found yet.
    var pending: [SavedPair] = []
    var isSameBoot = true
    var firstTry: TimeInterval = 0
    var lastTry: TimeInterval = 0
    var hasLoaded = false
    var needsSaving = false
    /// What each pair last looked like, by its left window, for a window now off the screen.
    var lastSaved: [UInt32: SavedPair] = [:]
}

/// Pairs that survive a quit, a crash or a restart (ADR 0054).
extension PairDragModel {
    /// How long saved pairs are looked for after a start, as apps can open windows later.
    private static let lookingTime: TimeInterval = 120
    private static let tryInterval: TimeInterval = 1

    /// Reads the saved pairs, once, and brings back those already there.
    func loadSavedPairs() {
        guard keepsPairs, !lasting.hasLoaded else { return }
        lasting.hasLoaded = true
        guard let data = system.loadPairsRecord() else { return }
        guard let record = SavedPairs(data: data) else {
            Self.logger.info("the saved pairs cannot be read")
            system.savePairsRecord(nil)
            return
        }
        lasting.pending = record.pairs
        lasting.isSameBoot = system.uptime >= record.savedAt
        lasting.firstTry = system.uptime
        tryPendingPairs()
    }

    /// Runs often, and costs nothing unless a save or a search is due.
    func keepPairsUpToDate() {
        if lasting.needsSaving { savePairs() }
        guard !lasting.pending.isEmpty,
            system.uptime - lasting.lastTry >= Self.tryInterval
        else { return }
        if system.uptime - lasting.firstTry >= Self.lookingTime {
            Self.logger.info("gave up on \(self.lasting.pending.count) saved pairs")
            lasting.pending = []
            savePairs()
        } else {
            tryPendingPairs()
        }
    }

    private func tryPendingPairs() {
        lasting.lastTry = system.uptime
        let windows = system.windowIdentities()
        // Joining changes `lasting` too, so this does not go through the list in place.
        lasting.pending = lasting.pending.filter { saved in
            guard
                let pair = PairRestore.find(
                    saved, among: windows, isSameBoot: lasting.isSameBoot),
                let left = system.window(number: pair.left),
                let right = system.window(number: pair.right)
            else { return true }
            // Neither window moves. Windows that cannot be joined any more are done with.
            try? join(left, to: right, on: .left)
            return false
        }
    }

    /// Writes the pairs there are and those still looked for.
    func savePairs() {
        lasting.needsSaving = false
        guard keepsPairs else { return }
        let windows = system.windowIdentities()
        var saved: [UInt32: SavedPair] = [:]
        for pair in book.pairs {
            if let left = windows.first(where: { $0.number == pair.left }),
                let right = windows.first(where: { $0.number == pair.right })
            {
                saved[pair.left] = SavedPair(left: left, right: right)
            } else {
                saved[pair.left] = lasting.lastSaved[pair.left]
            }
        }
        lasting.lastSaved = saved
        let all = book.pairs.compactMap { saved[$0.left] } + lasting.pending
        system.savePairsRecord(
            all.isEmpty ? nil : SavedPairs(savedAt: system.uptime, pairs: all).encoded())
    }
}
