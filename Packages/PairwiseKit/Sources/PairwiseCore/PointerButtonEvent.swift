/// The left mouse button going down, moving while down, or going up, at a place on the
/// screen. A press says whether the join key was down, as the event itself knows that; the
/// system's own state of the keys can lag behind it (ADR 0036).
public enum PointerButtonEvent: Equatable, Sendable {
    case pressed(ScreenPoint, isJoinKeyDown: Bool = false)
    case dragged(ScreenPoint)
    case released(ScreenPoint)
}
