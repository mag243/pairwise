import AppKit
import PairwiseUI
import SwiftUI

/// The menu of the menu bar item (ADR 0034).
struct MenuBarContent: View {
    let model: PairDragModel
    let updater: Updater
    let settingsWindow: String

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Toggle("Move pairs together", isOn: isMoving)
        // With the settings closed, this is the only place that says why nothing moves.
        if let problem = model.problem {
            Text(problem.message)
        }
        Divider()
        Button("Settings…") {
            openWindow(id: settingsWindow)
            bringSettingsForward()
        }
        Divider()
        Button(updater.isUpdateWaiting ? "Update Available…" : "Check for Updates…") {
            updater.checkForUpdates()
        }
        .disabled(!updater.canCheck)
        Button("About Pairwise") {
            // An app without a Dock icon does not come forward by itself.
            NSApplication.shared.activate()
            NSApplication.shared.orderFrontStandardAboutPanel(nil)
        }
        Divider()
        Button("Quit Pairwise") {
            model.stop()
            NSApplication.shared.terminate(nil)
        }
    }

    /// An app without a Dock icon does not come forward by itself, and a window that is open on
    /// another desktop stays there unless told to come along. SwiftUI makes the window after
    /// this turn of the run loop.
    private func bringSettingsForward() {
        NSApplication.shared.activate()
        let identifier = settingsWindow
        Task { @MainActor in
            await Task.yield()
            let window = NSApplication.shared.windows.first {
                $0.identifier?.rawValue.contains(identifier) == true
            }
            window?.collectionBehavior.insert(.moveToActiveSpace)
            window?.makeKeyAndOrderFront(nil)
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
