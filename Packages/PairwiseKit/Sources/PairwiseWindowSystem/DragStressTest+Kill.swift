#if DEBUG

import AppKit
import PairwiseCore

/// Kills the app during a drag, with two windows of its own parked, and has a second run check
/// that they came back (ADR 0053). The first run says where they belong in a file of its own,
/// as the record that matters is removed by the second run's start.
extension DragStressTest {
    private static let killOrigin = ScreenPoint(x: 120, y: 120)
    private static let killPartnerX = 700.0
    private static let killPressX = 300.0
    private static let killSteps = 40
    private static let killStep = 4.0
    private static let parkedWait: UInt64 = 800
    private static let frameTolerance = 3.0

    private var windowsPath: String { outputPath + ".windows" }
    private var foldersPath: String { outputPath + ".folders" }

    /// Starts a drag of a pair, and kills the app with the windows parked.
    /// Precondition: taking over drags has been started.
    public func runKillTest() async {
        lines.append("kill test started")
        guard let (window, partner) = await openWindows() else {
            lines.append("could not open the test windows")
            return
        }
        await place(window, at: Self.killOrigin)
        await place(partner, at: ScreenPoint(x: Self.killPartnerX, y: Self.killOrigin.y))
        await wait(Self.settleWait)
        guard
            let first = window.serverFrame(), let second = partner.serverFrame(),
            let firstNumber = window.windowNumber, let secondNumber = partner.windowNumber,
            joined(window, partner)
        else {
            lines.append("could not set up the pair")
            return
        }
        try? window.raise()
        await wait(Self.settleWait)
        saveExpected([
            ParkedWindow(number: firstNumber, owner: 0, frame: first),
            ParkedWindow(number: secondNumber, owner: 0, frame: second),
        ])
        await dragUntilParked(window)
        lines.append("before the kill: first \(String(describing: window.serverFrame()))")
        lines.append("before the kill: other \(String(describing: partner.serverFrame()))")
        // Released in the same breath: nothing should run between this and the kill.
        var point = CGPoint(
            x: first.origin.x + Self.killPressX, y: first.origin.y + Self.titleBandY)
        point.x += Double(Self.killSteps) * Self.killStep
        post(.leftMouseUp, at: point)
        kill(getpid(), SIGKILL)
    }

    private func dragUntilParked(_ window: AccessibilityWindow) async {
        guard let frame = window.serverFrame() else { return }
        var point = CGPoint(
            x: frame.origin.x + Self.killPressX, y: frame.origin.y + Self.titleBandY)
        post(.mouseMoved, at: point)
        await wait(Self.windowWait)
        post(.leftMouseDown, at: point)
        await wait(Self.windowWait)
        for _ in 0..<Self.killSteps {
            point.x += Self.killStep
            post(.leftMouseDragged, at: point)
            await wait(Self.stepWait)
        }
        await wait(Self.parkedWait)
    }

    private func saveExpected(_ windows: [ParkedWindow]) {
        let record = ParkingRecord(savedAt: 0, windows: windows)
        try? record.encoded()?.write(to: URL(fileURLWithPath: windowsPath))
        let paths = folders.map(\.path).joined(separator: "\n")
        try? paths.write(toFile: foldersPath, atomically: true, encoding: .utf8)
    }

    /// Checks the windows of the first run, which this run's start should have put back, and
    /// closes them.
    /// Precondition: taking over drags has been started.
    public func runKillCheck(on system: AccessibilityWindowSystem) async {
        lines.append("kill check started")
        await wait(Self.settleWait)
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: windowsPath)),
            let expected = ParkingRecord(data: data)
        else {
            lines.append("nothing from the first run")
            return
        }
        lines.append("record left: \(system.loadParkingRecord() != nil)")
        var allBack = true
        for item in expected.windows {
            guard let window = system.window(number: item.number) as? AccessibilityWindow else {
                allBack = false
                lines.append("window \(item.number) is gone")
                continue
            }
            allBack = check(window, against: item) && allBack
            close(window)
        }
        lines.append(allBack ? "kill check passed" : "kill check FAILED")
        removeFirstRunsFiles()
    }

    private func check(_ window: AccessibilityWindow, against item: ParkedWindow) -> Bool {
        guard let frame = window.serverFrame() else { return false }
        let isBack =
            frame.origin.distance(to: item.frame.origin) <= Self.frameTolerance
            && abs(frame.size.width - item.frame.size.width) <= Self.frameTolerance
            && abs(frame.size.height - item.frame.size.height) <= Self.frameTolerance
        lines.append("window \(item.number): expected \(item.frame), is \(frame): back \(isBack)")
        return isBack
    }

    private func removeFirstRunsFiles() {
        let text = (try? String(contentsOfFile: foldersPath, encoding: .utf8)) ?? ""
        for path in text.split(separator: "\n") {
            try? FileManager.default.removeItem(atPath: String(path))
        }
        try? FileManager.default.removeItem(atPath: windowsPath)
        try? FileManager.default.removeItem(atPath: foldersPath)
    }
}

#endif
