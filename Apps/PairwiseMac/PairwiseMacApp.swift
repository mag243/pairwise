import AppKit
import PairwiseUI
import PairwiseWindowSystem
import SwiftUI

/// The macOS app: a menu bar item, and a settings window (ADR 0034). A debug build can also
/// test itself on a flag, and quit (ADR 0027, 0050).
@main
struct PairwiseMacApp: App {
    private static let showSettingsFlag = "--show-settings"
    private static let settingsWindow = "settings"

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var pairDrag: PairDragModel

    init() {
        let system = AccessibilityWindowSystem()
        let model = PairDragModel(system: system)
        model.joinScope = MainView.storedJoinScope
        model.playsSounds = MainView.storedPlaysSounds
        _pairDrag = State(initialValue: model)
        guard !Self.isAnimatedCopy else { return }
        Task { await Self.startWorking(model, system) }
    }

    var body: some Scene {
        MenuBarExtra(isInserted: .constant(!Self.isAnimatedCopy)) {
            MenuBarContent(model: pairDrag, settingsWindow: Self.settingsWindow)
        } label: {
            Image("MenuBarIcon")
        }
        Window("Pairwise", id: Self.settingsWindow) {
            #if DEBUG
            if Self.isAnimatedCopy {
                AnimatedTestView()
            } else {
                MainView(model: pairDrag)
            }
            #else
            MainView(model: pairDrag)
            #endif
        }
        .defaultLaunchBehavior(showsWindowAtLaunch ? .presented : .suppressed)
    }

    /// A copy of the app started by the stress test, which shows only an animation.
    private static var isAnimatedCopy: Bool {
        #if DEBUG
        CommandLine.arguments.contains(DragStressTest.animatedWindowFlag)
        #else
        false
        #endif
    }

    /// The window opens by itself when the app is of no use without it.
    private var showsWindowAtLaunch: Bool {
        Self.isAnimatedCopy
            || CommandLine.arguments.contains(Self.showSettingsFlag)
            || !pairDrag.isAccessibilityGranted
            || !pairDrag.isScreenRecordingGranted
    }

    private static func startWorking(
        _ model: PairDragModel, _ system: AccessibilityWindowSystem
    ) async {
        #if DEBUG
        if await runTestIfAsked(model, system) { return }
        #endif
        if model.isAccessibilityGranted, model.isScreenRecordingGranted { model.start() }
    }
}

#if DEBUG

/// The tests and tools a debug build can run on a flag (ADR 0027, 0050).
extension PairwiseMacApp {
    private static let stressTestFlag = "--drag-stress-test"
    private static let joinTestFlag = "--join-test"
    private static let seamTestFlag = "--seam-test"
    private static let seamLookFlag = "--seam-look"
    private static let killTestFlag = "--kill-test"
    private static let killCheckFlag = "--kill-check"
    /// Pairwise works as usual meanwhile, and quits when the recording is finished.
    private static let recordFlag = "--record"
    private static let recordingTime = Duration.seconds(40)

    /// Says whether a flag asked for a test, which has then run, and the app is quitting.
    fileprivate static func runTestIfAsked(
        _ model: PairDragModel, _ system: AccessibilityWindowSystem
    ) async -> Bool {
        let arguments = CommandLine.arguments
        // Test runs join windows of their own, and leave the user's saved pairs alone.
        model.keepsPairs = !arguments.contains { $0.hasPrefix("--") && $0 != recordFlag }
        if let flag = arguments.firstIndex(of: recordFlag), arguments.indices.contains(flag + 1) {
            model.start()
            await ScreenRecording(outputPath: arguments[flag + 1]).record(for: recordingTime)
            model.stop()
            NSApplication.shared.terminate(nil)
            return true
        }
        let flag = arguments.firstIndex {
            [stressTestFlag, joinTestFlag, seamTestFlag, seamLookFlag, killTestFlag, killCheckFlag]
                .contains($0)
        }
        guard let flag, arguments.indices.contains(flag + 1) else { return false }
        // The seam test measures windows alone, with no tap and no pair.
        if arguments[flag] != seamTestFlag { model.start() }
        let test = DragStressTest(
            outputPath: arguments[flag + 1],
            pressOutcome: { model.lastPressOutcome },
            lastLiveFrames: { model.lastDrag?.liveFrames ?? [] },
            join: { first, second in try model.join(first, to: second, on: .left) },
            leave: { model.leavePair(of: $0) })
        if arguments[flag] == joinTestFlag {
            await test.runJoinTest(on: system)
        } else if arguments[flag] == seamTestFlag {
            await test.runSeamTest()
        } else if arguments[flag] == seamLookFlag {
            await test.runSeamLook()
        } else if arguments[flag] == killTestFlag {
            await test.runKillTest()
        } else if arguments[flag] == killCheckFlag {
            await test.runKillCheck(on: system)
        } else {
            await test.run()
        }
        model.stop()
        NSApplication.shared.terminate(nil)
        return true
    }
}

#endif

/// Keeps the app running without windows. SwiftUI would otherwise quit it when the last one
/// closes, which is also the panel at the end of every drag.
private final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
