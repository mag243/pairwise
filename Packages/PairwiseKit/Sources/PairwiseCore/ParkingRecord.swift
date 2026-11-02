import Foundation

/// A window parked out of sight, and what puts it back (ADR 0053).
public struct ParkedWindow: Codable, Equatable, Sendable {
    public let number: UInt32
    /// The process that owns the window, as a number can come back for another window.
    public let owner: Int32
    /// Where the window belongs.
    public let frame: WindowFrame

    public init(number: UInt32, owner: Int32, frame: WindowFrame) {
        self.number = number
        self.owner = owner
        self.frame = frame
    }
}

/// What was parked, kept outside the process so that it survives a crash (ADR 0053).
public struct ParkingRecord: Codable, Equatable, Sendable {
    /// The time since the Mac started, when this was written.
    public let savedAt: TimeInterval
    public let windows: [ParkedWindow]

    public init(savedAt: TimeInterval, windows: [ParkedWindow]) {
        self.savedAt = savedAt
        self.windows = windows
    }

    /// Reads a record, or gives `nil` when `data` does not hold one.
    public init?(data: Data) {
        guard let record = try? JSONDecoder().decode(ParkingRecord.self, from: data) else {
            return nil
        }
        self = record
    }

    /// The record as data to write, or `nil` when it cannot be encoded.
    public func encoded() -> Data? {
        try? JSONEncoder().encode(self)
    }

    /// The windows that can still be the ones parked: from this boot of the Mac, as `now` is
    /// not before the record, and with a window of that number and process among `windows`.
    public func windowsToPutBack(now: TimeInterval, among windows: [ScreenWindow]) -> [ParkedWindow]
    {
        guard now >= savedAt else { return [] }
        return self.windows.filter { parked in
            windows.contains { $0.number == parked.number && $0.owner == parked.owner }
        }
    }
}
