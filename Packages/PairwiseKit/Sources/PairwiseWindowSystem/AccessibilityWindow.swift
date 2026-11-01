import ApplicationServices
import PairwiseCore

/// Another app's window, reached through the Accessibility API. Every call goes to that
/// app and waits for its answer, up to the messaging timeout.
@MainActor
final class AccessibilityWindow: MovableWindow {
    let element: AXUIElement

    /// Precondition: `element` is a window.
    init(element: AXUIElement) {
        self.element = element
        element.limitMessagingTime()
    }

    func frame() throws(WindowSystemError) -> WindowFrame {
        let origin = try read(kAXPositionAttribute, as: .cgPoint, initial: CGPoint.zero)
        let size = try read(kAXSizeAttribute, as: .cgSize, initial: CGSize.zero)
        return WindowFrame(origin: origin, size: size)
    }

    func move(to origin: ScreenPoint) throws(WindowSystemError) {
        var point = origin.cgPoint
        guard let value = AXValueCreate(.cgPoint, &point) else { throw .windowRefused }
        let result = AXUIElementSetAttributeValue(
            element, kAXPositionAttribute as CFString, value)
        guard result == .success else { throw WindowSystemError(result) }
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
