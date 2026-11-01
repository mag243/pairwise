import CoreGraphics
import PairwiseCore

/// A listen-only event tap on the left mouse button, on the main run loop. Being
/// listen-only, it cannot hold up or change input, whatever happens in here.
@MainActor
final class PointerTap {
    private let handler: @MainActor (PointerButtonEvent) -> Void
    private var port: CFMachPort?
    private var source: CFRunLoopSource?

    init(handler: @escaping @MainActor (PointerButtonEvent) -> Void) {
        self.handler = handler
    }

    /// Installs the tap.
    /// Postcondition: until `stop`, each press and release reaches the handler.
    func start() throws(WindowSystemError) {
        let events =
            CGEventMask(1 << CGEventType.leftMouseDown.rawValue)
            | CGEventMask(1 << CGEventType.leftMouseUp.rawValue)
        guard
            let port = CGEvent.tapCreate(
                tap: .cgSessionEventTap, place: .tailAppendEventTap, options: .listenOnly,
                eventsOfInterest: events, callback: pointerTapCallback,
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

    fileprivate func receive(_ type: CGEventType, at location: CGPoint) {
        switch type {
        case .leftMouseDown: handler(.pressed(ScreenPoint(location)))
        case .leftMouseUp: handler(.released(ScreenPoint(location)))
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            // The system turns off a tap it finds slow; without this the release is lost.
            if let port { CGEvent.tapEnable(tap: port, enable: true) }
        default: break
        }
    }
}

/// Runs on the main thread, since the tap's source is on the main run loop.
private func pointerTapCallback(
    proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, info: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if let info {
        let tap = Unmanaged<PointerTap>.fromOpaque(info)
        let location = event.location
        MainActor.assumeIsolated {
            tap.takeUnretainedValue().receive(type, at: location)
        }
    }
    return Unmanaged.passUnretained(event)
}
