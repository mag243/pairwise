import Observation
import ServiceManagement

/// Starting at login (ADR 0060). What macOS says is the truth, since the user can also change
/// it in System Settings. A debug build leaves it off, and never starts by itself.
@MainActor @Observable
final class LoginItem {
    /// Why the last change failed, to show beside the switch.
    private(set) var failure: String?

    /// Whether the switch can be used in this build.
    var isAvailable: Bool {
        #if DEBUG
        false
        #else
        true
        #endif
    }

    /// Whether Pairwise starts at login, as macOS has it.
    var isOn: Bool {
        get {
            access(keyPath: \.isOn)
            return SMAppService.mainApp.status == .enabled
        }
        set {
            withMutation(keyPath: \.isOn) { change(to: newValue) }
        }
    }

    private func change(to isOn: Bool) {
        do {
            if isOn {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            failure = nil
        } catch {
            failure = error.localizedDescription
        }
    }
}
