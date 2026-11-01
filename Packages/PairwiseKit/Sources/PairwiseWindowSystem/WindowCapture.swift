import PairwiseCore
import ScreenCaptureKit

/// Takes a picture of another app's window through ScreenCaptureKit (ADR 0014).
@MainActor
enum WindowCapture {
    /// A stand-in showing `window` as it looks now.
    static func standIn(of window: AccessibilityWindow) async -> Result<
        any WindowStandIn, WindowSystemError
    > {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false, onScreenWindowsOnly: true)
            let frame = try window.frame()
            guard let match = onScreenWindow(of: window, frame: frame, in: content) else {
                return .failure(.captureFailed)
            }
            let filter = SCContentFilter(desktopIndependentWindow: match)
            let scale = Double(filter.pointPixelScale)
            let configuration = SCStreamConfiguration()
            configuration.width = Int(frame.size.width * scale)
            configuration.height = Int(frame.size.height * scale)
            configuration.ignoreShadowsSingleWindow = true
            configuration.showsCursor = false
            let image = try await SCScreenshotManager.captureImage(
                contentFilter: filter, configuration: configuration)
            let size = CGSize(width: frame.size.width, height: frame.size.height)
            return .success(StandInPanel(image: image, size: size))
        } catch let error as WindowSystemError {
            return .failure(error)
        } catch {
            return .failure(.captureFailed)
        }
    }

    private static func onScreenWindow(
        of window: AccessibilityWindow, frame: WindowFrame, in content: SCShareableContent
    ) -> SCWindow? {
        let processID = window.element.processID
        let candidates = content.windows.filter { $0.owningApplication?.processID == processID }
        let frames = candidates.map { WindowFrame(origin: $0.frame.origin, size: $0.frame.size) }
        return WindowMatch.index(of: frame, among: frames).map { candidates[$0] }
    }
}
