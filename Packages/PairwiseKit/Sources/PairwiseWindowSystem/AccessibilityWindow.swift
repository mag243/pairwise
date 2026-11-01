import ApplicationServices
import PairwiseCore

/// Another app's window, reached through the Accessibility API. Every call goes to that
/// app and waits for its answer, up to the messaging timeout.
@MainActor
final class AccessibilityWindow: MovableWindow {
    private static let enhancedInterfaceAttribute = "AXEnhancedUserInterface"

    let element: AXUIElement
    /// The window server's number for this window, found on first use (ADR 0018).
    private var serverWindowNumber: CGWindowID?
    private var hasLookedUpWindowNumber = false

    /// Precondition: `element` is a window.
    init(element: AXUIElement) {
        self.element = element
        element.limitMessagingTime()
    }

    /// Precondition: `element` is the window the window server numbers `serverWindowNumber`.
    init(element: AXUIElement, serverWindowNumber: CGWindowID) {
        self.element = element
        self.serverWindowNumber = serverWindowNumber
        hasLookedUpWindowNumber = true
        element.limitMessagingTime()
    }

    func frame() throws(WindowSystemError) -> WindowFrame {
        let origin = try read(kAXPositionAttribute, as: .cgPoint, initial: CGPoint.zero)
        let size = try read(kAXSizeAttribute, as: .cgSize, initial: CGSize.zero)
        return WindowFrame(origin: origin, size: size)
    }

    func serverFrame() -> WindowFrame? {
        if !hasLookedUpWindowNumber {
            hasLookedUpWindowNumber = true
            if let processID = element.processID, let frame = try? frame() {
                serverWindowNumber = WindowServer.windowNumber(
                    ofProcess: processID, matching: frame)
            }
        }
        return serverWindowNumber.flatMap(WindowServer.frame(ofWindow:))
    }

    func move(to origin: ScreenPoint) throws(WindowSystemError) {
        let restoreAnimation = turnOffMoveAnimation()
        defer { restoreAnimation() }
        var point = origin.cgPoint
        guard let value = AXValueCreate(.cgPoint, &point) else { throw .windowRefused }
        let result = AXUIElementSetAttributeValue(
            element, kAXPositionAttribute as CFString, value)
        guard result == .success else { throw WindowSystemError(result) }
    }

    /// An app with this attribute on animates a move, and a parked window would fly across
    /// the screen (ADR 0030). Returns what puts the attribute back.
    private func turnOffMoveAnimation() -> () -> Void {
        guard let processID = element.processID else { return {} }
        let app = AXUIElementCreateApplication(processID)
        app.limitMessagingTime()
        let name = Self.enhancedInterfaceAttribute as CFString
        guard app.attribute(Self.enhancedInterfaceAttribute) as? Bool == true else { return {} }
        AXUIElementSetAttributeValue(app, name, kCFBooleanFalse)
        return { AXUIElementSetAttributeValue(app, name, kCFBooleanTrue) }
    }

    func raise() throws(WindowSystemError) {
        let result = AXUIElementPerformAction(element, kAXRaiseAction as CFString)
        guard result == .success else { throw WindowSystemError(result) }
    }

    private func read<Value: BitwiseCopyable>(
        _ attribute: String, as type: AXValueType, initial: Value
    ) throws(WindowSystemError) -> Value {
        var raw: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute as CFString, &raw)
        guard result == .success else { throw WindowSystemError(result) }
        guard let raw, CFGetTypeID(raw) == AXValueGetTypeID() else { throw .windowRefused }
        var value = initial
        guard AXValueGetValue(unsafeDowncast(raw, to: AXValue.self), type, &value) else {
            throw .windowRefused
        }
        return value
    }
}
