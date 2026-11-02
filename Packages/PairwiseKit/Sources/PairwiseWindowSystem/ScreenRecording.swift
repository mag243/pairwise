#if DEBUG

import AppKit
import ScreenCaptureKit
import os

/// Records the display under the pointer to a file for a while, to look at a drag frame by
/// frame afterwards. It only watches, and needs the Screen Recording permission.
@MainActor
public final class ScreenRecording: NSObject {
    private static let logger = Logger(subsystem: "me.m-domain.pairwise", category: "recording")
    private static let framesPerSecond: CMTimeScale = 60
    /// How long the system gets to finish the file after the recording stops.
    private static let finishTime = Duration.seconds(2)

    private let outputPath: String
    private var stream: SCStream?

    /// Precondition: nothing exists at `outputPath`, or it may be replaced.
    public init(outputPath: String) {
        self.outputPath = outputPath
    }

    /// Records for `duration`, and returns when the file is finished. A failure is logged and
    /// also written next to the file, as this is a tool to look at something else.
    public func record(for duration: Duration) async {
        do {
            try await start()
            try await Task.sleep(for: duration)
            try await stream?.stopCapture()
            try await Task.sleep(for: Self.finishTime)
        } catch {
            let text = "the recording failed: \(error)\n"
            Self.logger.info("\(text, privacy: .public)")
            try? text.write(toFile: outputPath + ".error", atomically: true, encoding: .utf8)
        }
    }

    private func start() async throws {
        let content = try await SCShareableContent.excludingDesktopWindows(
            false, onScreenWindowsOnly: true)
        let underPointer =
            NSScreen.screens.first { $0.frame.contains(NSEvent.mouseLocation) }
            .flatMap { $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? UInt32 }
        guard
            let display = content.displays.first(where: { $0.displayID == underPointer })
                ?? content.displays.first
        else { throw CocoaError(.featureUnsupported) }
        let filter = SCContentFilter(display: display, excludingWindows: [])
        let scale = Int(filter.pointPixelScale)
        let configuration = SCStreamConfiguration()
        configuration.width = display.width * scale
        configuration.height = display.height * scale
        configuration.minimumFrameInterval = CMTime(value: 1, timescale: Self.framesPerSecond)
        configuration.showsCursor = true
        let output = SCRecordingOutputConfiguration()
        output.outputURL = URL(fileURLWithPath: outputPath)
        output.outputFileType = .mov
        let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
        try stream.addRecordingOutput(SCRecordingOutput(configuration: output, delegate: self))
        try await stream.startCapture()
        self.stream = stream
    }
}

extension ScreenRecording: SCRecordingOutputDelegate {}

#endif
