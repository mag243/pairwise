import CoreGraphics
import Foundation
import PairwiseCore

/// What the window server says about windows: places and numbers, without asking their
/// apps and without a permission (ADR 0018).
enum WindowServer {
    /// The level of normal windows. Above it are menus and the Dock, but also windows that
    /// cannot be seen and cover the whole screen, so being on top there says nothing.
    private static let normalWindowLevel = 0

    /// A window on screen, as the window server describes it.
    struct OnScreenWindow: Equatable {
        let number: CGWindowID
        let processID: pid_t
        let frame: WindowFrame
    }

    /// The frontmost normal window at `point` in `descriptions`, which are in the window
    /// server's order, or `nil` when there is none or it is a window of `ownProcess`.
    static func topWindow(
        at point: ScreenPoint, excludingProcess ownProcess: pid_t, in descriptions: [[String: Any]]
    ) -> OnScreenWindow? {
        let top = descriptions.first { description in
            description[kCGWindowLayer as String] as? Int == normalWindowLevel
                && frame(from: description)?.contains(point) == true
        }
        guard
            let top, let frame = frame(from: top),
            let number = top[kCGWindowNumber as String] as? CGWindowID,
            let processID = top[kCGWindowOwnerPID as String] as? pid_t,
            processID != ownProcess
        else { return nil }
        return OnScreenWindow(number: number, processID: processID, frame: frame)
    }

    /// The normal windows in `descriptions` of other processes than `ownProcess`.
    static func normalWindows(
        excludingProcess ownProcess: pid_t, in descriptions: [[String: Any]]
    ) -> [OnScreenWindow] {
        descriptions.compactMap { description in
            guard
                description[kCGWindowLayer as String] as? Int == normalWindowLevel,
                let frame = frame(from: description),
                let number = description[kCGWindowNumber as String] as? CGWindowID,
                let processID = description[kCGWindowOwnerPID as String] as? pid_t,
                processID != ownProcess
            else { return nil }
            return OnScreenWindow(number: number, processID: processID, frame: frame)
        }
    }

    /// The window in a description of one window from the window server.
    static func window(from description: [String: Any]) -> OnScreenWindow? {
        guard
            let frame = frame(from: description),
            let number = description[kCGWindowNumber as String] as? CGWindowID,
            let processID = description[kCGWindowOwnerPID as String] as? pid_t
        else { return nil }
        return OnScreenWindow(number: number, processID: processID, frame: frame)
    }

    /// The number of the window of `processID` in `descriptions` that matches `frame`.
    static func windowNumber(
        ofProcess processID: pid_t, matching frame: WindowFrame, in descriptions: [[String: Any]]
    ) -> CGWindowID? {
        let windows = descriptions.filter { $0[kCGWindowOwnerPID as String] as? pid_t == processID }
        let frames = windows.map {
            Self.frame(from: $0) ?? WindowFrame(x: 0, y: 0, width: 0, height: 0)
        }
        return WindowMatch.index(of: frame, among: frames).flatMap {
            windows[$0][kCGWindowNumber as String] as? CGWindowID
        }
    }

    /// The frame in a window's description from the window server.
    static func frame(from description: [String: Any]) -> WindowFrame? {
        guard
            let bounds = description[kCGWindowBounds as String] as? NSDictionary,
            let rect = CGRect(dictionaryRepresentation: bounds)
        else { return nil }
        return WindowFrame(origin: rect.origin, size: rect.size)
    }
}
