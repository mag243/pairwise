import AppKit
import PairwiseCore

/// Where everything goes in the panel for a seam (ADR 0048, 0049).
extension StandInPanel {
    /// The width of the amber line on a seam while it moves, in points.
    static let seamLineWidth: CGFloat = 6

    /// The top left of a window, in points, that holds its close, minimize and zoom buttons.
    static let buttonsArea = CGSize(width: 92, height: 52)

    /// How many rows of a picture one row of its sample stands for.
    static let rowsPerSample = 4

    /// Where two pictures go with the seam at `seam` from the left, each divided at its place
    /// in `splits` and keeping both edges. The panel's width does not change.
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

    static func place(
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

    /// One value per point across, and fewer rows than that, which is enough to see text.
    static func quietSplit(of picture: Picture) -> CGFloat {
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

    /// Where the amber line goes: on the seam, as long as the shorter window, tops level.
    static func seamLine(of sizes: [CGSize], seamAt seam: CGFloat) -> CGRect {
        let heights = sizes.map(\.height)
        let tallest = heights.max() ?? 0
        let shortest = heights.min() ?? 0
        return CGRect(
            x: seam - seamLineWidth / 2, y: tallest - shortest, width: seamLineWidth,
            height: shortest)
    }

    /// Where a live frame goes: all of it in its slot, scaled to fit. It differs little from
    /// the slot, as the window follows the seam, so nothing shows of the scaling, where any
    /// division would show as a line through the content, also with a still pointer as an app
    /// can round its width (ADR 0049).
    static func liveLayout(
        of sizes: [CGSize], totalWidth: CGFloat, seamAt seam: CGFloat
    ) -> [(slot: CGRect, frame: CGRect)] {
        seamLayout(of: sizes, splits: [0, 0], totalWidth: totalWidth, seamAt: seam).map { place in
            (place.slot, CGRect(origin: .zero, size: place.slot.size))
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

    /// The part of a surface that `rect`, in points at `scale`, takes up, as a share of it.
    static func share(of rect: CGRect, scale: Double, inSurface surface: CGSize) -> CGRect {
        CGRect(
            x: rect.origin.x * scale / surface.width, y: rect.origin.y * scale / surface.height,
            width: rect.width * scale / surface.width,
            height: rect.height * scale / surface.height)
    }
}
