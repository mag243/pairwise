import PairwiseUI
import PairwiseWindowSystem
import SwiftUI

/// The macOS app: for the spike of M1, one window to start following and read the
/// measurements (ADR 0013).
@main
struct PairwiseMacApp: App {
    @State private var model: FollowModel
    @State private var dragTest: DragHoldTest

    init() {
        let system = AccessibilityWindowSystem()
        _model = State(initialValue: FollowModel(system: system))
        _dragTest = State(initialValue: DragHoldTest(system: system))
    }

    var body: some Scene {
        WindowGroup("Pairwise") {
            FollowView(model: model, dragTest: dragTest)
        }
    }
}
