import ApplicationServices
import PairwiseCore

/// An element of another app, reached through the Accessibility API (ADR 0031).
protocol AccessibilityElement {
    /// Sets the timeout for calls to this element; call once on an element Pairwise keeps.
    func limitMessagingTime()
    /// The attribute's raw value, and what became of asking.
    func copyAttribute(_ name: String) -> (value: CFTypeRef?, result: AXError)
    /// Sets the attribute, and says what became of it.
    func setAttribute(_ name: String, to value: CFTypeRef) -> AXError
    /// Performs the action, and says what became of it.
    func performAction(_ name: String) -> AXError
    /// The attribute's value when it is a list of elements, or else none.
    func elements(of attribute: String) -> [any AccessibilityElement]
    /// The attribute's value when it is another element.
    func elementAttribute(_ name: String) -> (any AccessibilityElement)?
    /// The names of all attributes this element has.
    var attributeNames: [String] { get }
    /// The process that owns this element, or `nil` when the element has gone.
    var processID: pid_t? { get }
    /// Whether `other` is the same element of the same app.
    func isSame(as other: any AccessibilityElement) -> Bool
}

extension AccessibilityElement {
    /// The attribute's raw value, or `nil` when the element does not give it.
    func attribute(_ name: String) -> CFTypeRef? {
        let (value, result) = copyAttribute(name)
        return result == .success ? value : nil
    }
}

/// The calls to the system that are not about one element (ADR 0031).
@MainActor
protocol SystemAccess {
    /// The element of the app with process `processID`.
    func application(_ processID: pid_t) -> any AccessibilityElement
    /// The window server's descriptions of the windows on screen, frontmost first.
    func onScreenWindows() -> [[String: Any]]
    /// The window server's description of one window, or `nil` when it has gone.
    func windowDescription(_ number: CGWindowID) -> [String: Any]?
    /// All displays in global screen coordinates.
    func displays() -> [WindowFrame]
    /// Where the pointer is now, in global screen coordinates.
    var pointerLocation: ScreenPoint { get }
    /// The identifier of the app of process `processID`, or `nil` when the system does not say.
    func appIdentifier(of processID: pid_t) -> String?
    /// This app's own process.
    var ownProcess: pid_t { get }
}

/// A tap that decides on the left mouse button's events (ADR 0031).
@MainActor
protocol PointerHold: AnyObject {
    /// Installs the tap.
    func start() throws(WindowSystemError)
    /// Removes the tap.
    func stop()
}

/// A coloured area above other windows (ADR 0031).
@MainActor
protocol ScreenMark: AnyObject {
    /// Shows the mark over `frame`, or moves it there.
    func show(at frame: WindowFrame)
    /// Takes the mark off the screen.
    func hide()
}

/// A lock on a seam, above other windows (ADR 0044).
@MainActor
protocol SeamLockMark: AnyObject {
    /// Shows the lock over `frame`, or moves or changes it there.
    func show(at frame: WindowFrame, isClosed: Bool)
    /// Takes the lock off the screen.
    func hide()
}
