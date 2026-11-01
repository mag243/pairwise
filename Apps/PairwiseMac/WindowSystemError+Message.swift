import PairwiseCore
import SwiftUI

extension WindowSystemError {
    /// The reason to show the user.
    var message: LocalizedStringKey {
        switch self {
        case .accessibilityDenied: "Pairwise has no Accessibility access."
        case .eventTapUnavailable:
            "The pointer cannot be watched. Quit and reopen Pairwise after granting access."
        case .screenRecordingDenied: "Pairwise has no Screen Recording access."
        case .captureFailed: "No picture of the partner: it follows by itself."
        case .windowGone: "The window has gone."
        case .windowRefused: "The window refuses to move."
        case .windowBusy: "The window's app does not answer."
        case .noPartner: "No window of the partner app to follow: open one."
        }
    }
}
