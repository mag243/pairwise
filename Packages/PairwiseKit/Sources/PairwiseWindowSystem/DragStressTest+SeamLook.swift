import AppKit
import ImageIO
import PairwiseCore
import ScreenCaptureKit

/// Pictures of a resize at the seam, to look at what it shows (ADR 0048). It joins two windows
/// of its own, with files in them, and saves what the screen shows around those two only.
extension DragStressTest {
    private static let lookWidth = 700.0
    private static let lookHeight = 500.0
    private static let lookOrigin = ScreenPoint(x: 100, y: 120)
    private static let lookMargin = 40.0
    private static let lookPressDown = 60.0
    private static let lookSteps = 40
    private static let lookFiles = 40
    private static let picturesAfterRelease = 6

    /// Runs the drags, and saves the pictures next to the output file.
    public func runSeamLook() async {
        let start = CGEvent(source: nil)?.location
        lines.append("seam look started")
        defer {
            if let start { post(.mouseMoved, at: start) }
            for folder in folders { try? FileManager.default.removeItem(at: folder) }
        }
        guard let (left, right) = await openWindows() else {
            lines.append("could not open the test windows")
            return
        }
        fillFolders()
        let size = WindowSize(width: Self.lookWidth, height: Self.lookHeight)
        try? left.resize(to: size)
        try? right.resize(to: size)
        await place(left, at: Self.lookOrigin)
        let rightOrigin = ScreenPoint(x: Self.lookOrigin.x + Self.lookWidth, y: Self.lookOrigin.y)
        await place(right, at: rightOrigin)
        await wait(Self.settleWait)
        guard joined(left, right) else { return }
        await look(named: "a-before")
        await dragSeam(of: right, by: -150, named: "b-right-widens")
        await dragSeam(of: right, by: 300, named: "c-left-widens")
        await dragSeam(of: right, by: 400, named: "d-past-the-limit")
        report("after", left, right)
        close(left)
        close(right)
        lines.append("seam look ended")
    }

    private func fillFolders() {
        for folder in folders {
            for index in 0..<Self.lookFiles {
                let file = folder.appendingPathComponent("A file with a long name \(index).txt")
                try? Data().write(to: file)
            }
        }
    }

    /// Drags the left edge of `window`: a picture halfway, one at the end still holding, and a
    /// series right after the release.
    private func dragSeam(
        of window: AccessibilityWindow, by distance: Double, named name: String
    ) async {
        guard let frame = window.serverFrame() else { return }
        var point = CGPoint(x: frame.origin.x + 1, y: frame.origin.y + Self.lookPressDown)
        post(.mouseMoved, at: point)
        await wait(Self.windowWait)
        post(.leftMouseDown, at: point)
        await wait(Self.windowWait)
        for step in 1...Self.lookSteps {
            point.x += distance / Double(Self.lookSteps)
            post(.leftMouseDragged, at: point)
            await wait(Self.stepWait)
            if step == Self.lookSteps / 2 { await look(named: "\(name)-1-halfway") }
        }
        await wait(Self.windowWait)
        await look(named: "\(name)-2-end")
        lines.append("\(name), still held: window \(String(describing: window.serverFrame()))")
        post(.leftMouseUp, at: point)
        for index in 0..<Self.picturesAfterRelease {
            await look(named: "\(name)-3-released-\(index)")
        }
        await wait(Self.settleWait)
        await look(named: "\(name)-4-settled")
        lines.append("\(name), settled: window \(String(describing: window.serverFrame()))")
    }

    /// Saves what the screen shows around the two windows' place.
    private func look(named name: String) async {
        guard
            let content = try? await SCShareableContent.excludingDesktopWindows(
                false, onScreenWindowsOnly: true),
            let display = content.displays.first(where: { $0.displayID == CGMainDisplayID() })
        else { return }
        let area = CGRect(
            x: Self.lookOrigin.x - Self.lookMargin, y: Self.lookOrigin.y - Self.lookMargin,
            width: 2 * (Self.lookWidth + Self.lookMargin),
            height: Self.lookHeight + 2 * Self.lookMargin
        ).intersection(CGRect(x: 0, y: 0, width: display.width, height: display.height))
        let configuration = SCStreamConfiguration()
        configuration.sourceRect = area
        configuration.width = Int(area.width)
        configuration.height = Int(area.height)
        configuration.showsCursor = true
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let before = ProcessInfo.processInfo.systemUptime
        guard
            let image = try? await SCScreenshotManager.captureImage(
                contentFilter: filter, configuration: configuration),
            let destination = CGImageDestinationCreateWithURL(
                URL(fileURLWithPath: "\(outputPath)-\(name).png") as CFURL,
                "public.png" as CFString, 1, nil)
        else { return }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
        let elapsed = Int((ProcessInfo.processInfo.systemUptime - before) * 1000)
        lines.append("picture \(name), took \(elapsed) ms")
    }
}
