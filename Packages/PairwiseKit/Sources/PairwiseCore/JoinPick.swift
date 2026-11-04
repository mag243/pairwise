/// Which of the places to join is chosen during a drag (ADR 0069).
/// Invariant: `step` lies within `choices`, or is 0 without choices.
public struct JoinPick: Equatable, Sendable {
    private var choices: [JoinPlace?] = []
    private var step = 0

    public init() {}

    /// The place chosen, or `nil` for no window or without choices.
    public var place: JoinPlace? {
        choices.isEmpty ? nil : choices[step]
    }

    /// Takes the choices of the moment. A window that was chosen stays chosen while it is a
    /// choice, also on another side; otherwise the first choice applies again.
    public mutating func update(to choices: [JoinPlace?]) {
        let chosen = step == 0 ? nil : place?.other.number
        self.choices = choices
        step = choices.firstIndex { $0?.other.number == chosen && chosen != nil } ?? 0
    }

    /// Goes `steps` choices on, or back when negative, starting over past either end.
    public mutating func advance(by steps: Int = 1) {
        guard !choices.isEmpty else { return }
        let count = choices.count
        step = ((step + steps) % count + count) % count
    }
}
