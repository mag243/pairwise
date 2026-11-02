import AppKit
import PairwiseCore
import PairwiseUI
import PairwiseWindowSystem
import SwiftUI

/// The macOS app: a menu bar item, and a settings window (ADR 0034). A debug build can also
/// test itself on a flag, and quit (ADR 0027, 0050).
@main
struct PairwiseMacApp: App {
    private static let showSettingsFlag = "--show-settings"
    private static let settingsWindow = "settings"
    private static let permissionLookInterval = Duration.seconds(2)

    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var pairDrag: PairDragModel
    @State private var updater = Updater()

    init() {
        let system = AccessibilityWindowSystem()
        let model = PairDragModel(system: system)
        model.joinScope = MainView.storedJoinScope
        model.playsSounds = MainView.storedPlaysSounds
        model.liveFramesPerSecond = MainView.storedDragPictures.framesPerSecond
        _pairDrag = State(initialValue: model)
        guard !Self.isAnimatedCopy else { return }
        Task { await Self.startWorking(model, system) }
    }

    var body: some Scene {
        MenuBarExtra(isInserted: .constant(!Self.isAnimatedCopy)) {
            MenuBarContent(model: pairDrag, updater: updater, settingsWindow: Self.settingsWindow)
        } label: {
            Image("MenuBarIcon")
        }
        Window("Pairwise", id: Self.settingsWindow) {
            #if DEBUG
            if Self.isAnimatedCopy {
                AnimatedTestView()
            } else {
                MainView(model: pairDrag, updater: updater)
            }
            #else
            MainView(model: pairDrag, updater: updater)
            #endif
        }
        .windowResizability(.contentSize)
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
        if await AppMover.offerIfNeeded() { return }
        model.startWhenPermitted()
        // The user gives and takes permissions in System Settings, which tells no app.
        while !Task.isCancelled {
            try? await Task.sleep(for: permissionLookInterval)
            model.followPermissions()
        }
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
    private static let settingsLookFlag = "--settings-look"
    /// Pairwise works as usual meanwhile, and quits when the recording is finished.
    private static let recordFlag = "--record"
    private static let recordingTime = Duration.seconds(40)

    /// Says whether a flag asked for a test, which has then run, and the app is quitting.
    fileprivate static func runTestIfAsked(
        _ model: PairDragModel, _ system: AccessibilityWindowSystem
    ) async -> Bool {
        let arguments = CommandLine.arguments
        let isTestRun = arguments.contains { $0.hasPrefix("--") && $0 != recordFlag }
        // Test runs join windows of their own, and leave the user's saved pairs alone.
        model.keepsPairs = !isTestRun
        // They measure the live pictures too, whatever the user chose.
        if isTestRun { model.liveFramesPerSecond = DragPictures.live.framesPerSecond }
        if let flag = arguments.firstIndex(of: recordFlag), arguments.indices.contains(flag + 1) {
            model.start()
            await ScreenRecording(outputPath: arguments[flag + 1]).record(for: recordingTime)
            model.stop()
            NSApplication.shared.terminate(nil)
            return true
        }
        let flag = arguments.firstIndex {
            [
                stressTestFlag, joinTestFlag, seamTestFlag, seamLookFlag, killTestFlag,
                killCheckFlag, settingsLookFlag,
            ].contains($0)
        }
        guard let flag, arguments.indices.contains(flag + 1) else { return false }
        // The seam test measures windows alone, with no tap and no pair.
        if arguments[flag] != seamTestFlag, arguments[flag] != settingsLookFlag { model.start() }
        let test = DragStressTest(
            outputPath: arguments[flag + 1],
            pressOutcome: { model.lastPressOutcome },
            lastLiveFrames: { model.lastDrag?.liveFrames ?? [] },
            join: { first, second in try model.join(first, to: second, on: .left) },
            leave: { model.leavePair(of: $0) })
        await run(test, for: arguments[flag], model, system)
        model.stop()
        NSApplication.shared.terminate(nil)
        return true
    }

    private static func run(
        _ test: DragStressTest, for flag: String, _ model: PairDragModel,
        _ system: AccessibilityWindowSystem
    ) async {
        if flag == joinTestFlag {
            await test.runJoinTest(on: system)
        } else if flag == seamTestFlag {
            await test.runSeamTest()
        } else if flag == seamLookFlag {
            await test.runSeamLook()
        } else if flag == settingsLookFlag {
            await test.savePicture(
                of: NSHostingView(rootView: MainView(model: model, updater: Updater())))
        } else if flag == killTestFlag {
            await test.runKillTest()
        } else if flag == killCheckFlag {
            await test.runKillCheck(on: system)
        } else {
            await test.run()
        }
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
