import ApplicationServices
import PairwiseCore

/// Another app's window, reached through the Accessibility API. Every call goes to that
/// app and waits for its answer, up to the messaging timeout.
@MainActor
final class AccessibilityWindow: MovableWindow {
    private static let enhancedInterfaceAttribute = "AXEnhancedUserInterface"
    private static let fullScreenAttribute = "AXFullScreen"

    let element: any AccessibilityElement
    private let access: any SystemAccess
    /// The window server's number for this window, found on first use (ADR 0018).
    private var serverWindowNumber: CGWindowID?
    private var hasLookedUpWindowNumber = false

    /// Precondition: `element` is a window.
    init(element: any AccessibilityElement, access: any SystemAccess = LiveSystemAccess()) {
        self.element = element
        self.access = access
        element.limitMessagingTime()
    }

    /// Precondition: `element` is the window the window server numbers `serverWindowNumber`.
    init(
        element: any AccessibilityElement, serverWindowNumber: CGWindowID,
        access: any SystemAccess = LiveSystemAccess()
    ) {
        self.element = element
        self.access = access
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
                    ofProcess: processID, matching: frame, in: access.onScreenWindows())
            }
        }
        return
            serverWindowNumber
            .flatMap(access.windowDescription)
            .flatMap(WindowServer.frame(from:))
    }

    func move(to origin: ScreenPoint) throws(WindowSystemError) {
        let restoreAnimation = turnOffMoveAnimation()
        defer { restoreAnimation() }
        var point = origin.cgPoint
        guard let value = AXValueCreate(.cgPoint, &point) else { throw .windowRefused }
        let result = element.setAttribute(kAXPositionAttribute, to: value)
        guard result == .success else { throw WindowSystemError(result) }
    }

    func resize(to size: WindowSize) throws(WindowSystemError) {
        let restoreAnimation = turnOffMoveAnimation()
        defer { restoreAnimation() }
        var cgSize = CGSize(width: size.width, height: size.height)
        guard let value = AXValueCreate(.cgSize, &cgSize) else { throw .windowRefused }
        let result = element.setAttribute(kAXSizeAttribute, to: value)
        guard result == .success else { throw WindowSystemError(result) }
    }

    /// An app with this attribute on animates a move, and a parked window would fly across
    /// the screen (ADR 0030). Returns what puts the attribute back.
    private func turnOffMoveAnimation() -> () -> Void {
        guard let processID = element.processID else { return {} }
        let app = access.application(processID)
        app.limitMessagingTime()
        let name = Self.enhancedInterfaceAttribute
        guard app.attribute(name) as? Bool == true else { return {} }
        _ = app.setAttribute(name, to: kCFBooleanFalse)
        return { _ = app.setAttribute(name, to: kCFBooleanTrue) }
    }

    var windowNumber: UInt32? {
        _ = serverFrame()
        return serverWindowNumber
    }

    var isAvailable: Bool {
        guard (try? frame()) != nil else { return false }
        return element.attribute(kAXMinimizedAttribute) as? Bool != true
            && element.attribute(Self.fullScreenAttribute) as? Bool != true
    }

    func raise() throws(WindowSystemError) {
        let result = element.performAction(kAXRaiseAction)
        guard result == .success else { throw WindowSystemError(result) }
    }

    private func read<Value: BitwiseCopyable>(
        _ attribute: String, as type: AXValueType, initial: Value
    ) throws(WindowSystemError) -> Value {
        let (raw, result) = element.copyAttribute(attribute)
        guard result == .success else { throw WindowSystemError(result) }
        guard let raw, CFGetTypeID(raw) == AXValueGetTypeID() else { throw .windowRefused }
        var value = initial
        guard AXValueGetValue(unsafeDowncast(raw, to: AXValue.self), type, &value) else {
            throw .windowRefused
        }
        return value
    }
}
