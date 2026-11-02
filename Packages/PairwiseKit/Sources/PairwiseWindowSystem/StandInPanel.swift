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

    /// Where a picture goes for a seam: its slot in the panel, and within the slot its first
    /// half, its second half and the room between. A narrower window loses its middle and a
    /// wider one gains one, so that both edges stay whole, as with a real window (ADR 0048).
    struct SeamPlace: Equatable {
        let slot: CGRect
        let head: CGRect
        let fill: CGRect
        let tail: CGRect
    }

    /// The layers of one picture for a seam.
    struct SeamLayers {
        let head = StandInPanel.stillLayer()
        let fill = StandInPanel.stillLayer()
        let tail = StandInPanel.stillLayer()
    }

    private let panel: NSPanel
    private let streams: [LiveStream]
    private let pictures: [Picture]
    /// What shows each picture at a seam, for pictures with no content to keep whole.
    private let placeholders: [PlaceholderLayers]
    /// A layer per picture that cuts it off at the seam, the layer with the whole picture, and
    /// the layers that show its parts once a seam has been set.
    private(set) var slots: [CALayer] = []
    private(set) var images: [CALayer] = []
    private(set) var parts: [SeamLayers] = []
    /// Where each picture divides, as a share of its width, found at the first seam.
    private var splitShares: [CGFloat] = []
    private var seam: CGFloat?
    private var isPreparedForSeam = false
    /// An opaque layer under each picture, added at the first seam.
    private(set) var backings: [CALayer] = []
    /// The amber line on the seam, added at the first seam.
    let seamLineLayer = StandInPanel.stillLayer()
    private var totalWidth: CGFloat { pictures.map(\.size.width).reduce(0, +) }

    var liveFrames: [Int] { streams.map(\.frames) }

    /// Each stream, if any, updates the picture at the same place in `pictures`.
    /// With `placeholders`, one per picture, these take over from the pictures at a seam.
    init(
        pictures: [Picture], streams: [LiveStream], placeholders: [PlaceholderLayers] = []
    ) {
        self.streams = streams
        self.pictures = pictures
        self.placeholders = placeholders
        let layout = Self.layout(of: pictures.map(\.size))
        let size = layout.size
        panel = NSPanel(
            contentRect: CGRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isReleasedWhenClosed = false
        // A fade would show the old pictures over windows of another size.
        panel.animationBehavior = .none
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        panel.level = .floating
        panel.collectionBehavior = [.transient, .ignoresCycle, .fullScreenAuxiliary]
        let view = NSView(frame: CGRect(origin: .zero, size: size))
        view.wantsLayer = true
        for (index, picture) in pictures.enumerated() {
            let slot = StandInPanel.stillLayer()
            slot.frame = layout.frames[index]
            slot.masksToBounds = true
            let layer = StandInPanel.stillLayer()
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

    private static func seamLayers(
        of picture: Picture, split: CGFloat, in slot: CALayer
    ) -> SeamLayers {
        let layers = SeamLayers()
        let share = split / picture.size.width
        let pieces = [
            (layers.head, CGRect(x: 0, y: 0, width: share, height: 1)),
            (layers.fill, fillColumn(ofPictureWidth: picture.size.width, atSplit: split)),
            (layers.tail, CGRect(x: share, y: 0, width: 1 - share, height: 1)),
        ]
        for (layer, piece) in pieces {
            layer.contents = picture.image
            layer.contentsGravity = .resize
            layer.contentsRect = piece
            slot.addSublayer(layer)
        }
        return layers
    }

    /// Prepares once, at the first seam, as a press that only moves needs none of this. With
    /// live frames to come, the picture is scaled as they are, so that it lies exactly under
    /// the first of them. Only pictures that stay still are divided (ADR 0049).
    private func prepareForSeam() {
        guard !isPreparedForSeam else { return }
        isPreparedForSeam = true
        seamLineLayer.backgroundColor = SeamColour.amber.cgColor
        seamLineLayer.cornerRadius = Self.seamLineWidth / 2
        panel.contentView?.layer?.addSublayer(seamLineLayer)
        for (index, picture) in pictures.enumerated() {
            let backing = StandInPanel.stillLayer()
            backing.backgroundColor = Self.backingColour(of: picture.image)
            backing.cornerRadius = Self.backingCornerRadius
            slots[index].insertSublayer(backing, at: 0)
            backings.append(backing)
        }
        for (index, placeholder) in placeholders.enumerated() {
            slots[index].addSublayer(placeholder.root)
            images[index].isHidden = true
        }
        guard streams.isEmpty, placeholders.isEmpty else { return }
        for (index, picture) in pictures.enumerated() {
            let split = Self.quietSplit(of: picture)
            splitShares.append(split / picture.size.width)
            parts.append(Self.seamLayers(of: picture, split: split, in: slots[index]))
            images[index].isHidden = true
        }
    }

    func setSeam(atOffset offset: Double) {
        seam = offset
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        prepareForSeam()
        layOutSeam()
        CATransaction.commit()
    }

    private func layOutSeam() {
        guard let seam else { return }
        let sizes = pictures.map(\.size)
        let live = Self.liveLayout(of: sizes, totalWidth: totalWidth, seamAt: seam)
        for (index, place) in live.enumerated() {
            slots[index].frame = place.slot
            images[index].frame = place.frame
            backings[index].frame = place.frame
            if placeholders.indices.contains(index) {
                placeholders[index].layOut(size: place.frame.size)
            }
        }
        let splits = zip(sizes, splitShares).map { $0.width * $1 }
        let places = Self.seamLayout(
            of: sizes, splits: splits, totalWidth: totalWidth, seamAt: seam)
        for (index, layers) in parts.enumerated() {
            layers.head.frame = places[index].head
            layers.fill.frame = places[index].fill
            layers.tail.frame = places[index].tail
        }
        seamLineLayer.frame = Self.seamLine(of: sizes, seamAt: seam)
    }

    func addButtonsPatch(over index: Int) {
        let picture = pictures[index]
        let patch = Self.buttonsPatch(ofPictureSize: picture.size)
        let layer = StandInPanel.stillLayer()
        layer.contents = picture.image
        layer.contentsGravity = .resize
        layer.contentsRect = patch.part
        layer.frame = patch.frame
        slots[index].addSublayer(layer)
    }

    /// Shows a live frame in place of the picture.
    func show(_ surface: IOSurfaceRef, rect: CGRect, scale: Double, at index: Int) {
        guard images.indices.contains(index), rect.width > 0 else { return }
        let size = CGSize(width: IOSurfaceGetWidth(surface), height: IOSurfaceGetHeight(surface))
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        images[index].contents = surface
        images[index].contentsRect = Self.share(of: rect, scale: scale, inSurface: size)
        layOutSeam()
        CATransaction.commit()
    }

    /// Live frames get room for the pair's whole width, as a window can grow to about that.
    func showForSeam(at origin: ScreenPoint) {
        move(to: origin)
        panel.orderFrontRegardless()
        prepareForSeam()
        for (index, stream) in streams.enumerated() where pictures.indices.contains(index) {
            let picture = pictures[index]
            let scale = CGFloat(picture.image.width) / picture.size.width
            addButtonsPatch(over: index)
            stream.picture.onFrame = { [weak self] surface, rect, frameScale in
                self?.show(surface, rect: rect, scale: frameScale, at: index)
            }
            stream.start(
                room: CGSize(
                    width: totalWidth * scale, height: picture.size.height * scale))
        }
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
