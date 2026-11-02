/// The side of a pair a window is on.
public enum PairSide: Equatable, Sendable {
    case left
    case right
}

/// Two windows that move together, known by their window numbers.
/// Invariant: `left` and `right` differ.
public struct WindowPair: Equatable, Sendable {
    public let left: UInt32
    public let right: UInt32

    /// Precondition: `left` and `right` differ.
    public init(left: UInt32, right: UInt32) {
        precondition(left != right, "left and right differ")
        self.left = left
        self.right = right
    }
}

/// Why two windows cannot become a pair.
public enum PairError: Error, Equatable, Sendable {
    /// A window cannot pair with itself.
    case sameWindow
    /// One of the windows is in a pair already.
    case alreadyInPair
    /// The system does not know one of the windows.
    case unknownWindow
}

/// The pairs that exist (ADR 0033).
/// Invariant: a window is in one pair at most.
public struct PairBook: Equatable, Sendable {
    public private(set) var pairs: [WindowPair] = []

    public init() {}

    /// Makes a pair of `window` and `other`, with `window` on `side` of it.
    public mutating func join(
        _ window: UInt32, to other: UInt32, on side: PairSide
    ) throws(PairError) {
        guard window != other else { throw .sameWindow }
        guard pair(containing: window) == nil, pair(containing: other) == nil else {
            throw .alreadyInPair
        }
        pairs.append(
            side == .left
                ? WindowPair(left: window, right: other) : WindowPair(left: other, right: window))
    }

    /// The pair that `window` is in, if any.
    public func pair(containing window: UInt32) -> WindowPair? {
        pairs.first { $0.left == window || $0.right == window }
    }

    /// The window paired with `window`, and the side that partner is on.
    public func partner(of window: UInt32) -> (window: UInt32, side: PairSide)? {
        guard let pair = pair(containing: window) else { return nil }
        return pair.left == window ? (pair.right, .right) : (pair.left, .left)
    }

    /// Ends the pair that `window` is in, if any.
    public mutating func end(pairContaining window: UInt32) {
        pairs.removeAll { $0.left == window || $0.right == window }
    }
}
