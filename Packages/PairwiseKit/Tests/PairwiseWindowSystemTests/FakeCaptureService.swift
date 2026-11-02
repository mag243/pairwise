import CoreGraphics
import PairwiseCore
import PairwiseTestSupport

@testable import PairwiseWindowSystem

/// A window in the fake system's list.
struct FakeCapturable: CapturableWindow {
    let processID: pid_t?
    let frame: WindowFrame
}

/// A window of neither the real system nor a capture list.
@MainActor
final class FakePlainWindow: MovableWindow {
    var windowNumber: UInt32? { nil }
    var isAvailable: Bool { true }

    func frame() throws(WindowSystemError) -> WindowFrame {
        WindowFrame(x: 0, y: 0, width: 1, height: 1)
    }

    func serverFrame() -> WindowFrame? { nil }
    func move(to origin: ScreenPoint) throws(WindowSystemError) {}
    func resize(to size: WindowSize) throws(WindowSystemError) {}
    func raise() throws(WindowSystemError) {}
}

/// A capture service in memory.
@MainActor
final class FakeCaptureService: CaptureService {
    var windows: [FakeCapturable] = []
    var listError: (any Error)?
    var pictureError: (any Error)?
    private(set) var listRequests = 0
    private(set) var pictureFrames: [WindowFrame] = []
    private(set) var standInFramesPerSecond: Int?

    func onScreenWindows() async throws -> [any CapturableWindow] {
        listRequests += 1
        if let listError { throw listError }
        return windows
    }

    func picture(
        of window: any CapturableWindow, frame: WindowFrame
    ) async throws -> StandInPanel.Picture {
        if let pictureError { throw pictureError }
        pictureFrames.append(frame)
        return try StandInPanel.Picture(image: Self.image(), size: .zero)
    }

    func standIn(
        pictures: [StandInPanel.Picture],
        windows: [(window: any CapturableWindow, frame: WindowFrame)], framesPerSecond: Int
    ) -> any WindowStandIn {
        standInFramesPerSecond = framesPerSecond
        return FakeStandIn()
    }

    private struct NoImage: Error {}

    /// A picture of one pixel.
    static func image() throws -> CGImage {
        let space = CGColorSpaceCreateDeviceRGB()
        guard
            let image = CGContext(
                data: nil, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 0, space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?.makeImage()
        else { throw NoImage() }
        return image
    }
}
