import AppKit
import PairwiseCore

/// Pictures of windows side by side, tops level, in one panel of Pairwise's own. It takes
/// neither focus nor clicks, so the app being dragged keeps both (ADR 0024).
@MainActor
final class StandInPanel: WindowStandIn {
    /// A picture and the size in points of the window it shows.
    struct Picture: Sendable {
        let image: CGImage
        let size: CGSize
    }

    private let panel: NSPanel
    private let streams: [LiveStream]

    var liveFrames: [Int] { streams.map(\.frames) }

    /// Each stream, if any, updates the picture at the same place in `pictures`.
    init(pictures: [Picture], streams: [LiveStream]) {
        self.streams = streams
        let size = CGSize(
            width: pictures.map(\.size.width).reduce(0, +),
            height: pictures.map(\.size.height).max() ?? 0)
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
        var left: CGFloat = 0
        for (index, picture) in pictures.enumerated() {
            let layer = CALayer()
            layer.contents = picture.image
            layer.contentsGravity = .resize
            // A layer's origin is at its bottom left, and the tops are level.
            layer.frame = CGRect(
                x: left, y: size.height - picture.size.height,
                width: picture.size.width, height: picture.size.height)
            view.layer?.addSublayer(layer)
            if streams.indices.contains(index) { streams[index].layer = layer }
            left += picture.size.width
        }
        panel.contentView = view
    }

    func show(at origin: ScreenPoint) {
        move(to: origin)
        panel.orderFrontRegardless()
        for stream in streams { stream.start() }
    }

    func move(to origin: ScreenPoint) {
        panel.setFrameTopLeftPoint(NSScreen.appKitPoint(origin))
    }

    func dismiss() {
        for stream in streams { stream.stop() }
        panel.close()
    }
}
