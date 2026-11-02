import AppKit
import PairwiseCore

/// Resizing at a seam with posted events on two windows of its own: a pair's step of the join
/// test, and a measurement of how well a window can follow, with no pair and no tap (ADR 0045).
extension DragStressTest {
    private static let seamLeftOrigin = ScreenPoint(x: 100, y: 120)
    /// Wide enough for both windows to shrink: Finder refuses to go narrow.
    private static let seamWidth = 800.0
    /// How far inside the held window the press lands, on its resize edge.
    private static let edgeInset = 1.0
    /// How far down the seam the press lands, away from its middle.
    private static let pressDown = 60.0
    private static let seamDragSteps = 100
    /// Points per step, with `stepWait` between steps: about a slow and a fast hand.
    private static let seamStepSizes = [1.0, 3.0]
    private static let seamLookWait: UInt64 = 8
    /// Wide enough for both windows to shrink: Finder refuses to go narrower than 520.
    private static let seamTestWidth = 700.0
    /// How far down the seam a press lands, away from the lock.
    private static let seamPressDown = 60.0

    /// Runs the measurements and writes them to the file.
    public func runSeamTest() async {
        let start = CGEvent(source: nil)?.location
        lines.append("seam test started")
        defer {
            if let start { post(.mouseMoved, at: start) }
            for folder in folders { try? FileManager.default.removeItem(at: folder) }
        }
        guard let (left, right) = await openWindows() else {
            lines.append("could not open the test windows")
            return
        }
        await placeForSeam(left, right)
        guard let first = left.windowNumber, let second = right.windowNumber, first != second
        else {
            lines.append("the test windows have no numbers of their own: nothing was tested")
            close(left)
            close(right)
            return
        }
        for step in Self.seamStepSizes {
            await measureSeam(holding: left, following: right, isHeldLeft: true, step: step)
            await measureSeam(holding: left, following: right, isHeldLeft: true, step: -step)
            await measureSeam(holding: right, following: left, isHeldLeft: false, step: step)
            await measureSeam(holding: right, following: left, isHeldLeft: false, step: -step)
        }
        close(left)
        close(right)
        lines.append("seam test ended")
    }

    private func placeForSeam(_ left: AccessibilityWindow, _ right: AccessibilityWindow) async {
        let size = WindowSize(width: Self.seamWidth, height: Double(Self.size.height))
        try? left.resize(to: size)
        try? right.resize(to: size)
        await place(left, at: Self.seamLeftOrigin)
        let rightX = Self.seamLeftOrigin.x + Self.seamWidth
        await place(right, at: ScreenPoint(x: rightX, y: Self.seamLeftOrigin.y))
        await wait(Self.settleWait)
    }

    /// Expects a pair with the first window on the right, wide enough to resize both ways.
    func resizeAtTheSeam(_ window: AccessibilityWindow, _ other: AccessibilityWindow) async {
        let size = WindowSize(width: Self.seamTestWidth, height: Self.otherHeight)
        try? other.resize(to: size)
        try? window.resize(to: size)
        await place(other, at: Self.leftOrigin)
        await place(
            window, at: ScreenPoint(x: Self.leftOrigin.x + size.width, y: Self.leftOrigin.y))
        await wait(Self.settleWait)
        report("set up for the seam", window, other)
        await dragSeam(of: window, partner: other, by: -100)
        lines.append("expect the seam moved by -100, far edges where they were")
        report("resized at the seam", window, other)
        await dragSeam(of: window, partner: other, by: -300)
        lines.append("expect the other at Finder's minimum of 520 during the drag, seam shared")
        report("resized to the other's minimum", window, other)
        await dragSeam(of: other, partner: window, atRightEdge: true, by: 500)
        lines.append(
            "expect the first at Finder's minimum of 520 during the drag, far edge at 1500")
        report("resized to the minimum on the right", window, other)
    }

    /// Drags an edge of `window`, away from the lock in the middle of the seam.
    private func dragSeam(
        of window: AccessibilityWindow, partner: AccessibilityWindow, atRightEdge: Bool = false,
        by distance: Double
    ) async {
        guard let frame = window.serverFrame() else { return }
        try? window.raise()
        await wait(Self.settleWait)
        let x = atRightEdge ? frame.maxX - 1 : frame.origin.x + 1
        var point = CGPoint(x: x, y: frame.origin.y + Self.seamPressDown)
        post(.mouseMoved, at: point)
        await wait(Self.windowWait)
        post(.leftMouseDown, at: point)
        await wait(Self.windowWait)
        for _ in 0..<Self.joinSteps {
            point.x += distance / Double(Self.joinSteps)
            post(.leftMouseDragged, at: point)
            await wait(Self.stepWait)
        }
        await wait(Self.windowWait)
        lines.append("press: \(pressOutcome())")
        report("during the drag, still held", window, partner)
        post(.leftMouseUp, at: point)
        await wait(Self.settleWait)
    }

    private func measureSeam(
        holding held: AccessibilityWindow, following partner: AccessibilityWindow,
        isHeldLeft: Bool, step: Double
    ) async {
        let (left, right) = isHeldLeft ? (held, partner) : (partner, held)
        await placeForSeam(left, right)
        try? held.raise()
        await wait(Self.settleWait)
        guard let frame = held.serverFrame() else { return }
        var point = CGPoint(
            x: isHeldLeft ? frame.maxX - Self.edgeInset : frame.origin.x + Self.edgeInset,
            y: frame.origin.y + Self.pressDown)
        let follower = SeamFollower(held: held, partner: partner, isHeldLeft: isHeldLeft)
        let ticker = DisplayTicker { follower.look() }
        post(.mouseMoved, at: point)
        await wait(Self.windowWait)
        post(.leftMouseDown, at: point)
        await wait(Self.windowWait)
        for _ in 0..<Self.seamDragSteps {
            point.x += step
            post(.leftMouseDragged, at: point)
            await wait(Self.seamLookWait)
        }
        post(.leftMouseUp, at: point)
        await wait(Self.settleWait)
        ticker?.stop()
        let side = isHeldLeft ? "left window held" : "right window held"
        lines.append("\(side), \(step) points a step: \(follower.summary())")
    }
}

/// Keeps a partner against the seam of a window being resized, and writes down how far behind
/// it is. Places come from the window server, as they say what is on the screen.
@MainActor
private final class SeamFollower {
    private static let millisecondsPerSecond = 1000.0

    private let held: AccessibilityWindow
    private let partner: AccessibilityWindow
    private let isHeldLeft: Bool
    private var last: WindowFrame?
    private var changes = 0
    private var callTime = 0.0
    private var longestCall = 0.0
    private var gapTotal = 0.0
    private var widestGap = 0.0
    private var gapSamples = 0

    init(held: AccessibilityWindow, partner: AccessibilityWindow, isHeldLeft: Bool) {
        self.held = held
        self.partner = partner
        self.isHeldLeft = isHeldLeft
    }

    /// One display frame: notes the gap on the screen, and follows when the seam has moved.
    func look() {
        guard let now = held.serverFrame(), let other = partner.serverFrame() else { return }
        let gap = abs(seamGap(now, other))
        guard let previous = last else {
            last = now
            return
        }
        guard now != previous || gap > 0 else { return }
        gapTotal += gap
        gapSamples += 1
        widestGap = max(widestGap, gap)
        last = now
        guard gap > 0 else { return }
        changes += 1
        let before = ProcessInfo.processInfo.systemUptime
        follow(now, other)
        let elapsed = ProcessInfo.processInfo.systemUptime - before
        callTime += elapsed
        longestCall = max(longestCall, elapsed)
    }

    private func seamGap(_ held: WindowFrame, _ other: WindowFrame) -> Double {
        isHeldLeft ? other.origin.x - held.maxX : held.origin.x - other.maxX
    }

    private func follow(_ held: WindowFrame, _ other: WindowFrame) {
        if isHeldLeft {
            let width = other.maxX - held.maxX
            try? partner.move(to: ScreenPoint(x: held.maxX, y: other.origin.y))
            try? partner.resize(to: WindowSize(width: width, height: other.size.height))
        } else {
            let width = held.origin.x - other.origin.x
            try? partner.resize(to: WindowSize(width: width, height: other.size.height))
        }
    }

    func summary() -> String {
        let width = last.map { "\(Int($0.size.width))" } ?? "?"
        let partnerWidth = partner.serverFrame().map { "\(Int($0.size.width))" } ?? "?"
        let mean = changes == 0 ? 0 : callTime / Double(changes) * Self.millisecondsPerSecond
        let longest = longestCall * Self.millisecondsPerSecond
        let meanGap = gapSamples == 0 ? 0 : gapTotal / Double(gapSamples)
        let gapNow = (held.serverFrame()).flatMap { now in
            partner.serverFrame().map { seamGap(now, $0) }
        }
        return """
            held width \(width), partner \(partnerWidth), \(changes) follows, mean call \(rounded(mean)) ms, \
            longest \(rounded(longest)) ms; gap mean \(rounded(meanGap)), widest \
            \(rounded(widestGap)), at the end \(gapNow.map(rounded) ?? "?") points
            """
    }

    private func rounded(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}
