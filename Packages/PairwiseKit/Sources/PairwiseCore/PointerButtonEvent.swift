/// The left mouse button going down, moving while down, or going up, at a place on the
/// screen.
public enum PointerButtonEvent: Equatable, Sendable {
    case pressed(ScreenPoint)
    case dragged(ScreenPoint)
    case released(ScreenPoint)
}
