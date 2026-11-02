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

    /// What a picture's slot in the panel and its picture within the slot take up.
    struct SeamPlace: Equatable {
        let slot: CGRect
        let image: CGRect
    }

    /// How far from the seam the column that stretches is, in points, away from the window's
    /// rounded corners and its edge.
    private static let stretchInset: CGFloat = 12

    private let panel: NSPanel
    private let streams: [LiveStream]
    private let pictures: [Picture]
    /// A layer per picture that cuts it off at the seam, and the layer with the picture.
    private var slots: [CALayer] = []
    private var images: [CALayer] = []

    var liveFrames: [Int] { streams.map(\.frames) }

    /// Each stream, if any, updates the picture at the same place in `pictures`.
    init(pictures: [Picture], streams: [LiveStream]) {
        self.streams = streams
        self.pictures = pictures
        let layout = Self.layout(of: pictures.map(\.size))
        let size = layout.size
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
        for (index, picture) in pictures.enumerated() {
            let slot = CALayer()
            slot.frame = layout.frames[index]
            slot.masksToBounds = true
            let layer = CALayer()
            layer.contents = picture.image
            layer.contentsGravity = .resize
            layer.frame = CGRect(origin: .zero, size: picture.size)
            slot.addSublayer(layer)
            view.layer?.addSublayer(slot)
            slots.append(slot)
            images.append(layer)
            if streams.indices.contains(index) { streams[index].picture.layer = layer }
        }
        panel.contentView = view
    }

    /// Where pictures of these sizes go side by side, tops level, in a panel of the size
    /// given. A layer's origin is at its bottom left.
    static func layout(of sizes: [CGSize]) -> (size: CGSize, frames: [CGRect]) {
        let height = sizes.map(\.height).max() ?? 0
        var left: CGFloat = 0
        let frames = sizes.map { size in
            defer { left += size.width }
            return CGRect(
                x: left, y: height - size.height, width: size.width, height: size.height)
        }
        return (CGSize(width: left, height: height), frames)
    }

    /// Where two pictures go with the seam at `seam` from the left. A narrower window's picture
    /// is cut off at the seam, a wider one's fills its slot, and each keeps its far edge.
    static func seamLayout(of sizes: [CGSize], seamAt seam: CGFloat) -> [SeamPlace] {
        guard sizes.count == 2 else { return [] }
        let (left, right) = (sizes[0], sizes[1])
        let height = max(left.height, right.height)
        let rightWidth = left.width + right.width - seam
        let leftImage = max(left.width, seam)
        let rightImage = max(right.width, rightWidth)
        return [
            SeamPlace(
                slot: CGRect(x: 0, y: height - left.height, width: seam, height: left.height),
                image: CGRect(x: 0, y: 0, width: leftImage, height: left.height)),
            SeamPlace(
                slot: CGRect(
                    x: seam, y: height - right.height, width: rightWidth, height: right.height),
                image: CGRect(
                    x: rightWidth - rightImage, y: 0, width: rightImage, height: right.height)),
        ]
    }

    /// The part of a picture that stretches when it fills a wider slot, as a share of the
    /// picture: a thin column near the seam, which is mostly plain window.
    static func stretchingColumn(ofPictureWidth width: CGFloat, isLeft: Bool) -> CGRect {
        let columnWidth = 1 / width
        let inset = stretchInset / width
        return CGRect(x: isLeft ? 1 - inset : inset, y: 0, width: columnWidth, height: 1)
    }

    func setSeam(atOffset offset: Double) {
        let places = Self.seamLayout(of: pictures.map(\.size), seamAt: offset)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for (index, place) in places.enumerated() {
            let picture = pictures[index]
            slots[index].frame = place.slot
            images[index].frame = place.image
            // The parts that do not stretch keep the picture's own pixels per point.
            images[index].contentsScale = CGFloat(picture.image.width) / picture.size.width
            images[index].contentsCenter = Self.stretchingColumn(
                ofPictureWidth: picture.size.width, isLeft: index == 0)
        }
        CATransaction.commit()
    }

    func showStill(at origin: ScreenPoint) {
        move(to: origin)
        panel.orderFrontRegardless()
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
