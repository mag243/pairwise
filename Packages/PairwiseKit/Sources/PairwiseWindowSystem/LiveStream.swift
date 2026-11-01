import CoreMedia
import CoreVideo
import QuartzCore
import ScreenCaptureKit

/// Keeps a layer showing one window as it changes, while a drag lasts (ADR 0029). A failure
/// leaves the last picture on the layer, as the drag does not depend on this.
@MainActor
final class LiveStream: NSObject {
    /// The layer that shows the frames.
    var layer: CALayer?
    /// How many frames have arrived; a frame arrives only when the window has changed.
    private(set) var frames = 0

    private let filter: SCContentFilter
    private let configuration = SCStreamConfiguration()
    private var stream: SCStream?

    init(window: SCWindow, width: Int, height: Int, framesPerSecond: Int) {
        filter = SCContentFilter(desktopIndependentWindow: window)
        configuration.width = width
        configuration.height = height
        configuration.minimumFrameInterval = CMTime(
            value: 1, timescale: CMTimeScale(framesPerSecond))
        configuration.ignoreShadowsSingleWindow = true
        configuration.showsCursor = false
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        super.init()
    }

    /// Starts the frames; they arrive on the main queue.
    func start() {
        let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
        guard (try? stream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)) != nil
        else { return }
        self.stream = stream
        stream.startCapture { _ in }
    }

    /// Ends the frames.
    func stop() {
        stream?.stopCapture { _ in }
        stream = nil
    }

    fileprivate func show(_ surface: IOSurfaceRef) {
        frames += 1
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer?.contents = surface
        CATransaction.commit()
    }
}

extension LiveStream: SCStreamOutput {
    /// Runs on the main queue, as asked for in `start`. Only complete frames hold a new picture.
    nonisolated func stream(
        _ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard
            type == .screen,
            let attachments = CMSampleBufferGetSampleAttachmentsArray(
                sampleBuffer, createIfNecessary: false) as? [[SCStreamFrameInfo: Any]],
            let rawStatus = attachments.first?[.status] as? Int,
            SCFrameStatus(rawValue: rawStatus) == .complete,
            let buffer = CMSampleBufferGetImageBuffer(sampleBuffer),
            let surface = CVPixelBufferGetIOSurface(buffer)?.takeUnretainedValue()
        else { return }
        nonisolated(unsafe) let frame = surface
        MainActor.assumeIsolated { show(frame) }
    }
}
