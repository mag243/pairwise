import CoreGraphics
import PairwiseCore
import os

/// An active event tap on the left mouse button, on the main run loop, that can withhold
/// an event (ADR 0024). When this tap fails or is too slow, the system turns it off and
/// input passes.
@MainActor
final class HoldingTap: PointerHold {
    /// The key that joins and parts windows (ADR 0036).
    private static let joinKey = CGEventFlags.maskCommand

    private static let logger = Logger(subsystem: "me.m-domain.pairwise", category: "pair-drag")

    private let decide: @MainActor (PointerButtonEvent) -> Bool
    private var port: CFMachPort?
    private var source: CFRunLoopSource?

    init(decide: @escaping @MainActor (PointerButtonEvent) -> Bool) {
        self.decide = decide
    }

    /// Installs the tap.
    /// Postcondition: until `stop`, each press, drag and release is decided on.
    func start() throws(WindowSystemError) {
        let events =
            CGEventMask(1 << CGEventType.leftMouseDown.rawValue)
            | CGEventMask(1 << CGEventType.leftMouseDragged.rawValue)
            | CGEventMask(1 << CGEventType.leftMouseUp.rawValue)
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
    }

    /// Removes the tap.
    /// Postcondition: the system holds no reference to this object for the callback.
    func stop() {
        if let source { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        if let port { CFMachPortInvalidate(port) }
        source = nil
        port = nil
    }

    /// Whether the event passes; anything but the three button events always does.
    func passes(_ type: CGEventType, at location: CGPoint, flags: CGEventFlags) -> Bool {
        switch type {
        case .leftMouseDown:
            return decide(
                .pressed(ScreenPoint(location), isJoinKeyDown: flags.contains(Self.joinKey)))
        case .leftMouseDragged:
            return decide(
                .dragged(
                    ScreenPoint(location), isJoinKeyDown: flags.contains(Self.joinKey),
                    isEqualHeightKeyDown: flags.contains(.maskShift)))
        case .leftMouseUp: return decide(.released(ScreenPoint(location)))
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            // Turned back on, or the drag would go on with no more moves; these events have passed.
            Self.logger.info("the system turned the tap off: events passed")
            if let port { CGEvent.tapEnable(tap: port, enable: true) }
            return true
        default: return true
        }
    }
}

/// Runs on the main thread, since the tap's source is on the main run loop.
private func holdingTapCallback(
    proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, info: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    guard let info else { return Unmanaged.passUnretained(event) }
    let tap = Unmanaged<HoldingTap>.fromOpaque(info)
    let location = event.location
    let flags = event.flags
    let passes = MainActor.assumeIsolated {
        tap.takeUnretainedValue().passes(type, at: location, flags: flags)
    }
    return passes ? Unmanaged.passUnretained(event) : nil
}
