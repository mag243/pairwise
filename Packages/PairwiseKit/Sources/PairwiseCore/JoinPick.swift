/// Which of the places to join applies during a drag (ADR 0069): the first choice, or a window
/// the user went to.
public struct JoinPick: Equatable, Sendable {
    private var choices: [JoinPlace?] = []
    /// The window the user went to, for as long as it is a choice.
    private var chosen: UInt32?

    public init() {}

    /// The place that applies, or `nil` when there is none.
    public var place: JoinPlace? {
        choices[safe: currentIndex].flatMap { $0 }
    }

    private var currentIndex: Int {
        choices.firstIndex { $0 != nil && $0?.other.number == chosen } ?? 0
    }

    /// Takes the choices of the moment. A window that was chosen stays chosen, also on another
    /// side and at another place in the order, while it is a choice.
    public mutating func update(to choices: [JoinPlace?]) {
        self.choices = choices
        if !choices.contains(where: { $0 != nil && $0?.other.number == chosen }) { chosen = nil }
    }

    /// Goes `steps` windows on, or back when negative, and starts over past either end. A `nil`
    /// first choice is left behind: going on always gives a window, when there is one.
    public mutating func advance(by steps: Int = 1) {
        let windows = choices.compactMap { $0 }
        guard steps != 0, !windows.isEmpty else { return }
        let hasFirstWindow = choices.first.flatMap { $0 } != nil
        let unchosen = hasFirstWindow || steps < 0 ? 0 : -1
        let position = (windows.firstIndex { $0.other.number == chosen } ?? unchosen) + steps
        let count = windows.count
        chosen = windows[(position % count + count) % count].other.number
    }
}

extension Array {
    fileprivate subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
