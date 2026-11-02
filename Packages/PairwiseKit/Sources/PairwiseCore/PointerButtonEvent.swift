/// The left mouse button going down, moving while down, or going up, at a place on the
/// screen. A press and a drag say whether the join key is down, as the event itself knows that;
/// the system's own state of the keys can lag behind it (ADR 0036, 0039).
public enum PointerButtonEvent: Equatable, Sendable {
    case pressed(ScreenPoint, isJoinKeyDown: Bool = false)
    case dragged(ScreenPoint, isJoinKeyDown: Bool = false)
    case released(ScreenPoint)
}
