/// A window of any app. Frames are in global screen coordinates with the origin at
/// the top left of the main display, the coordinates pointer locations come in.
@MainActor
public protocol MovableWindow: AnyObject {
    /// The window's current frame, asked of its app.
    func frame() throws(WindowSystemError) -> WindowFrame

    /// Moves the window's top left corner to `origin`.
    func move(to origin: ScreenPoint) throws(WindowSystemError)

    /// Brings the window in front of other windows, without taking focus.
    func raise() throws(WindowSystemError)
}
