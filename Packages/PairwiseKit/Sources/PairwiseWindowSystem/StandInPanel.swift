import AppKit
import PairwiseCore

/// A picture of a window in a panel of Pairwise's own. It takes neither focus nor
/// clicks, so the app being dragged keeps both (ADR 0014).
@MainActor
final class StandInPanel: WindowStandIn {
    private let panel: NSPanel

    /// `size` is the pictured window's size in points.
    init(image: CGImage, size: CGSize) {
        panel = NSPanel(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.level = .floating
        panel.collectionBehavior = [.transient, .ignoresCycle, .fullScreenAuxiliary]
        let view = NSView(frame: CGRect(origin: .zero, size: size))
        view.wantsLayer = true
        view.layer?.contents = image
        view.layer?.contentsGravity = .resize
        panel.contentView = view
    }

    func show(at origin: ScreenPoint) {
        move(to: origin)
        panel.orderFrontRegardless()
    }

    func move(to origin: ScreenPoint) {
        panel.setFrameTopLeftPoint(NSScreen.appKitPoint(origin))
    }

    func dismiss() {
        panel.close()
    }
}
