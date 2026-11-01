/// Finds a window among the system's on-screen windows, which the Accessibility API
/// cannot point to directly (ADR 0014).
public enum WindowMatch {
    /// Sizes from the two APIs can differ by rounding.
    private static let sizeTolerance = 1.0

    /// The index of the candidate with the size of `frame` and the origin closest to
    /// it, or `nil` when none has that size. Origins may differ because the window can
    /// be moving while the candidates are read.
    public static func index(of frame: WindowFrame, among candidates: [WindowFrame]) -> Int? {
        candidates.indices
            .filter { hasSameSize(candidates[$0], frame) }
            .min { first, second in
                candidates[first].origin.distance(to: frame.origin)
                    < candidates[second].origin.distance(to: frame.origin)
            }
    }

    private static func hasSameSize(_ first: WindowFrame, _ second: WindowFrame) -> Bool {
        abs(first.size.width - second.size.width) <= sizeTolerance
            && abs(first.size.height - second.size.height) <= sizeTolerance
    }
}
