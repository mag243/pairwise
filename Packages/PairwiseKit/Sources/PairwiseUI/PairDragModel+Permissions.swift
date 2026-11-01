import PairwiseCore

/// What the user grants elsewhere, in System Settings.
extension PairDragModel {
    /// Reads the permissions and the apps again; the user grants elsewhere, in System Settings.
    public func refreshPermissions() {
        partnerApps = system.partnerApps
        isAccessibilityGranted = system.isAccessibilityGranted
        isScreenRecordingGranted = system.isScreenRecordingGranted
    }

    /// Asks the system to show the user where to grant the Accessibility permission.
    public func requestAccessibility() {
        system.requestAccessibility()
    }

    /// Asks the system for the Screen Recording permission.
    public func requestScreenRecording() {
        system.requestScreenRecording()
    }
}
