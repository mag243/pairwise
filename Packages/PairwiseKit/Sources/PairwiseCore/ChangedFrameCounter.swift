/// Counts the live frames that differ from the one before at a sampled pixel. The system
/// also sends frames of a window that has not changed, so counting all of them says nothing
/// (ADR 0029).
public struct ChangedFrameCounter: Sendable {
    /// How many frames showed a change.
    public private(set) var changes = 0
    private var last: UInt32?

    public init() {}

    /// Notes the sampled pixel of a frame, or `nil` when the frame gave none.
    public mutating func note(_ pixel: UInt32?) {
        guard let pixel else { return }
        if let last, last != pixel { changes += 1 }
        last = pixel
    }
}
