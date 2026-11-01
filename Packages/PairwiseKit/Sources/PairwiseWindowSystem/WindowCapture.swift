import PairwiseCore
import ScreenCaptureKit

/// Takes pictures of other apps' windows through ScreenCaptureKit (ADR 0024).
@MainActor
enum WindowCapture {
    /// The system's list of windows from the last call. Asking for it takes the longest,
    /// and a window that has moved is still found in an older list.
    private static var knownContent: SCShareableContent?

    /// Fetches the list of windows ahead of the first picture; a failure is for later.
    static func prepare() async {
        knownContent = try? await SCShareableContent.excludingDesktopWindows(
            false, onScreenWindowsOnly: true)
    }

    /// A stand-in showing `windows` side by side as they look now. The pictures are taken
    /// at the same time, as each of them waits on the system.
    static func standIn(of windows: [AccessibilityWindow]) async -> Result<
        any WindowStandIn, WindowSystemError
    > {
        do {
            let content = try await content(for: windows)
            let tasks = windows.map { window in
                // swiftlint:disable:next unhandled_throwing_task - the value below rethrows it
                Task { try await picture(of: window, in: content) }
            }
            var pictures: [StandInPanel.Picture] = []
            for task in tasks {
                pictures.append(try await task.value)
            }
            Task { await prepare() }
            return .success(StandInPanel(pictures: pictures))
        } catch let error as WindowSystemError {
            return .failure(error)
        } catch {
            return .failure(.captureFailed)
        }
    }

    /// The known list when it holds all of `windows`, or else a fresh one.
    private static func content(
        for windows: [AccessibilityWindow]
    ) async throws -> SCShareableContent {
        if let knownContent, windows.allSatisfy({ holds($0, in: knownContent) }) {
            return knownContent
        }
        let fresh = try await SCShareableContent.excludingDesktopWindows(
            false, onScreenWindowsOnly: true)
        knownContent = fresh
        return fresh
    }

    private static func holds(
        _ window: AccessibilityWindow, in content: SCShareableContent
    ) -> Bool {
        guard let frame = try? window.frame() else { return false }
        return onScreenWindow(of: window, frame: frame, in: content) != nil
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
