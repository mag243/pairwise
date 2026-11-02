import PairwiseCore
import QuartzCore

/// The layer of one window's live picture, and how many of its frames showed a change.
@MainActor
final class LivePicture {
    /// The layer that shows the frames.
    var layer: CALayer?
    /// When set, this shows the frames instead, with the part of each that holds the window
    /// and the scale of that part (ADR 0049).
    var onFrame: (@MainActor (IOSurfaceRef, CGRect, Double) -> Void)?
    /// How many frames showed a change.
    var changes: Int { counter.changes }
    private var counter = ChangedFrameCounter()

    /// Shows a frame, with the pixel at the window's centre to tell whether it changed. It
    /// replaces the picture at once, as an animation here would lag behind the window.
    func show(
        _ surface: IOSurfaceRef, centrePixel: UInt32?, contentRect: CGRect? = nil,
        scale: Double = 1
    ) {
        counter.note(centrePixel)
        if let onFrame, let contentRect {
            onFrame(surface, contentRect, scale)
            return
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer?.contents = surface
        CATransaction.commit()
    }
}
