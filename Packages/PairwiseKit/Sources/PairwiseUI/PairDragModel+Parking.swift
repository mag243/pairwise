import Foundation
import PairwiseCore

/// A window with the frame it belongs at, on its way out of sight (ADR 0053).
struct WindowToPark {
    let window: any MovableWindow
    let frame: WindowFrame
}

/// Keeping a record of parked windows, so that a crash does not lose them (ADR 0053).
extension PairDragModel {
    /// Writes where `windows` belong, before the first of them leaves. A drag that has started
    /// parking keeps its record, as these windows are not back yet.
    func recordParking(of windows: [WindowToPark]) {
        guard !isParkingRecorded else { return }
        let onScreen = system.normalWindows()
        let parked = windows.compactMap { item -> ParkedWindow? in
            guard
                let number = item.window.windowNumber,
                let owner = onScreen.first(where: { $0.number == number })?.owner
            else { return nil }
            return ParkedWindow(number: number, owner: owner, frame: item.frame)
        }
        system.saveParkingRecord(
            ParkingRecord(savedAt: system.uptime, windows: parked).encoded())
        isParkingRecorded = true
    }

    /// The windows are back where they belong.
    func forgetParking() {
        guard isParkingRecorded else { return }
        isParkingRecorded = false
        system.saveParkingRecord(nil)
    }

    /// Puts back what an earlier run left parked. It asks the windows' apps, so it comes once,
    /// when Pairwise starts.
    func putBackParkedWindows() {
        guard let data = system.loadParkingRecord() else { return }
        defer { system.saveParkingRecord(nil) }
        guard let record = ParkingRecord(data: data) else {
            Self.logger.info("the record of parked windows cannot be read")
            return
        }
        let parked = record.windowsToPutBack(now: system.uptime, among: system.normalWindows())
        for item in parked {
            guard let window = system.window(number: item.number) else { continue }
            try? window.resize(to: item.frame.size)
            try? window.move(to: item.frame.origin)
        }
        Self.logger.info("put back \(parked.count) windows left parked")
    }
}
