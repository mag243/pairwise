import PairwiseCore

/// What the user grants elsewhere, in System Settings.
extension PairDragModel {
    /// Reads the permissions and the apps again; the user grants elsewhere, in System Settings.
    public func refreshPermissions() {
        isAccessibilityGranted = system.isAccessibilityGranted
        isScreenRecordingGranted = system.isScreenRecordingGranted
    }

    /// Starts now, or as soon as `followPermissions` sees that both permissions are given.
    /// A permission that is still missing is no problem yet: the settings ask for it anyway.
    public func startWhenPermitted() {
        start()
        if waitsForPermissions { problem = nil }
    }

    /// Reads the permissions, and acts when they changed in System Settings: starts when
    /// waiting for them, and stops when one was taken away, so that all input passes.
    public func followPermissions() {
        refreshPermissions()
        let isGranted = isAccessibilityGranted && isScreenRecordingGranted
        if isRunning, !isGranted {
            stop()
            waitsForPermissions = true
            problem = isAccessibilityGranted ? .screenRecordingDenied : .accessibilityDenied
        } else if waitsForPermissions, isGranted {
            start()
        }
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
