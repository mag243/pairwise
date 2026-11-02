import AppKit
import PairwiseUI
import PairwiseWindowSystem
import SwiftUI

/// The macOS app: a menu bar item, and a settings window (ADR 0034). With
/// `--drag-stress-test <file>` it tests dragging itself and quits (ADR 0027).
@main
struct PairwiseMacApp: App {
    private static let stressTestFlag = "--drag-stress-test"
    private static let showSettingsFlag = "--show-settings"
    private static let settingsWindow = "settings"

    @State private var pairDrag: PairDragModel

    init() {
        let model = PairDragModel(system: AccessibilityWindowSystem())
        _pairDrag = State(initialValue: model)
        guard !Self.isAnimatedCopy else { return }
        Task { await Self.startWorking(model) }
    }

    var body: some Scene {
        MenuBarExtra(isInserted: .constant(!Self.isAnimatedCopy)) {
            MenuBarContent(model: pairDrag, settingsWindow: Self.settingsWindow)
        } label: {
            Image("MenuBarIcon")
        }
        Window("Pairwise", id: Self.settingsWindow) {
            if Self.isAnimatedCopy {
                AnimatedTestView()
            } else {
                MainView(model: pairDrag)
            }
        }
        .defaultLaunchBehavior(showsWindowAtLaunch ? .presented : .suppressed)
    }

    /// A copy of the app started by the stress test, which shows only an animation.
    private static var isAnimatedCopy: Bool {
        CommandLine.arguments.contains(DragStressTest.animatedWindowFlag)
    }

    /// The window opens by itself when the app is of no use without it.
    private var showsWindowAtLaunch: Bool {
        Self.isAnimatedCopy
            || CommandLine.arguments.contains(Self.showSettingsFlag)
            || !pairDrag.isAccessibilityGranted
            || !pairDrag.isScreenRecordingGranted
    }

    private static func startWorking(_ model: PairDragModel) async {
        let arguments = CommandLine.arguments
        guard
            let flag = arguments.firstIndex(of: stressTestFlag),
            arguments.indices.contains(flag + 1)
        else {
            if model.isAccessibilityGranted, model.isScreenRecordingGranted { model.start() }
            return
        }
        model.start()
        let test = DragStressTest(
            outputPath: arguments[flag + 1],
            pressOutcome: { model.lastPressOutcome },
            lastLiveFrames: { model.lastDrag?.liveFrames ?? [] },
            join: { first, second in try? model.join(first, to: second, on: .left) },
            leave: { model.leavePair(of: $0) })
        await test.run()
        model.stop()
        NSApplication.shared.terminate(nil)
    }
}
