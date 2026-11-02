import AppKit
import Observation
import Sparkle

/// Updates through Sparkle (ADR 0057). In a debug build it never starts, so a build under
/// development or a test run never offers to replace itself.
@MainActor @Observable
final class Updater: NSObject {
    /// Whether a check can start now; false while one runs, and in a debug build.
    private(set) var canCheck = false
    /// Whether an update was found in the background and waits for the user.
    private(set) var isUpdateWaiting = false

    @ObservationIgnored private var controller: SPUStandardUpdaterController?
    @ObservationIgnored private var canCheckWatch: NSKeyValueObservation?

    /// Whether the updater runs at all, which the settings show.
    var isAvailable: Bool { controller != nil }

    /// Whether Sparkle looks for updates by itself; the user's choice is stored by Sparkle.
    var checksAutomatically: Bool {
        get {
            access(keyPath: \.checksAutomatically)
            return controller?.updater.automaticallyChecksForUpdates ?? false
        }
        set {
            withMutation(keyPath: \.checksAutomatically) {
                controller?.updater.automaticallyChecksForUpdates = newValue
            }
        }
    }

    override init() {
        super.init()
        #if !DEBUG
        let controller = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: nil, userDriverDelegate: self)
        self.controller = controller
        // Sparkle changes this on the main thread, but the watch's closure cannot assume so.
        let updater = controller.updater
        canCheck = updater.canCheckForUpdates
        canCheckWatch = updater.observe(\.canCheckForUpdates, options: .new) { [weak self] _, _ in
            Task { @MainActor in
                self?.canCheck = self?.controller?.updater.canCheckForUpdates ?? false
            }
        }
        #endif
    }

    /// Checks now, or opens the update that waits.
    func checkForUpdates() {
        // An app without a Dock icon does not come forward by itself.
        NSApplication.shared.activate()
        controller?.checkForUpdates(nil)
    }
}

extension Updater: SPUStandardUserDriverDelegate {
    nonisolated var supportsGentleScheduledUpdateReminders: Bool { true }

    /// An update found in the background only opens when the user is looking at Pairwise.
    nonisolated func standardUserDriverShouldHandleShowingScheduledUpdate(
        _ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool
    ) -> Bool {
        immediateFocus
    }

    nonisolated func standardUserDriverWillHandleShowingUpdate(
        _ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState
    ) {
        guard !handleShowingUpdate, !state.userInitiated else { return }
        Task { @MainActor in isUpdateWaiting = true }
    }

    nonisolated func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        Task { @MainActor in isUpdateWaiting = false }
    }

    nonisolated func standardUserDriverWillFinishUpdateSession() {
        Task { @MainActor in isUpdateWaiting = false }
    }
}
