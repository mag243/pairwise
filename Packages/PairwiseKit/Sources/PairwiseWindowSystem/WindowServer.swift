import CoreGraphics
import Foundation
import PairwiseCore

/// What the window server says about windows: places and numbers, without asking their
/// apps and without a permission (ADR 0018).
enum WindowServer {
    /// The level of normal windows, below menus, the Dock and floating panels.
    private static let normalWindowLevel = 0

    /// A window on screen, as the window server describes it.
    struct OnScreenWindow: Equatable {
        let number: CGWindowID
        let processID: pid_t
        let frame: WindowFrame
    }

    /// The window on top at `point`, or `nil` when that is no window of another app at the
    /// normal level: a window of `ownProcess`, a menu, or nothing.
    static func topWindow(at point: ScreenPoint, excludingProcess ownProcess: pid_t)
        -> OnScreenWindow?
    {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]]
        return topWindow(at: point, excludingProcess: ownProcess, in: list ?? [])
    }

    /// As above, from `descriptions` in the window server's order: frontmost first.
    static func topWindow(
        at point: ScreenPoint, excludingProcess ownProcess: pid_t, in descriptions: [[String: Any]]
    ) -> OnScreenWindow? {
        let top = descriptions.first { frame(from: $0)?.contains(point) == true }
        guard
            let top, let frame = frame(from: top),
            top[kCGWindowLayer as String] as? Int == normalWindowLevel,
            let number = top[kCGWindowNumber as String] as? CGWindowID,
            let processID = top[kCGWindowOwnerPID as String] as? pid_t,
            processID != ownProcess
        else { return nil }
        return OnScreenWindow(number: number, processID: processID, frame: frame)
    }

    /// The number of the on-screen window of `processID` that matches `frame`.
    static func windowNumber(ofProcess processID: pid_t, matching frame: WindowFrame) -> CGWindowID?
    {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard
            let list = CGWindowListCopyWindowInfo(options, kCGNullWindowID)
                as? [[String: Any]]
        else { return nil }
        let windows = list.filter { $0[kCGWindowOwnerPID as String] as? pid_t == processID }
        let frames = windows.map {
            Self.frame(from: $0) ?? WindowFrame(x: 0, y: 0, width: 0, height: 0)
        }
        return WindowMatch.index(of: frame, among: frames).flatMap {
            windows[$0][kCGWindowNumber as String] as? CGWindowID
        }
    }

    /// The window's frame now, or `nil` when it has gone.
    static func frame(ofWindow number: CGWindowID) -> WindowFrame? {
        let list = CGWindowListCopyWindowInfo(.optionIncludingWindow, number) as? [[String: Any]]
        return list?.first.flatMap(frame(from:))
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
