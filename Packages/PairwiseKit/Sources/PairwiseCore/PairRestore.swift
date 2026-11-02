import Foundation

/// What can be known about a window, to find it again after a restart (ADR 0054).
public struct WindowIdentity: Codable, Equatable, Sendable {
    public let number: UInt32
    /// The process that owns the window.
    public let owner: Int32
    /// The identifier of its app, or `nil` when the system does not say.
    public let app: String?
    /// A hash of its title, as a title can name a private document, or `nil` without a title.
    public let titleKey: String?
    public let frame: WindowFrame

    public init(number: UInt32, owner: Int32, app: String?, titleKey: String?, frame: WindowFrame) {
        self.number = number
        self.owner = owner
        self.app = app
        self.titleKey = titleKey
        self.frame = frame
    }
}

/// A pair as it was saved.
public struct SavedPair: Codable, Equatable, Sendable {
    public let left: WindowIdentity
    public let right: WindowIdentity

    public init(left: WindowIdentity, right: WindowIdentity) {
        self.left = left
        self.right = right
    }
}

/// The pairs kept between runs of the app (ADR 0054).
public struct SavedPairs: Codable, Equatable, Sendable {
    /// The time since the Mac started, when this was written.
    public let savedAt: TimeInterval
    public let pairs: [SavedPair]

    public init(savedAt: TimeInterval, pairs: [SavedPair]) {
        self.savedAt = savedAt
        self.pairs = pairs
    }

    /// Reads a record, or gives `nil` when `data` does not hold one.
    public init?(data: Data) {
        guard let record = try? JSONDecoder().decode(SavedPairs.self, from: data) else {
            return nil
        }
        self = record
    }

    /// The record as data to write, or `nil` when it cannot be encoded.
    public func encoded() -> Data? {
        try? JSONEncoder().encode(self)
    }
}

/// Finding a saved pair again, which prefers losing it to joining the wrong windows.
public enum PairRestore {
    /// How far a frame or a top may be off and still be the same, in points.
    private static let tolerance = 2.0

    /// The windows of `saved` among `windows`, or `nil` unless both are found for certain and
    /// still stand side by side with their tops level. Nothing needs to move for such a pair.
    /// `isSameBoot` says whether window numbers can still mean what they did.
    public static func find(
        _ saved: SavedPair, among windows: [WindowIdentity], isSameBoot: Bool
    ) -> WindowPair? {
        guard
            let left = find(saved.left, among: windows, isSameBoot: isSameBoot),
            let right = find(saved.right, among: windows, isSameBoot: isSameBoot),
            left.number != right.number,
            Seam.between(left: left.frame, right: right.frame) != nil,
            abs(left.frame.origin.y - right.frame.origin.y) <= tolerance
        else { return nil }
        return WindowPair(left: left.number, right: right.number)
    }

    private static func find(
        _ saved: WindowIdentity, among windows: [WindowIdentity], isSameBoot: Bool
    ) -> WindowIdentity? {
        if isSameBoot,
            let same = windows.first(where: {
                $0.number == saved.number && $0.owner == saved.owner && $0.app == saved.app
            })
        {
            return same
        }
        guard saved.app != nil else { return nil }
        let ofApp = windows.filter { $0.app == saved.app }
        let atFrame = ofApp.filter { isSameFrame($0.frame, saved.frame) }
        if atFrame.count == 1 { return atFrame[0] }
        guard saved.titleKey != nil else { return nil }
        let byTitle = ofApp.filter {
            $0.titleKey == saved.titleKey && isSameSize($0.frame, saved.frame)
        }
        return byTitle.count == 1 ? byTitle[0] : nil
    }

    private static func isSameFrame(_ first: WindowFrame, _ second: WindowFrame) -> Bool {
        isSameSize(first, second) && first.origin.distance(to: second.origin) <= tolerance
    }

    private static func isSameSize(_ first: WindowFrame, _ second: WindowFrame) -> Bool {
        abs(first.size.width - second.size.width) <= tolerance
            && abs(first.size.height - second.size.height) <= tolerance
    }
}
