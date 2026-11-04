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

    var attributeNames: [String] { Array(attributes.keys) }

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
    var displayFrames: [WindowFrame] = []
    var ownProcess: pid_t = 99
    var pointerLocation = ScreenPoint(x: 0, y: 0)
    var appIdentifiers: [pid_t: String] = [:]

    func appIdentifier(of processID: pid_t) -> String? {
        appIdentifiers[processID]
    }

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

/// A hold in memory, which touches no input.
@MainActor
final class FakeHold: PointerHold {
    var startError: WindowSystemError?
    private(set) var starts = 0
    private(set) var stops = 0
    private(set) var isChoiceInputWatched = false

    func start() throws(WindowSystemError) {
        if let startError { throw startError }
        starts += 1
    }

    func stop() {
        stops += 1
    }

    func setChoiceInputWatched(_ isWatched: Bool) {
        isChoiceInputWatched = isWatched
    }
}

/// A mark in memory, which shows nothing.
@MainActor
final class FakeMark: ScreenMark {
    private(set) var frames: [WindowFrame] = []
    private(set) var isHidden = false

    func show(at frame: WindowFrame) {
        frames.append(frame)
    }

    func hide() {
        isHidden = true
    }
}
