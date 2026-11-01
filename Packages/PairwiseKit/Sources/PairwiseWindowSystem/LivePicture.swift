import PairwiseCore
import QuartzCore

/// The layer of one window's live picture, and how many of its frames showed a change.
@MainActor
final class LivePicture {
    /// The layer that shows the frames.
    var layer: CALayer?
    /// How many frames showed a change.
    var changes: Int { counter.changes }
    private var counter = ChangedFrameCounter()

    /// Shows a frame, with the pixel at the window's centre to tell whether it changed. It
    /// replaces the picture at once, as an animation here would lag behind the window.
    func show(_ surface: IOSurfaceRef, centrePixel: UInt32?) {
        counter.note(centrePixel)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer?.contents = surface
        CATransaction.commit()
    }
}
