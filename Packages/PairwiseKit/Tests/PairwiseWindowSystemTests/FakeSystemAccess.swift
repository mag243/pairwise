import ApplicationServices
import CoreGraphics
import Foundation
import PairwiseCore

@testable import PairwiseWindowSystem

/// An element in memory, with attributes a test sets and a record of what was done.
final class FakeElement: AccessibilityElement {
    var attributes: [String: CFTypeRef] = [:]
    var errors: [String: AXError] = [:]
    var setErrors: [String: AXError] = [:]
    var actionError = AXError.success
    var children: [String: [FakeElement]] = [:]
    var elementAttributes: [String: FakeElement] = [:]
    var processID: pid_t?
    private(set) var sets: [(name: String, value: CFTypeRef)] = []
    private(set) var actions: [String] = []
    private(set) var timeLimits = 0

    init(processID: pid_t? = 1) {
        self.processID = processID
    }

    /// A window element at `frame`.
    static func window(frame: CGRect, processID: pid_t = 1) -> FakeElement {
        let element = FakeElement(processID: processID)
        var origin = frame.origin
        var size = frame.size
        element.attributes[kAXPositionAttribute] = AXValueCreate(.cgPoint, &origin)
        element.attributes[kAXSizeAttribute] = AXValueCreate(.cgSize, &size)
        element.attributes[kAXSubroleAttribute] = kAXStandardWindowSubrole as CFString
        return element
    }

    func limitMessagingTime() {
        timeLimits += 1
    }

    func copyAttribute(_ name: String) -> (value: CFTypeRef?, result: AXError) {
        if let error = errors[name] { return (nil, error) }
        guard let value = attributes[name] else { return (nil, .noValue) }
        return (value, .success)
    }

    func setAttribute(_ name: String, to value: CFTypeRef) -> AXError {
        if let error = setErrors[name] { return error }
        sets.append((name, value))
        attributes[name] = value
        return .success
    }

    func performAction(_ name: String) -> AXError {
        if actionError != .success { return actionError }
        actions.append(name)
        return .success
    }

    func elements(of attribute: String) -> [any AccessibilityElement] {
        children[attribute] ?? []
    }

    func elementAttribute(_ name: String) -> (any AccessibilityElement)? {
        elementAttributes[name]
    }

    func isSame(as other: any AccessibilityElement) -> Bool {
        (other as? FakeElement) === self
    }
}

/// A system in memory.
@MainActor
final class FakeSystemAccess: SystemAccess {
    var apps: [pid_t: FakeElement] = [:]
    var windows: [[String: Any]] = []
    var bundleProcesses: [String: [pid_t]] = [:]
    var runningApps: [PartnerApp] = []
    var displayFrames: [WindowFrame] = []
    var ownProcess: pid_t = 99

    func application(_ processID: pid_t) -> any AccessibilityElement {
        if let app = apps[processID] { return app }
        let app = FakeElement(processID: processID)
        apps[processID] = app
        return app
    }

    func onScreenWindows() -> [[String: Any]] {
        windows
    }

    func windowDescription(_ number: CGWindowID) -> [String: Any]? {
        windows.first { $0[kCGWindowNumber as String] as? CGWindowID == number }
    }

    func processes(bundleIdentifier: String) -> [pid_t] {
        bundleProcesses[bundleIdentifier] ?? []
    }

    func regularApps() -> [PartnerApp] {
        runningApps
    }

    func displays() -> [WindowFrame] {
        displayFrames
    }

    /// The window server's description of a window.
    static func description(
        number: Int, process: Int, frame: CGRect, level: Int = 0
    ) -> [String: Any] {
        [
            kCGWindowBounds as String: frame.dictionaryRepresentation,
            kCGWindowNumber as String: NSNumber(value: number),
            kCGWindowOwnerPID as String: NSNumber(value: process),
            kCGWindowLayer as String: NSNumber(value: level),
        ]
    }
}
