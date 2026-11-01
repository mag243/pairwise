/// A window of any app. Frames are in global screen coordinates with the origin at
/// the top left of the main display, the coordinates pointer locations come in.
@MainActor
public protocol MovableWindow: AnyObject {
    /// The window's current frame, asked of its app.
    func frame() throws(WindowSystemError) -> WindowFrame

    /// The window's current frame as the window server has it, without asking its app, or
    /// `nil` when the window server does not tell.
    func serverFrame() -> WindowFrame?

    /// Moves the window's top left corner to `origin`.
    func move(to origin: ScreenPoint) throws(WindowSystemError)

    /// Brings the window in front of other windows, without taking focus.
    func raise() throws(WindowSystemError)
}
