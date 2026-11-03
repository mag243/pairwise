#if DEBUG

import AppKit
import ApplicationServices
import PairwiseCore

/// Opening the stress test's own windows (ADR 0027).
extension DragStressTest {
    func openWindows() async -> (AccessibilityWindow, AccessibilityWindow)? {
        guard
            let dragged = await openWindow(named: "PairwiseStressA-\(UUID().uuidString.prefix(8))")
        else { return nil }
        guard
            let partner = await openWindow(named: "PairwiseStressB-\(UUID().uuidString.prefix(8))")
        else {
            close(dragged)
            return nil
        }
        for window in [dragged, partner] {
            var size = Self.size
            if let value = AXValueCreate(.cgSize, &size) {
                _ = window.element.setAttribute(kAXSizeAttribute, to: value)
            }
        }
        return (dragged, partner)
    }

    /// Opens a new empty folder in Finder and finds its window as the one that was not
    /// there before; Finder does not always title it after the folder at once.
    func openWindow(named name: String) async -> AccessibilityWindow? {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        guard
            (try? FileManager.default.createDirectory(
                at: folder, withIntermediateDirectories: true)) != nil,
            let finder = NSRunningApplication.runningApplications(
                withBundleIdentifier: "com.apple.finder"
            ).first
        else { return nil }
        folders.append(folder)
        let element = AXUIElementCreateApplication(finder.processIdentifier)
        let before = standardWindows(of: element)
        NSWorkspace.shared.open(folder)
        for _ in 0..<Self.windowLookups {
            await wait(Self.windowWait)
            let new = standardWindows(of: element).filter { window in
                !before.contains { $0.isSame(as: window) }
            }
            // More than one could be a window of the user's, which must not be touched.
            if new.count == 1 { return AccessibilityWindow(element: new[0]) }
            if new.count > 1 { return nil }
        }
        return nil
    }

    func standardWindows(of app: any AccessibilityElement) -> [any AccessibilityElement] {
        app.elements(of: kAXWindowsAttribute).filter {
            $0.attribute(kAXSubroleAttribute) as? String == kAXStandardWindowSubrole
        }
    }

    /// Starts a second copy of this app that shows only an animation (ADR 0029).
    func openAnimatedWindow() async -> (AccessibilityWindow, Process)? {
        guard let path = Bundle.main.executablePath else { return nil }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = [Self.animatedWindowFlag]
        guard (try? process.run()) != nil else { return nil }
        let element = AXUIElementCreateApplication(process.processIdentifier)
        for _ in 0..<Self.windowLookups {
            await wait(Self.windowWait)
            let windows = element.elements(of: kAXWindowsAttribute)
            // A window just opened is not on screen yet, and so has no number.
            if let first = windows.first {
                let window = AccessibilityWindow(element: first)
                if window.windowNumber != nil { return (window, process) }
            }
        }
        process.terminate()
        return nil
    }
}

#endif
