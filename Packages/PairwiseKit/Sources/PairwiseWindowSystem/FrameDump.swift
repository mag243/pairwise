#if DEBUG

import CoreImage
import Foundation
import ImageIO

/// Saves the first frames of each live stream as they come from the system, before Pairwise
/// shows them, with `--dump-frames <folder>`, to tell what is in a frame from what the panel
/// does with it.
enum FrameDump {
    private static let flag = "--dump-frames"
    private static let framesPerStream = 45
    private static let lock = NSLock()
    nonisolated(unsafe) private static var counts: [ObjectIdentifier: Int] = [:]
    nonisolated(unsafe) private static var streams: [ObjectIdentifier: Int] = [:]

    private static let folder: String? = {
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: flag), arguments.indices.contains(index + 1)
        else { return nil }
        return arguments[index + 1]
    }()

    /// Saves `surface` as the next frame of `stream`, up to the limit per stream.
    static func save(_ surface: IOSurfaceRef, stream: ObjectIdentifier) {
        guard let folder else { return }
        lock.lock()
        let streamNumber = streams[stream] ?? streams.count
        streams[stream] = streamNumber
        let frame = counts[stream, default: 0]
        counts[stream] = frame + 1
        lock.unlock()
        guard frame < framesPerStream else { return }
        let image = CIImage(ioSurface: surface)
        let context = CIContext()
        let url = URL(fileURLWithPath: "\(folder)/stream\(streamNumber)-\(frame + 1000).jpg")
        try? context.writeJPEGRepresentation(
            of: image, to: url, colorSpace: CGColorSpaceCreateDeviceRGB())
    }
}

#endif
