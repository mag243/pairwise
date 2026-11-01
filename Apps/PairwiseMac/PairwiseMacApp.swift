import AppKit
import PairwiseUI
import PairwiseWindowSystem
import SwiftUI

/// The macOS app: for now one window to start moving windows as one and read the
/// measurements (ADR 0024). With `--drag-stress-test <file>` it tests dragging
/// itself and quits (ADR 0027).
@main
struct PairwiseMacApp: App {
    private static let stressTestFlag = "--drag-stress-test"

    @State private var pairDrag: PairDragModel

    init() {
        let system = AccessibilityWindowSystem()
        _pairDrag = State(initialValue: PairDragModel(system: system))
    }

    var body: some Scene {
        WindowGroup("Pairwise") {
            if CommandLine.arguments.contains(DragStressTest.animatedWindowFlag) {
                AnimatedTestView()
            } else {
                MainView(model: pairDrag)
                    .task { await runStressTestIfAsked() }
            }
        }
    }

    private func runStressTestIfAsked() async {
        let arguments = CommandLine.arguments
        guard
            let flag = arguments.firstIndex(of: Self.stressTestFlag),
            arguments.indices.contains(flag + 1)
        else { return }
        pairDrag.start()
        let model = pairDrag
        let test = DragStressTest(
            outputPath: arguments[flag + 1],
            pressOutcome: { model.lastPressOutcome },
            lastLiveFrames: { model.lastDrag?.liveFrames ?? [] },
            join: { first, second in try? model.join(first, to: second, on: .left) },
            leave: { model.leavePair(of: $0) })
        await test.run()
        pairDrag.stop()
        NSApplication.shared.terminate(nil)
    }
}
