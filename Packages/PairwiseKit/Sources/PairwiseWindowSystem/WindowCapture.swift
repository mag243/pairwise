import PairwiseCore
import ScreenCaptureKit

/// Takes pictures of other apps' windows through ScreenCaptureKit (ADR 0014).
@MainActor
enum WindowCapture {
    /// A stand-in showing `windows` side by side as they look now.
    static func standIn(of windows: [AccessibilityWindow]) async -> Result<
        any WindowStandIn, WindowSystemError
    > {
        do {
            let content = try await SCShareableContent.excludingDesktopWindows(
                false, onScreenWindowsOnly: true)
            var pictures: [StandInPanel.Picture] = []
            for window in windows {
                pictures.append(try await picture(of: window, in: content))
            }
            return .success(StandInPanel(pictures: pictures))
        } catch let error as WindowSystemError {
            return .failure(error)
        } catch {
            return .failure(.captureFailed)
        }
    }

    private static func picture(
        of window: AccessibilityWindow, in content: SCShareableContent
    ) async throws -> StandInPanel.Picture {
        let frame = try window.frame()
        guard let match = onScreenWindow(of: window, frame: frame, in: content) else {
            throw WindowSystemError.captureFailed
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
        return StandInPanel.Picture(image: image, size: size)
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
