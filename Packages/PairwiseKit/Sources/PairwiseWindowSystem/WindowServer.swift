import CoreGraphics
import Foundation
import PairwiseCore

/// What the window server says about windows: places and numbers, without asking their
/// apps and without a permission (ADR 0018).
enum WindowServer {
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
