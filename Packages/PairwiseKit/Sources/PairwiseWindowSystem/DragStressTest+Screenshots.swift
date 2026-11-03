#if DEBUG

import AppKit
import ApplicationServices
import PairwiseCore

/// The page's pictures (ADR 0065): TextEdit and Preview join, stay a pair and move, and the
/// settings show. Every scene checks what it should show, and the last line of the output file
/// says that all of them did.
extension DragStressTest {
    /// The last line of the output file of a run that made every picture.
    public static let screenshotsDone = "screenshots done"
    private static let textApp = "com.apple.TextEdit"
    private static let pictureApp = "com.apple.Preview"
    private static let textFile = "Travel notes.rtf"
    private static let pictureFile = "Coast.png"
    private static let windowSize = CGSize(width: 620, height: 480)
    private static let topMargin = 50.0
    private static let bottomMargin = 70.0
    private static let settingsPictureWidth = 760.0
    private static let maxPictureWidth = 1800.0
    /// How far the first window starts from its place beside the other, and how far below it.
    private static let joinDistance = 60.0
    private static let joinDrop = 30.0
    /// The gap left in the picture of joining, within the join rule's snap distance of 24 points,
    /// to show that the windows are not joined yet.
    private static let joinGap = 20.0
    /// Far from the title and the document icon, where a press could also drag the file.
    private static let pressPart = 0.8
    private static let dragBy = CGPoint(x: -36, y: 24)
    private static let closeTolerance = 3.0
    private static let appLookups = 100
    private static let settingsWait: UInt64 = 1000

    /// Makes the pictures next to the output file, from the demo files there.
    /// Precondition: taking over drags has been started, on placeholders.
    public func runScreenshots(on system: AccessibilityWindowSystem, settings: NSView) async {
        let start = CGEvent(source: nil)?.location
        lines.append("screenshots started")
        var apps: [NSRunningApplication] = []
        var stage: ScreenshotStage?
        defer {
            pressJoinKey(false)
            system.onlyNormalWindows = nil
            for app in apps { app.terminate() }
            stage?.close()
            if let start { post(.mouseMoved, at: start) }
        }
        do {
            try refuseIfNotReady()
            let made = try ScreenshotStage(
                folder: folder, keptApps: [Self.textApp, Self.pictureApp])
            stage = made
            let area = windowsArea(on: made)
            let text = try await open(Self.textFile, in: Self.textApp, &apps)
            let picture = try await open(Self.pictureFile, in: Self.pictureApp, &apps)
            let numbers = try await place(text, picture, in: area, on: made)
            system.onlyNormalWindows = numbers
            try await joinScene(text, picture, area, made)
            try await pairScene(text, picture, area, made)
            try await dragScene(text, picture, area, made)
            for app in apps { app.terminate() }
            apps = []
            await wait(Self.settingsWait)
            try await settingsScene(settings, made)
            lines.append(Self.screenshotsDone)
        } catch {
            lines.append("failed: \(error)")
        }
    }

    private var folder: URL { URL(fileURLWithPath: outputPath).deletingLastPathComponent() }

    private func refuseIfNotReady() throws {
        guard AXIsProcessTrusted() else {
            throw ScreenshotFailure(description: "the debug build has no Accessibility")
        }
        guard CGPreflightScreenCaptureAccess() else {
            throw ScreenshotFailure(description: "the debug build has no Screen Recording")
        }
        for app in [Self.textApp, Self.pictureApp]
        where !NSRunningApplication.runningApplications(withBundleIdentifier: app).isEmpty {
            throw ScreenshotFailure(
                description: "\(app) is running; quit it, to keep your files out")
        }
    }

    /// The top of the screen, at its whole width unless that is very wide, and then at its right
    /// end, where the strip shows Pairwise's icon.
    private func windowsArea(on stage: ScreenshotStage) -> CGRect {
        let right = stage.bounds.maxX - ScreenshotStage.rightEdgeLeftOut
        let width = min(Self.maxPictureWidth, right)
        let height =
            stage.menuBarHeight + Self.topMargin + Self.windowSize.height + Self.bottomMargin
        return CGRect(x: right - width, y: 0, width: width, height: height)
    }

    /// Opens a demo file in an app that was not running, and finds its one window.
    private func open(
        _ file: String, in bundle: String, _ apps: inout [NSRunningApplication]
    ) async throws -> AccessibilityWindow {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundle) else {
            throw ScreenshotFailure(description: "\(bundle) is not on this Mac")
        }
        let configuration = NSWorkspace.OpenConfiguration()
        // Without this, the app also reopens the documents of its last run.
        configuration.arguments = ["-ApplePersistenceIgnoreState", "YES"]
        let app = try await NSWorkspace.shared.open(
            [folder.appendingPathComponent(file)], withApplicationAt: url,
            configuration: configuration)
        apps.append(app)
        let element = AXUIElementCreateApplication(app.processIdentifier)
        for _ in 0..<Self.appLookups {
            await wait(Self.windowWait)
            let windows = standardWindows(of: element)
            if windows.count == 1 { return AccessibilityWindow(element: windows[0]) }
            if windows.count > 1 {
                throw ScreenshotFailure(description: "\(bundle) opened more than the demo file")
            }
        }
        throw ScreenshotFailure(description: "\(bundle) showed no window")
    }

    /// Sets the first window apart from where it joins, and returns both windows' numbers.
    private func place(
        _ text: AccessibilityWindow, _ picture: AccessibilityWindow, in area: CGRect,
        on stage: ScreenshotStage
    ) async throws -> Set<UInt32> {
        let size = WindowSize(width: Self.windowSize.width, height: Self.windowSize.height)
        try await resize(text, to: size)
        try await resize(picture, to: size)
        await wait(Self.settleWait)
        // An app can keep a window wider than asked, as Preview does.
        guard let textFrame = text.serverFrame(), let pictureFrame = picture.serverFrame() else {
            throw ScreenshotFailure(description: "the demo windows have no frames")
        }
        let top = stage.menuBarHeight + Self.topMargin
        let textWidth = textFrame.size.width
        let pictureX = area.midX - (textWidth + pictureFrame.size.width) / 2 + textWidth
        await place(picture, at: ScreenPoint(x: pictureX, y: top))
        await place(text, at: ScreenPoint(x: pictureX - textWidth - Self.joinDistance, y: top))
        await wait(Self.settleWait)
        lines.append("placed, screen \(stage.bounds), picture area \(area)")
        guard let first = text.windowNumber, let second = picture.windowNumber, first != second
        else { throw ScreenshotFailure(description: "the demo windows have no numbers") }
        try picture.raise()
        try text.raise()
        return [first, second]
    }

    /// An app that has just started can be too busy to answer for a while.
    private func resize(_ window: AccessibilityWindow, to size: WindowSize) async throws {
        for _ in 0..<Self.appLookups {
            do {
                try window.resize(to: size)
                return
            } catch .windowBusy {
                await wait(Self.windowWait)
            }
        }
        throw ScreenshotFailure(description: "a demo window stayed busy")
    }

    private func joinScene(
        _ text: AccessibilityWindow, _ picture: AccessibilityWindow, _ area: CGRect,
        _ stage: ScreenshotStage
    ) async throws {
        var failure: Error?
        await drag(
            text, byX: Self.joinDistance - Self.joinGap, byY: Self.joinDrop, withJoinKey: true,
            picture: nil, pressAt: Self.pressPart
        ) { [self] in
            failure = await capture("join", area, stage, showing: Self.floatingLevel, "the guide")
        }
        if let failure { throw failure }
        guard let left = text.serverFrame(), let right = picture.serverFrame(),
            abs(left.maxX - right.origin.x) <= Self.closeTolerance
        else { throw ScreenshotFailure(description: "the windows did not join side by side") }
    }

    private func pairScene(
        _ text: AccessibilityWindow, _ picture: AccessibilityWindow, _ area: CGRect,
        _ stage: ScreenshotStage
    ) async throws {
        guard let left = text.serverFrame() else {
            throw ScreenshotFailure(description: "TextEdit's window has gone")
        }
        post(
            .mouseMoved,
            at: CGPoint(x: left.maxX + Self.snapGap, y: left.origin.y + left.size.height / 2))
        await wait(Self.guideWait)
        if let failure = await capture("pair", area, stage, showing: Self.lockLevel, "the lock") {
            throw failure
        }
    }

    /// A pair moves as one, and placeholders take no live frames, which the purple icon needs.
    private func dragScene(
        _ text: AccessibilityWindow, _ picture: AccessibilityWindow, _ area: CGRect,
        _ stage: ScreenshotStage
    ) async throws {
        let before = picture.serverFrame()
        var failure: Error?
        await drag(
            text, byX: Self.dragBy.x, byY: Self.dragBy.y, withJoinKey: false, picture: nil,
            pressAt: Self.pressPart
        ) { [self] in
            failure = await capture(
                "drag", area, stage, showing: Self.floatingLevel, "the placeholders")
        }
        if let failure { throw failure }
        await wait(Self.settleWait)
        guard let before, let after = picture.serverFrame(),
            abs(after.origin.x - before.origin.x - Self.dragBy.x) <= Self.closeTolerance
        else { throw ScreenshotFailure(description: "the pair did not move together") }
        guard lastLiveFrameCounts.allSatisfy({ $0 == 0 }) else {
            throw ScreenshotFailure(description: "the drag took live frames")
        }
    }

    private func settingsScene(_ view: NSView, _ stage: ScreenshotStage) async throws {
        let size = view.fittingSize
        let height = stage.menuBarHeight + Self.topMargin + size.height + Self.bottomMargin
        let right = stage.bounds.maxX - ScreenshotStage.rightEdgeLeftOut
        let width = min(Self.settingsPictureWidth, right)
        let area = CGRect(x: right - width, y: 0, width: width, height: height)
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.title = "Pairwise"
        window.contentView = view
        window.setFrameTopLeftPoint(
            NSPoint(
                x: area.midX - size.width / 2,
                y: stage.bounds.height - stage.menuBarHeight - Self.topMargin))
        window.makeKeyAndOrderFront(nil)
        defer { window.close() }
        await wait(Self.settingsWait)
        await activate(window, in: stage)
        lines.append(try await stage.capture("settings", area: area))
    }

    /// A click makes this app active, which a menu bar app cannot ask for itself when nothing
    /// gives way, and an inactive window has grey buttons. The pointer stays in the title bar.
    private func activate(_ window: NSWindow, in stage: ScreenshotStage) async {
        let frame = window.frame
        let titleBar = CGPoint(
            x: frame.midX, y: stage.bounds.height - frame.maxY + Self.titleBandY)
        post(.mouseMoved, at: titleBar)
        await wait(Self.windowWait)
        post(.leftMouseDown, at: titleBar)
        post(.leftMouseUp, at: titleBar)
        await wait(Self.settingsWait)
    }

    /// Takes a picture when this app shows something at `level`, and says why otherwise.
    private func capture(
        _ name: String, _ area: CGRect, _ stage: ScreenshotStage, showing level: Int, _ what: String
    ) async -> Error? {
        guard !ownMarks(atLevel: level).isEmpty else {
            return ScreenshotFailure(description: "\(name): \(what) did not show")
        }
        do {
            lines.append(try await stage.capture(name, area: area))
            return nil
        } catch {
            return error
        }
    }
}

#endif
