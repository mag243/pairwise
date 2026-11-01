import PairwiseUI
import PairwiseWindowSystem
import SwiftUI

/// The macOS app: for the spike of M1, one window to start following and read the
/// measurements (ADR 0013).
@main
struct PairwiseMacApp: App {
    @State private var model = FollowModel(system: AccessibilityWindowSystem())

    var body: some Scene {
        WindowGroup("Pairwise") {
            FollowView(model: model)
        }
    }
}
