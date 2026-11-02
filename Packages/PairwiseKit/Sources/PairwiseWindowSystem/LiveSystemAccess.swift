import AppKit
import ApplicationServices
import PairwiseCore

/// The real system. Each call only forwards, so the logic stays elsewhere and testable.
struct LiveSystemAccess: SystemAccess {
    func application(_ processID: pid_t) -> any AccessibilityElement {
        AXUIElementCreateApplication(processID)
    }

    func onScreenWindows() -> [[String: Any]] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        return CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] ?? []
    }

    func windowDescription(_ number: CGWindowID) -> [String: Any]? {
        let list = CGWindowListCopyWindowInfo(.optionIncludingWindow, number) as? [[String: Any]]
        return list?.first
    }

    func displays() -> [WindowFrame] {
        NSScreen.globalFrames(of: NSScreen.screens.map(\.frame))
    }

    var pointerLocation: ScreenPoint {
        ScreenPoint(CGEvent(source: nil)?.location ?? .zero)
    }

    var ownProcess: pid_t { ProcessInfo.processInfo.processIdentifier }
}
