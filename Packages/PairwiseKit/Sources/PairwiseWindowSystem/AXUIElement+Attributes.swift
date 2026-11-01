import ApplicationServices

extension AXUIElement {
    /// How long a call to this element's app may take, in seconds. An app that hangs
    /// must not hold up Pairwise for longer, since the calls run on the main thread.
    private static let messagingTimeout: Float = 0.1

    /// Sets the timeout for calls to this element; call once on an element Pairwise keeps.
    func limitMessagingTime() {
        AXUIElementSetMessagingTimeout(self, Self.messagingTimeout)
    }

    /// The attribute's raw value, or `nil` when the element does not give it.
    func attribute(_ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(self, name as CFString, &value) == .success else {
            return nil
        }
        return value
    }

    /// The attribute's value when it is another element.
    func elementAttribute(_ name: String) -> AXUIElement? {
        guard let value = attribute(name), CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }
        return unsafeDowncast(value, to: AXUIElement.self)
    }

    /// The process that owns this element, or `nil` when the element has gone.
    var processID: pid_t? {
        var pid: pid_t = 0
        guard AXUIElementGetPid(self, &pid) == .success else { return nil }
        return pid
    }
}
