import AppKit
import ApplicationServices
import PairwiseCore

/// Drags a window of its own again and again with real mouse events, and writes down
/// whether its partner went along (ADR 0027). It moves only the two Finder windows it
/// opens itself on empty folders of its own.
@MainActor
public final class DragStressTest {
    /// Given to a copy of the app, which then shows only an animation.
    public static let animatedWindowFlag = "--animated-window"
    private static let tries = 40
    private static let liveTries = 5
    private static let longDragSteps = 250
    private static let longDragDrift = 0.5
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
    private let lastLiveFrames: () -> [Int]
    private var lines: [String] = []

    /// `pressOutcome` says what became of the last press, and `lastLiveFrames` how many
    /// live frames per window the last drag got.
    public init(
        system: AccessibilityWindowSystem, outputPath: String,
        pressOutcome: @escaping () -> String, lastLiveFrames: @escaping () -> [Int]
    ) {
        self.system = system
        self.outputPath = outputPath
        self.pressOutcome = pressOutcome
        self.lastLiveFrames = lastLiveFrames
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
        await liveTries(dragged: dragged)
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

    /// Drags beside a helper window that animates, for long enough to count live frames.
    private func liveTries(dragged: AccessibilityWindow) async {
        guard let (helper, process) = await openAnimatedWindow() else {
            lines.append("could not open the animated window")
            return
        }
        defer { process.terminate() }
        system.pinnedPartner = helper
        for index in 0..<Self.liveTries {
            await place(dragged, at: Self.origin)
            await place(helper, at: ScreenPoint(x: Self.partnerX, y: Self.origin.y))
            try? helper.raise()
            try? dragged.raise()
            await wait(Self.settleWait)
            await longDrag()
            await wait(Self.settleWait)
            lines.append("live try \(index): frames per window \(lastLiveFrames())")
        }
        system.pinnedPartner = nil
    }

    private func longDrag() async {
        let press = CGPoint(
            x: Self.origin.x + Double(Self.size.width) / 2, y: Self.origin.y + Self.titleBandY)
        post(.mouseMoved, at: press)
        post(.leftMouseDown, at: press)
        var point = press
        for step in 0..<Self.longDragSteps {
            point.x += step % 2 == 0 ? Self.dragStep : -Self.dragStep
            point.y += Self.longDragDrift
            post(.leftMouseDragged, at: point)
            await wait(Self.stepWait)
        }
        post(.leftMouseUp, at: point)
    }

    /// Starts a second copy of this app that shows only an animation (ADR 0029).
    private func openAnimatedWindow() async -> (AccessibilityWindow, Process)? {
        guard let path = Bundle.main.executablePath else { return nil }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = [Self.animatedWindowFlag]
        guard (try? process.run()) != nil else { return nil }
        let element = AXUIElementCreateApplication(process.processIdentifier)
        for _ in 0..<Self.windowLookups {
            await wait(Self.windowWait)
            let windows = element.attribute(kAXWindowsAttribute) as? [AXUIElement] ?? []
            if let first = windows.first { return (AccessibilityWindow(element: first), process) }
        }
        process.terminate()
        return nil
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
