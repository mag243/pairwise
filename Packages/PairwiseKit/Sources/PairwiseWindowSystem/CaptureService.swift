import PairwiseCore
import ScreenCaptureKit

/// A window that can be captured, as the system lists it.
@MainActor
protocol CapturableWindow {
    /// The process of the app that owns it, or `nil` when the system does not say.
    var processID: pid_t? { get }
    /// Its frame in global screen coordinates.
    var frame: WindowFrame { get }
    /// The window server's number for it.
    var windowNumber: UInt32? { get }
}

/// The calls to ScreenCaptureKit (ADR 0031).
@MainActor
protocol CaptureService {
    /// The windows on screen.
    func onScreenWindows() async throws -> [any CapturableWindow]
    /// A picture of `window`, which has the frame `frame`.
    func picture(
        of window: any CapturableWindow, frame: WindowFrame
    ) async throws -> StandInPanel.Picture
    /// A stand-in of `pictures`, each kept live from its window in `windows` unless
    /// `framesPerSecond` is 0.
    func standIn(
        pictures: [StandInPanel.Picture],
        windows: [(window: any CapturableWindow, frame: WindowFrame)],
        framesPerSecond: Int
    ) -> any WindowStandIn
}

/// The real ScreenCaptureKit. Each call only forwards.
struct LiveCaptureService: CaptureService {
    private struct Window: CapturableWindow {
        let window: SCWindow
        var processID: pid_t? { window.owningApplication?.processID }
        var windowNumber: UInt32? { window.windowID }
        var frame: WindowFrame { WindowFrame(origin: window.frame.origin, size: window.frame.size) }
    }

    func onScreenWindows() async throws -> [any CapturableWindow] {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false, onScreenWindowsOnly: true)
        return content.windows.map(Window.init(window:))
    }

    func picture(
        of window: any CapturableWindow, frame: WindowFrame
    ) async throws -> StandInPanel.Picture {
        guard let window = (window as? Window)?.window else {
            throw WindowSystemError.captureFailed
        }
        let configuration = SCStreamConfiguration()
        let pixels = Self.pixelSize(of: window, frame: frame)
        configuration.width = pixels.width
        configuration.height = pixels.height
        configuration.ignoreShadowsSingleWindow = true
        configuration.showsCursor = false
        let image = try await SCScreenshotManager.captureImage(
            contentFilter: SCContentFilter(desktopIndependentWindow: window),
            configuration: configuration)
        let size = CGSize(width: frame.size.width, height: frame.size.height)
        return StandInPanel.Picture(image: image, size: size)
    }

    func standIn(
        pictures: [StandInPanel.Picture],
        windows: [(window: any CapturableWindow, frame: WindowFrame)],
        framesPerSecond: Int
    ) -> any WindowStandIn {
        let streams: [LiveStream] =
            framesPerSecond > 0
            ? windows.compactMap { found in
                guard let window = (found.window as? Window)?.window else { return nil }
                let pixels = Self.pixelSize(of: window, frame: found.frame)
                return LiveStream(
                    window: window, width: pixels.width, height: pixels.height,
                    framesPerSecond: framesPerSecond)
            } : []
        return StandInPanel(pictures: pictures, streams: streams)
    }

    private static func pixelSize(
        of window: SCWindow, frame: WindowFrame
    ) -> (width: Int, height: Int) {
        let scale = Double(SCContentFilter(desktopIndependentWindow: window).pointPixelScale)
        return (Int(frame.size.width * scale), Int(frame.size.height * scale))
    }
}
