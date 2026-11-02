import PairwiseCore

/// What the user grants elsewhere, in System Settings.
extension PairDragModel {
    /// Reads the permissions and the apps again; the user grants elsewhere, in System Settings.
    public func refreshPermissions() {
        isAccessibilityGranted = system.isAccessibilityGranted
        isScreenRecordingGranted = system.isScreenRecordingGranted
    }

    /// Starts now, or as soon as `followPermissions` sees that Accessibility is given.
    /// A permission that is still missing is no problem yet: the settings ask for it anyway.
    public func startWhenPermitted() {
        start()
        if waitsForPermissions { problem = nil }
    }

    /// Reads the permissions, and acts when they changed in System Settings: starts when waiting
    /// for Accessibility, and stops when it was taken away, so that all input passes. Without
    /// Screen Recording, pictures that need it fall back on placeholders (ADR 0064).
    public func followPermissions() {
        let hadScreenRecording = isScreenRecordingGranted
        refreshPermissions()
        if hadScreenRecording != isScreenRecordingGranted { applyDragPictures() }
        if isRunning, !isAccessibilityGranted {
            stop()
            waitsForPermissions = true
            problem = .accessibilityDenied
        } else if waitsForPermissions, isAccessibilityGranted {
            start()
        }
    }

    /// Passes the choice on, or placeholders when it needs a permission that is missing.
    func applyDragPictures() {
        let usable =
            dragPictures.needsScreenRecording && !isScreenRecordingGranted
            ? DragPictures.placeholder : dragPictures
        system.showsPlaceholders = usable == .placeholder
        liveFramesPerSecond = usable.framesPerSecond
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
