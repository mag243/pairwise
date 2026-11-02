import AppKit
import PairwiseUI
import SwiftUI

/// The menu of the menu bar item (ADR 0034).
struct MenuBarContent: View {
    let model: PairDragModel
    let settingsWindow: String

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Toggle("Move pairs together", isOn: isMoving)
        Divider()
        Button("About Pairwise") {
            // An app without a Dock icon does not come forward by itself.
            NSApplication.shared.activate()
            NSApplication.shared.orderFrontStandardAboutPanel(nil)
        }
        Button("Settings…") {
            openWindow(id: settingsWindow)
            // An app without a Dock icon does not come forward by itself.
            NSApplication.shared.activate()
        }
        Button("Quit Pairwise") {
            model.stop()
            NSApplication.shared.terminate(nil)
        }
    }

    private var isMoving: Binding<Bool> {
        Binding {
            model.isRunning
        } set: { isOn in
            if isOn { model.start() } else { model.stop() }
        }
    }
}
