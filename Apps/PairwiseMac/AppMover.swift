import AppKit
import PairwiseCore

/// Offers once to move the app to Applications (ADR 0060). A Release build only: a debug build
/// runs from the build folder on purpose.
@MainActor
enum AppMover {
    private static let hasOfferedKey = "hasOfferedMove"
    private static let applications = URL(filePath: "/Applications", directoryHint: .isDirectory)

    /// Offers a move if there is reason to. Returns whether the app is quitting to run from there.
    static func offerIfNeeded() async -> Bool {
        #if DEBUG
        false
        #else
        let defaults = UserDefaults.standard
        let source = Bundle.main.bundleURL
        guard
            InstallPlace.offersMove(
                appPath: source.path(), homePath: NSHomeDirectory(),
                hasOffered: defaults.bool(forKey: hasOfferedKey))
        else { return false }
        defaults.set(true, forKey: hasOfferedKey)
        guard askToMove() else { return false }
        do {
            let target = try copy(source)
            try await NSWorkspace.shared.openApplication(
                at: target, configuration: newInstance())
            NSApplication.shared.terminate(nil)
            return true
        } catch {
            show(error)
            return false
        }
        #endif
    }

    private static func newInstance() -> NSWorkspace.OpenConfiguration {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        return configuration
    }

    private static func askToMove() -> Bool {
        // An app without a Dock icon does not come forward by itself.
        NSApplication.shared.activate()
        let alert = NSAlert()
        alert.messageText = String(localized: "Move Pairwise to Applications?")
        alert.informativeText = String(
            localized: "It can then start at login and update itself. It will not ask again.")
        alert.addButton(withTitle: String(localized: "Move to Applications"))
        alert.addButton(withTitle: String(localized: "Not Now"))
        return alert.runModal() == .alertFirstButtonReturn
    }

    /// Puts a copy in Applications, with an older one in the Trash so that nothing is lost.
    private static func copy(_ source: URL) throws -> URL {
        let target = applications.appending(path: source.lastPathComponent)
        let files = FileManager.default
        if files.fileExists(atPath: target.path()) {
            try files.trashItem(at: target, resultingItemURL: nil)
        }
        try files.copyItem(at: source, to: target)
        return target
    }

    private static func show(_ error: Error) {
        let alert = NSAlert()
        alert.messageText = String(localized: "Pairwise could not be moved")
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }
}
