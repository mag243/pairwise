import ApplicationServices

extension AXUIElement: AccessibilityElement {
    /// How long a call to this element's app may take, in seconds. An app that hangs
    /// must not hold up Pairwise for longer, since the calls run on the main thread.
    private static let messagingTimeout: Float = 0.1

    var attributeNames: [String] {
        var names: CFArray?
        guard AXUIElementCopyAttributeNames(self, &names) == .success else { return [] }
        return names as? [String] ?? []
    }

    func limitMessagingTime() {
        AXUIElementSetMessagingTimeout(self, Self.messagingTimeout)
    }

    func copyAttribute(_ name: String) -> (value: CFTypeRef?, result: AXError) {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(self, name as CFString, &value)
        return (value, result)
    }

    func setAttribute(_ name: String, to value: CFTypeRef) -> AXError {
        AXUIElementSetAttributeValue(self, name as CFString, value)
    }

    func performAction(_ name: String) -> AXError {
        AXUIElementPerformAction(self, name as CFString)
    }

    func elements(of attribute: String) -> [any AccessibilityElement] {
        self.attribute(attribute) as? [AXUIElement] ?? []
    }

    func elementAttribute(_ name: String) -> (any AccessibilityElement)? {
        guard let value = attribute(name), CFGetTypeID(value) == AXUIElementGetTypeID() else {
            return nil
        }
        return unsafeDowncast(value, to: AXUIElement.self)
    }

    var processID: pid_t? {
        var pid: pid_t = 0
        guard AXUIElementGetPid(self, &pid) == .success else { return nil }
        return pid
    }

    func isSame(as other: any AccessibilityElement) -> Bool {
        CFEqual(self, other as AnyObject)
    }
}
