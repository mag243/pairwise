/// What a pair's windows need as other windows come and go (ADR 0052).
public enum PairWatch {
    /// A window on top, with a partner to bring up behind it.
    public struct Raise: Equatable, Sendable {
        public let window: UInt32
        public let partner: UInt32

        public init(window: UInt32, partner: UInt32) {
            self.window = window
            self.partner = partner
        }
    }

    /// What to bring forward among `windows`, frontmost first: nothing unless the frontmost
    /// window is in a pair, and its partner is on the list but not right behind it.
    public static func partnerToBringForward(
        windows: [ScreenWindow], pairs: [WindowPair]
    ) -> Raise? {
        guard let top = windows.first?.number else { return nil }
        for pair in pairs where pair.left == top || pair.right == top {
            let partner = pair.left == top ? pair.right : pair.left
            guard
                let place = windows.firstIndex(where: { $0.number == partner }), place > 1
            else { return nil }
            return Raise(window: top, partner: partner)
        }
        return nil
    }
}
