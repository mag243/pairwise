/// The left mouse button going down or up, at a place on the screen.
public enum PointerButtonEvent: Equatable, Sendable {
    case pressed(ScreenPoint)
    case released(ScreenPoint)
}
