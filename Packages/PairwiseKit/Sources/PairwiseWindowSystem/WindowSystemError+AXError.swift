import ApplicationServices
import PairwiseCore

extension WindowSystemError {
    /// What a failed Accessibility call means for Pairwise.
    /// Precondition: `error` is not `.success`.
    init(_ error: AXError) {
        precondition(error != .success, "error is not .success")
        switch error {
        case .invalidUIElement: self = .windowGone
        case .apiDisabled: self = .accessibilityDenied
        case .cannotComplete: self = .windowBusy
        default: self = .windowRefused
        }
    }
}
