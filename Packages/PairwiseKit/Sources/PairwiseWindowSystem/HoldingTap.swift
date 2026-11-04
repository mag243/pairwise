import CoreGraphics
import PairwiseCore
import os

/// An active event tap on the left mouse button, on the main run loop, that can withhold
/// an event (ADR 0024). When this tap fails or is too slow, the system turns it off and
/// input passes.
@MainActor
final class HoldingTap: PointerHold {
    /// The key that joins and parts windows (ADR 0036).
    fileprivate static let joinKey = CGEventFlags.maskCommand
    /// The key that goes to the next place to join, by its place on the keyboard (ADR 0069).
    fileprivate static let choiceKeyCode: Int64 = 6

    private static let logger = Logger(subsystem: "me.m-domain.pairwise", category: "pair-drag")

    fileprivate let decide: @MainActor (PointerButtonEvent) -> Bool
    private var port: CFMachPort?
    private var source: CFRunLoopSource?
    private var choicePort: CFMachPort?
    private var choiceSource: CFRunLoopSource?
    private var isChoiceInputWatched = false

    init(decide: @escaping @MainActor (PointerButtonEvent) -> Bool) {
        self.decide = decide
    }

    /// Installs the tap.
    /// Postcondition: until `stop`, each press, drag and release is decided on, and each
    /// change of a modifier key is reported.
    func start() throws(WindowSystemError) {
        let events =
            CGEventMask(1 << CGEventType.leftMouseDown.rawValue)
            | CGEventMask(1 << CGEventType.leftMouseDragged.rawValue)
            | CGEventMask(1 << CGEventType.leftMouseUp.rawValue)
            | CGEventMask(1 << CGEventType.flagsChanged.rawValue)
        guard
            let port = CGEvent.tapCreate(
                tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
                eventsOfInterest: events, callback: holdingTapCallback,
                userInfo: Unmanaged.passUnretained(self).toOpaque()),
            let source = CFMachPortCreateRunLoopSource(nil, port, 0)
        else {
            throw .eventTapUnavailable
        }
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        self.port = port
        self.source = source
        installChoiceTap()
    }

    /// Installs the tap for choosing a window, off: while it is off, the system gives this app
    /// no typing and no scrolling (ADR 0069). Without it, joining works with the first choice.
    private func installChoiceTap() {
        let events =
            CGEventMask(1 << CGEventType.keyDown.rawValue)
            | CGEventMask(1 << CGEventType.scrollWheel.rawValue)
        guard
            let port = CGEvent.tapCreate(
                tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
                eventsOfInterest: events, callback: holdingTapCallback,
                userInfo: Unmanaged.passUnretained(self).toOpaque()),
            let source = CFMachPortCreateRunLoopSource(nil, port, 0)
        else {
            Self.logger.info("no tap for choosing a window")
            return
        }
        CGEvent.tapEnable(tap: port, enable: false)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        choicePort = port
        choiceSource = source
    }

    /// Turns the tap for choosing a window on or off.
    func setChoiceInputWatched(_ isWatched: Bool) {
        isChoiceInputWatched = isWatched
        if let choicePort { CGEvent.tapEnable(tap: choicePort, enable: isWatched) }
    }

    /// Removes the tap.
    /// Postcondition: the system holds no reference to this object for the callback.
    func stop() {
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let port { CFMachPortInvalidate(port) }
        source = nil
        port = nil
        if let choiceSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), choiceSource, .commonModes)
        }
        if let choicePort { CFMachPortInvalidate(choicePort) }
        choiceSource = nil
        choicePort = nil
    }

    /// Whether the event passes; anything but the three button events always does.
    /// Postcondition: a change of a modifier key is reported and passes, whatever the answer.
    func passes(_ type: CGEventType, at location: CGPoint, flags: CGEventFlags) -> Bool {
        switch type {
        case .leftMouseDown:
            return decide(
                .pressed(ScreenPoint(location), isJoinKeyDown: flags.contains(Self.joinKey)))
        case .leftMouseDragged:
            return decide(
                .dragged(
                    ScreenPoint(location), isJoinKeyDown: flags.contains(Self.joinKey),
                    isEqualHeightKeyDown: flags.contains(.maskShift),
                    isScopeKeyDown: flags.contains(.maskControl)))
        case .leftMouseUp: return decide(.released(ScreenPoint(location)))
        case .flagsChanged:
            _ = decide(
                .keysChanged(
                    isJoinKeyDown: flags.contains(Self.joinKey),
                    isEqualHeightKeyDown: flags.contains(.maskShift),
                    isScopeKeyDown: flags.contains(.maskControl)))
            return true
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            // Turned back on, or the drag would go on with no more moves; these events have passed.
            Self.logger.info("the system turned the tap off: events passed")
            if let port { CGEvent.tapEnable(tap: port, enable: true) }
            if isChoiceInputWatched, let choicePort {
                CGEvent.tapEnable(tap: choicePort, enable: true)
            }
            return true
        default: return true
        }
    }
}

extension HoldingTap {
    /// Whether a key press passes: all but the choice key with the join key down.
    func passesKey(code: Int64, flags: CGEventFlags, isRepeat: Bool) -> Bool {
        guard code == Self.choiceKeyCode, flags.contains(Self.joinKey) else { return true }
        return decide(.joinChoiceKey(isRepeat: isRepeat))
    }

    /// Whether scrolling passes, by the lines of a wheel or the points of a trackpad.
    func passesScroll(lines: Int, points: Double, isContinuous: Bool) -> Bool {
        decide(isContinuous ? .scrolledTrackpad(points: points) : .scrolledWheel(lines: lines))
    }

    /// Whether an event passes, by what was read from it.
    fileprivate func passes(_ type: CGEventType, _ fields: TapEventFields) -> Bool {
        switch type {
        case .keyDown:
            return passesKey(code: fields.keyCode, flags: fields.flags, isRepeat: fields.isRepeat)
        case .scrollWheel:
            return passesScroll(
                lines: fields.lines, points: fields.points, isContinuous: fields.isContinuous)
        default:
            return passes(type, at: fields.location, flags: fields.flags)
        }
    }
}

/// What the tap reads from an event, as the event itself cannot cross to the main actor.
private struct TapEventFields: Sendable {
    let location: CGPoint
    let flags: CGEventFlags
    let keyCode: Int64
    let isRepeat: Bool
    let lines: Int
    let points: Double
    let isContinuous: Bool

    init(_ event: CGEvent) {
        location = event.location
        flags = event.flags
        keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
        lines = Int(event.getIntegerValueField(.scrollWheelEventDeltaAxis1))
        points = event.getDoubleValueField(.scrollWheelEventPointDeltaAxis1)
        isContinuous = event.getIntegerValueField(.scrollWheelEventIsContinuous) != 0
    }
}

/// Runs on the main thread, since the tap's source is on the main run loop.
private func holdingTapCallback(
    proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, info: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let info else { return Unmanaged.passUnretained(event) }
    let tap = Unmanaged<HoldingTap>.fromOpaque(info)
    let fields = TapEventFields(event)
    let passes = MainActor.assumeIsolated {
        tap.takeUnretainedValue().passes(type, fields)
    }
    return passes ? Unmanaged.passUnretained(event) : nil
}
