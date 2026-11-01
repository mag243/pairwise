import SwiftUI

/// The macOS app: one empty window until the first milestone gives it content.
@main
struct PairwiseMacApp: App {
    private static let minimumWidth: CGFloat = 320
    private static let minimumHeight: CGFloat = 200

    var body: some Scene {
        WindowGroup("Pairwise") {
            Color.clear
                .frame(minWidth: Self.minimumWidth, minHeight: Self.minimumHeight)
        }
    }
}
