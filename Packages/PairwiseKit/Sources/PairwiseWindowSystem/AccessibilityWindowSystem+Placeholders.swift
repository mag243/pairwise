import AppKit
import PairwiseCore

/// Stand-ins without any capture (on trial, plan M3a).
extension AccessibilityWindowSystem {
    private static let screenScaleWithoutScreen: CGFloat = 2

    /// A stand-in showing `windows` as placeholders, read through the Accessibility API.
    func placeholderStandIn(
        of windows: [AccessibilityWindow]
    ) -> Result<any WindowStandIn, WindowSystemError> {
        let scale = NSScreen.main?.backingScaleFactor ?? Self.screenScaleWithoutScreen
        let isDark =
            NSApplication.shared.effectiveAppearance.bestMatch(
                from: [.darkAqua, .aqua]) == .darkAqua
        var pictures: [StandInPanel.Picture] = []
        var placeholders: [PlaceholderLayers] = []
        for window in windows {
            guard let frame = try? window.frame() else { return .failure(.captureFailed) }
            let title = window.title ?? ""
            let icon = window.element.processID.flatMap {
                NSRunningApplication(processIdentifier: $0)?.icon
            }
            guard
                let picture = PlaceholderPicture.make(
                    title: title, icon: icon,
                    size: CGSize(width: frame.size.width, height: frame.size.height),
                    scale: scale, isDark: isDark)
            else { return .failure(.captureFailed) }
            pictures.append(picture)
            placeholders.append(
                PlaceholderLayers(title: title, icon: icon, scale: scale, isDark: isDark))
        }
        return .success(
            StandInPanel(pictures: pictures, streams: [], placeholders: placeholders))
    }
}
