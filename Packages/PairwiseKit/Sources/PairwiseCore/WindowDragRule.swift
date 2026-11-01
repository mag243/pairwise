/// Tells a window drag from anything else a press on a window can do.
public enum WindowDragRule {
    /// Whether going from `start` to `current` is the window being moved: the origin
    /// has changed and the size has not. A resize at the left or top edge changes both,
    /// and a click changes neither.
    public static func isMove(from start: WindowFrame, to current: WindowFrame) -> Bool {
        current.origin != start.origin && current.size == start.size
    }
}
