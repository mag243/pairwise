import AppKit
import ImageIO
import PairwiseCore
import ScreenCaptureKit

/// Joining and parting two windows of its own with posted events (ADR 0027, 0035).
extension DragStressTest {
    private static let joinKey: CGKeyCode = 55
    static let joinSteps = 50
    private static let joinKeyStep = 10
    private static let guideWait: UInt64 = 300
    private static let floatingLevel = 3
    /// The level of the lock on a seam, which tells it from the guide.
    private static let lockLevel = 8
    /// How far below the other's top the first window goes before the lock joins them.
    private static let lockTopOffset = 30.0
    private static let pictureMargin = 60.0
    static let otherHeight = 500.0
    static let leftOrigin = ScreenPoint(x: 100, y: 120)
    private static let otherOrigin = ScreenPoint(x: 900, y: 120)
    /// How far from the other window's edge the drag stops, within the snap distance.
    private static let snapGap = 10.0

    /// Runs through joining and parting, and writes what happened to the file.
    /// Precondition: taking over drags has been started.
    public func runJoinTest(on system: AccessibilityWindowSystem) async {
        let start = CGEvent(source: nil)?.location
        lines.append("join test started")
        defer {
            pressJoinKey(false)
            system.onlyNormalWindows = nil
            if let start { post(.mouseMoved, at: start) }
            for folder in folders { try? FileManager.default.removeItem(at: folder) }
        }
        guard let (window, other) = await openWindows() else {
            lines.append("could not open the test windows")
            return
        }
        try? other.resize(to: WindowSize(width: Double(Self.size.width), height: Self.otherHeight))
        await place(window, at: Self.leftOrigin)
        await place(other, at: Self.otherOrigin)
        await wait(Self.settleWait)
        report("set up", window, other)
        lines.append("a window's attributes: \(window.element.attributeNames.sorted())")
        // Asked only now: just after opening, the window server may not know a window's size
        // yet, and a window's number is found by its size.
        guard let first = window.windowNumber, let second = other.windowNumber, first != second
        else {
            lines.append("the test windows have no numbers of their own: nothing was tested")
            close(window)
            close(other)
            return
        }
        system.onlyNormalWindows = [first, second]
        await joinFromTheLeft(window, other)
        await dragTogether(window, other)
        await part(window, other)
        await joinFromTheRight(window, other)
        await partWithTheLock(window, other)
        await resizeAtTheSeam(window, other)
        close(window)
        close(other)
        lines.append("join test ended")
    }

    private func joinFromTheLeft(_ window: AccessibilityWindow, _ other: AccessibilityWindow) async
    {
        let distance =
            Self.otherOrigin.x - Double(Self.size.width) + Self.snapGap - Self.leftOrigin.x
        await drag(window, byX: distance, byY: 30, withJoinKey: true, picture: "left")
        lines.append("expect the window at x 380, y 120, height 340, tight against the other")
        report("joined on the left", window, other)
    }

    private func dragTogether(_ window: AccessibilityWindow, _ other: AccessibilityWindow) async {
        await drag(window, byX: -100, byY: 60, withJoinKey: false, picture: nil)
        lines.append("expect both moved by -100, 60: x 280 and x 800, y 180")
        report("dragged together", window, other)
    }

    private func part(_ window: AccessibilityWindow, _ other: AccessibilityWindow) async {
        await drag(window, byX: -150, byY: 0, withJoinKey: true, picture: nil)
        report("parted: only the first moved, by -150", window, other)
        await drag(window, byX: -20, byY: 0, withJoinKey: false, picture: nil)
        report("a plain drag after parting: only the first moved, by -20", window, other)
    }

    private func joinFromTheRight(_ window: AccessibilityWindow, _ other: AccessibilityWindow) async
    {
        // Far enough left that the window's title bar stays on the screen beside the other.
        await place(other, at: Self.leftOrigin)
        await wait(Self.settleWait)
        guard let otherFrame = other.serverFrame() else { return }
        await place(window, at: ScreenPoint(x: otherFrame.maxX + 200, y: otherFrame.origin.y))
        await wait(Self.settleWait)
        await drag(window, byX: -(200 - Self.snapGap), byY: 20, withJoinKey: true, picture: "right")
        lines.append("expect the first against the other's right edge, with its own height")
        report("joined on the right", window, other)
        await drag(other, byX: -60, byY: 0, withJoinKey: false, picture: nil)
        report("dragged by the left window: both moved by -60", window, other)
        await drag(window, byX: 40, byY: 0, withJoinKey: false, picture: nil)
        report("dragged by the right window: both moved by 40", window, other)
        await drag(window, byX: 200, byY: 0, withJoinKey: true, picture: nil)
        report("parted during the drag: only the first moved, by 200", window, other)
        guard let frame = other.serverFrame(), let first = window.serverFrame() else { return }
        isEqualHeightKeyDown = true
        await drag(
            window, byX: frame.maxX + Self.snapGap - first.origin.x, byY: 20, withJoinKey: true,
            picture: "height")
        isEqualHeightKeyDown = false
        lines.append("expect the first with the other's height, 500")
        report("joined with Shift", window, other)
    }

    /// Expects the first window on the right, as the steps before leave it.
    private func partWithTheLock(_ window: AccessibilityWindow, _ other: AccessibilityWindow) async
    {
        guard let place = window.serverFrame()?.origin else { return }
        await clickLock(between: window, other, label: "closed")
        report("parted with the lock", window, other)
        await drag(window, byX: 30, byY: 0, withJoinKey: false, picture: nil)
        report("a plain drag after the lock: only the first moved, by 30", window, other)
        await self.place(window, at: ScreenPoint(x: place.x, y: place.y + Self.lockTopOffset))
        await wait(Self.settleWait)
        await clickLock(between: window, other, label: "open")
        lines.append("expect the windows' tops level, tight against each other")
        report("joined with the lock", window, other)
        await drag(window, byX: 30, byY: 0, withJoinKey: false, picture: nil)
        report("dragged after the lock: both moved by 30", window, other)
    }

    /// Clicks the lock in the middle of the seam, with the first window on the right.
    private func clickLock(
        between window: AccessibilityWindow, _ other: AccessibilityWindow, label: String
    ) async {
        guard let first = window.serverFrame(), let second = other.serverFrame() else { return }
        let top = max(first.origin.y, second.origin.y)
        let bottom = min(first.maxY, second.maxY)
        let middle = CGPoint(x: first.origin.x, y: (top + bottom) / 2)
        post(.mouseMoved, at: CGPoint(x: middle.x + Self.snapGap, y: middle.y))
        await wait(Self.guideWait)
        lines.append("near the seam, \(label): lock \(ownMarks(atLevel: Self.lockLevel))")
        post(.mouseMoved, at: middle)
        await wait(Self.windowWait)
        post(.leftMouseDown, at: middle)
        await wait(Self.windowWait)
        post(.leftMouseUp, at: middle)
        await wait(Self.settleWait)
        lines.append("press: \(pressOutcome()); lock now \(ownMarks(atLevel: Self.lockLevel))")
    }

    private func drag(
        _ window: AccessibilityWindow, byX: Double, byY: Double, withJoinKey: Bool, picture: String?
    ) async {
        guard let frame = window.serverFrame() else {
            lines.append("the window has no frame")
            return
        }
        try? window.raise()
        await wait(Self.settleWait)
        var point = CGPoint(
            x: frame.origin.x + frame.size.width / 2, y: frame.origin.y + Self.titleBandY)
        guard isOwnWindowOnTop(window, at: point) else {
            lines.append("drag skipped, another window is on top at the press")
            return
        }
        post(.mouseMoved, at: point)
        await wait(Self.windowWait)
        post(.leftMouseDown, at: point)
        await wait(Self.windowWait)
        for step in 0..<Self.joinSteps {
            // The key comes during the drag, as it does by hand (ADR 0039).
            if withJoinKey, step == Self.joinKeyStep {
                pressJoinKey(true)
                await wait(Self.windowWait)
            }
            point.x += byX / Double(Self.joinSteps)
            point.y += byY / Double(Self.joinSteps)
            post(.leftMouseDragged, at: point)
            await wait(Self.stepWait)
        }
        await wait(Self.guideWait)
        lines.append("press: \(pressOutcome()); guide: \(guideFrames())")
        if let picture { await savePicture(named: picture, around: window) }
        post(.leftMouseUp, at: point)
        if withJoinKey { pressJoinKey(false) }
        await wait(Self.settleWait)
    }

    private func pressJoinKey(_ isDown: Bool) {
        guard isJoinKeyDown != isDown else { return }
        isJoinKeyDown = isDown
        let source = CGEventSource(stateID: .hidSystemState)
        let event = CGEvent(
            keyboardEventSource: source, virtualKey: Self.joinKey, keyDown: isDown)
        event?.flags = isDown ? .maskCommand : []
        event?.post(tap: .cghidEventTap)
    }

    /// What this app shows above normal windows: the guide, if any.
    private func guideFrames() -> [String] {
        ownMarks(atLevel: Self.floatingLevel)
    }

    private func ownMarks(atLevel level: Int) -> [String] {
        LiveSystemAccess().onScreenWindows()
            .filter { description in
                description[kCGWindowOwnerPID as String] as? pid_t
                    == ProcessInfo.processInfo.processIdentifier
                    && description[kCGWindowLayer as String] as? Int == level
            }
            .compactMap(WindowServer.frame(from:))
            .map(Self.text(of:))
    }

    func report(
        _ label: String, _ window: AccessibilityWindow, _ other: AccessibilityWindow
    ) {
        let first = window.serverFrame().map(Self.text(of:)) ?? "gone"
        let second = other.serverFrame().map(Self.text(of:)) ?? "gone"
        lines.append("\(label): first \(first), other \(second)")
    }

    private static func text(of frame: WindowFrame) -> String {
        "x \(Int(frame.origin.x)), y \(Int(frame.origin.y)), "
            + "\(Int(frame.size.width)) by \(Int(frame.size.height))"
    }

    /// Saves the screen around the window next to the output file, to look at what the guide
    /// and macOS show at this moment. The rest of the screen stays out of the picture.
    private func savePicture(named name: String, around window: AccessibilityWindow) async {
        guard
            let frame = window.serverFrame(),
            let content = try? await SCShareableContent.excludingDesktopWindows(
                false, onScreenWindowsOnly: true),
            let display = content.displays.first
        else { return }
        let configuration = SCStreamConfiguration()
        let margin = Self.pictureMargin
        let area = CGRect(
            x: frame.origin.x - margin, y: frame.origin.y - margin,
            width: frame.size.width + Double(Self.size.width) + 2 * margin,
            height: Self.otherHeight + 2 * margin
        ).intersection(CGRect(x: 0, y: 0, width: display.width, height: display.height))
        configuration.sourceRect = area
        configuration.width = Int(area.width)
        configuration.height = Int(area.height)
        configuration.showsCursor = true
        let filter = SCContentFilter(display: display, excludingWindows: [])
        guard
            let image = try? await SCScreenshotManager.captureImage(
                contentFilter: filter, configuration: configuration),
            let destination = CGImageDestinationCreateWithURL(
                URL(fileURLWithPath: "\(outputPath)-\(name).png") as CFURL,
                "public.png" as CFString, 1, nil)
        else { return }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
    }
}
