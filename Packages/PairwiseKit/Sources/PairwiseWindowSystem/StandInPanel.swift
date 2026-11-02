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
    private struct SeamLayers {
        let head = CALayer()
        let fill = CALayer()
        let tail = CALayer()
    }

    /// The top left of a window, in points, that holds its close, minimize and zoom buttons.
    private static let buttonsArea = CGSize(width: 92, height: 52)

    /// How many rows of a picture one row of its sample stands for.
    private static let rowsPerSample = 4

    private let panel: NSPanel
    private let streams: [LiveStream]
    private let pictures: [Picture]
    /// A layer per picture that cuts it off at the seam, the layer with the whole picture, and
    /// the layers that show its parts once a seam has been set.
    private var slots: [CALayer] = []
    private var images: [CALayer] = []
    private var parts: [SeamLayers] = []
    /// Where each picture divides, as a share of its width, found at the first seam.
    private var splitShares: [CGFloat] = []
    /// The size of what each picture shows now, which a live frame can change.
    private var shownSizes: [CGSize] = []
    private var seam: CGFloat?
    private var totalWidth: CGFloat { pictures.map(\.size.width).reduce(0, +) }

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

    /// Where two pictures go with the seam at `seam` from the left, each divided at its place
    /// in `splits` and keeping both edges. The panel's width does not change, and `sizes` can be
    /// those of live frames, whose widths need not add up to it.
    static func seamLayout(
        of sizes: [CGSize], splits: [CGFloat], totalWidth: CGFloat, seamAt seam: CGFloat
    ) -> [SeamPlace] {
        guard sizes.count == 2, splits.count == 2 else { return [] }
        let (left, right) = (sizes[0], sizes[1])
        let height = max(left.height, right.height)
        let rightWidth = totalWidth - seam
        return [
            place(
                of: left, split: splits[0],
                inSlot: CGRect(x: 0, y: height - left.height, width: seam, height: left.height)),
            place(
                of: right, split: splits[1],
                inSlot: CGRect(
                    x: seam, y: height - right.height, width: rightWidth, height: right.height)),
        ]
    }

    private static func place(
        of size: CGSize, split: CGFloat, inSlot slot: CGRect
    ) -> SeamPlace {
        let tailWidth = size.width - split
        return SeamPlace(
            slot: slot,
            head: CGRect(x: 0, y: 0, width: split, height: size.height),
            fill: CGRect(
                x: split, y: 0, width: max(slot.width - size.width, 0), height: size.height),
            tail: CGRect(
                x: slot.width - tailWidth, y: 0, width: tailWidth, height: size.height))
    }

    /// The part of a picture that fills the room in a wider window, as a share of the picture:
    /// one column at its split, stretched.
    static func fillColumn(ofPictureWidth width: CGFloat, atSplit split: CGFloat) -> CGRect {
        CGRect(x: split / width, y: 0, width: 1 / width, height: 1)
    }

    /// Reads the picture once, at the first seam, as a press that only moves needs none of this.
    private func prepareForSeam() {
        guard parts.isEmpty else { return }
        shownSizes = pictures.map(\.size)
        for (index, picture) in pictures.enumerated() {
            let split = Self.quietSplit(of: picture)
            splitShares.append(split / picture.size.width)
            parts.append(Self.seamLayers(of: picture, split: split, in: slots[index]))
            images[index].isHidden = true
        }
    }

    /// One value per point across, and fewer rows than that, which is enough to see text.
    private static func quietSplit(of picture: Picture) -> CGFloat {
        let width = Int(picture.size.width)
        let height = max(Int(picture.size.height) / rowsPerSample, 1)
        guard
            width > 0,
            let context = CGContext(
                data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width,
                space: CGColorSpaceCreateDeviceGray(),
                bitmapInfo: CGImageAlphaInfo.none.rawValue),
            let data = context.data
        else { return picture.size.width / 2 }
        context.interpolationQuality = .none
        context.draw(picture.image, in: CGRect(x: 0, y: 0, width: width, height: height))
        let gray = Array(
            UnsafeBufferPointer(
                start: data.assumingMemoryBound(to: UInt8.self), count: width * height))
        return CGFloat(QuietColumn.index(inGray: gray, width: width, height: height))
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
        let splits = zip(shownSizes, splitShares).map { $0.width * $1 }
        let places = Self.seamLayout(
            of: shownSizes, splits: splits, totalWidth: totalWidth, seamAt: seam)
        for (index, place) in places.enumerated() {
            slots[index].frame = place.slot
            let layers = parts[index]
            layers.head.frame = place.head
            layers.fill.frame = place.fill
            layers.tail.frame = place.tail
        }
    }

    /// Where the still picture's buttons go over live frames, and the part of the picture that
    /// holds them. macOS shows a mark of its own there in the frames of a window it streams
    /// (ADR 0049).
    static func buttonsPatch(ofPictureSize size: CGSize) -> (frame: CGRect, part: CGRect) {
        let area = buttonsArea
        let height = area.height / size.height
        // A layer's contents count from the bottom, as its place does.
        return (
            CGRect(x: 0, y: size.height - area.height, width: area.width, height: area.height),
            CGRect(x: 0, y: 1 - height, width: area.width / size.width, height: height)
        )
    }

    private func addButtonsPatch(over index: Int) {
        let picture = pictures[index]
        let patch = Self.buttonsPatch(ofPictureSize: picture.size)
        let layer = CALayer()
        layer.contents = picture.image
        layer.contentsGravity = .resize
        layer.contentsRect = patch.part
        layer.frame = patch.frame
        slots[index].addSublayer(layer)
    }

    /// The part of a surface that `rect`, in points at `scale`, takes up, as a share of it.
    static func share(of rect: CGRect, scale: Double, inSurface surface: CGSize) -> CGRect {
        CGRect(
            x: rect.origin.x * scale / surface.width, y: rect.origin.y * scale / surface.height,
            width: rect.width * scale / surface.width,
            height: rect.height * scale / surface.height)
    }

    /// Shows a live frame through the same division as the picture, at its own width.
    private func show(_ surface: IOSurfaceRef, rect: CGRect, scale: Double, at index: Int) {
        guard parts.indices.contains(index), rect.width > 0 else { return }
        let size = CGSize(width: IOSurfaceGetWidth(surface), height: IOSurfaceGetHeight(surface))
        let part = Self.share(of: rect, scale: scale, inSurface: size)
        let head = part.width * splitShares[index]
        let layers = parts[index]
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for layer in [layers.head, layers.fill, layers.tail] { layer.contents = surface }
        layers.head.contentsRect = CGRect(
            x: part.minX, y: part.minY, width: head, height: part.height)
        layers.fill.contentsRect = CGRect(
            x: part.minX + head, y: part.minY, width: part.width / rect.width, height: part.height)
        layers.tail.contentsRect = CGRect(
            x: part.minX + head, y: part.minY, width: part.width - head, height: part.height)
        shownSizes[index] = rect.size
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
