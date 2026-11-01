import AppKit
import ApplicationServices
import PairwiseCore

/// Drags a window of its own again and again with real mouse events, and writes down
/// whether its partner went along (ADR 0027). It moves only the two Finder windows it
/// opens itself on empty folders of its own.
@MainActor
public final class DragStressTest {
    private static let tries = 40
    private static let origin = ScreenPoint(x: 120, y: 120)
    private static let size = CGSize(width: 520, height: 340)
    private static let partnerX = 700.0
    private static let titleBandY = 12.0
    private static let sideMargin = 140.0
    private static let dragSteps = 12
    private static let dragStep = 6.0
    private static let tolerance = 3.0
    /// Waits in milliseconds, tried in turn: from arriving at a place to the press, and
    /// from the press to the first drag event.
    private static let waitsBeforePress: [UInt64] = [0, 5, 20, 100, 300]
    private static let waitsAfterPress: [UInt64] = [0, 2, 10, 30, 80]
    private static let stepWait: UInt64 = 4
    private static let settleWait: UInt64 = 300
    private static let windowWait: UInt64 = 100
    private static let windowLookups = 50

    private let system: AccessibilityWindowSystem
    private let outputPath: String
    private let pressOutcome: () -> String
    private var lines: [String] = []

    /// `pressOutcome` says what became of the last press.
    public init(
        system: AccessibilityWindowSystem, outputPath: String,
        pressOutcome: @escaping () -> String
    ) {
        self.system = system
        self.outputPath = outputPath
        self.pressOutcome = pressOutcome
    }

    /// Runs all tries and writes the file; a failure to set up is written there too.
    /// Precondition: taking over drags has been started.
    public func run() async {
        let start = CGEvent(source: nil)?.location
        defer {
            if let start { post(.mouseMoved, at: start) }
            write()
        }
        guard let (dragged, partner) = await openWindows() else {
            lines.append("could not open the test windows")
            return
        }
        system.pinnedPartner = partner
        var counts: [String: Int] = [:]
        for index in 0..<Self.tries {
            let result = await oneTry(index, dragged: dragged, partner: partner)
            counts[result, default: 0] += 1
        }
        system.pinnedPartner = nil
        lines.append("summary: \(counts.sorted { $0.key < $1.key })")
        close(dragged)
        close(partner)
    }

    private func oneTry(
        _ index: Int, dragged: AccessibilityWindow, partner: AccessibilityWindow
    ) async -> String {
        await place(dragged, at: Self.origin)
        await place(partner, at: ScreenPoint(x: Self.partnerX, y: Self.origin.y))
        try? dragged.raise()
        await wait(Self.settleWait)
        let width = Double(Self.size.width) - 2 * Self.sideMargin
        let x = Self.origin.x + Self.sideMargin + Double.random(in: 0...width)
        let press = CGPoint(x: x, y: Self.origin.y + Self.titleBandY)
        let before = Self.waitsBeforePress[index % Self.waitsBeforePress.count]
        let after = Self.waitsAfterPress[
            (index / Self.waitsBeforePress.count) % Self.waitsAfterPress.count]
        post(.mouseMoved, at: press)
        await wait(before)
        post(.leftMouseDown, at: press)
        await wait(after)
        var point = press
        for _ in 0..<Self.dragSteps {
            point.x += Self.dragStep
            point.y += Self.dragStep
            post(.leftMouseDragged, at: point)
            await wait(Self.stepWait)
        }
        post(.leftMouseUp, at: point)
        await wait(Self.settleWait)
        let result = classify(dragged: dragged, partner: partner)
        lines.append(
            "try \(index): before \(before) ms, after \(after) ms: \(result); "
                + "press: \(pressOutcome())")
        return result
    }

    private func classify(dragged: AccessibilityWindow, partner: AccessibilityWindow) -> String {
        let moved = Double(Self.dragSteps) * Self.dragStep
        let expected = ScreenPoint(x: Self.origin.x + moved, y: Self.origin.y + moved)
        guard let window = dragged.serverFrame(), let other = partner.serverFrame() else {
            return "windows gone"
        }
        let windowMoved = window.origin.distance(to: Self.origin) > Self.tolerance
        let partnerBeside =
            other.origin.distance(to: ScreenPoint(x: window.maxX, y: window.origin.y))
            <= Self.tolerance
        let exact = window.origin.distance(to: expected) <= Self.tolerance
        switch (windowMoved, partnerBeside) {
        case (true, true): return exact ? "both moved" : "both moved, not to the place"
        case (true, false): return "only the held window moved"
        case (false, true): return "partner moved, held window not"
        case (false, false): return "nothing moved"
        }
    }

    private func openWindows() async -> (AccessibilityWindow, AccessibilityWindow)? {
        guard
            let dragged = await openWindow(named: "PairwiseStressA-\(UUID().uuidString.prefix(8))"),
            let partner = await openWindow(named: "PairwiseStressB-\(UUID().uuidString.prefix(8))")
        else { return nil }
        for window in [dragged, partner] {
            var size = Self.size
            if let value = AXValueCreate(.cgSize, &size) {
                AXUIElementSetAttributeValue(window.element, kAXSizeAttribute as CFString, value)
            }
        }
        return (dragged, partner)
    }

    /// Opens a new empty folder in Finder and finds its window by its title.
    private func openWindow(named name: String) async -> AccessibilityWindow? {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        guard
            (try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true))
                != nil
        else { return nil }
        NSWorkspace.shared.open(folder)
        for _ in 0..<Self.windowLookups {
            await wait(Self.windowWait)
            let apps = NSRunningApplication.runningApplications(
                withBundleIdentifier: "com.apple.finder")
            guard let app = apps.first else { continue }
            let element = AXUIElementCreateApplication(app.processIdentifier)
            let windows = element.attribute(kAXWindowsAttribute) as? [AXUIElement] ?? []
            if let found = windows.first(where: {
                $0.attribute(kAXTitleAttribute) as? String == name
            }) {
                return AccessibilityWindow(element: found)
            }
        }
        return nil
    }

    private func place(_ window: AccessibilityWindow, at origin: ScreenPoint) async {
        try? window.move(to: origin)
        await wait(Self.windowWait)
    }

    private func close(_ window: AccessibilityWindow) {
        if let button = window.element.elementAttribute(kAXCloseButtonAttribute) {
            AXUIElementPerformAction(button, kAXPressAction as CFString)
        }
    }

    private func post(_ type: CGEventType, at point: CGPoint) {
        let source = CGEventSource(stateID: .hidSystemState)
        CGEvent(
            mouseEventSource: source, mouseType: type, mouseCursorPosition: point,
            mouseButton: .left
        )?.post(tap: .cghidEventTap)
    }

    private func wait(_ milliseconds: UInt64) async {
        try? await Task.sleep(for: .milliseconds(milliseconds))
    }

    private func write() {
        let text = lines.joined(separator: "\n") + "\n"
        try? text.write(toFile: outputPath, atomically: true, encoding: .utf8)
    }
}
