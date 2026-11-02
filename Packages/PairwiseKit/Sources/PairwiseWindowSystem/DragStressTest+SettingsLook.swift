#if DEBUG

import AppKit

/// A picture of a view, to look at what it shows. It is drawn in a window that is never shown,
/// so nothing else on the screen can get in.
extension DragStressTest {
    private static let layoutWait: UInt64 = 1000

    /// Saves `view` at its own size to the output file, as a PNG.
    public func savePicture(of view: NSView) async {
        let size = view.fittingSize
        let window = NSWindow(
            contentRect: CGRect(origin: .zero, size: size), styleMask: [.titled],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = view
        await wait(Self.layoutWait)
        guard let bitmap = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: bitmap)
        try? bitmap.representation(using: .png, properties: [:])?
            .write(to: URL(fileURLWithPath: outputPath))
    }
}

#endif
