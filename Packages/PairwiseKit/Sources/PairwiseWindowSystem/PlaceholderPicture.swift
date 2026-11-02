import AppKit

/// A picture of a window that captures nothing: an empty plane with a title bar holding the
/// app's icon and the window's title (on trial, plan M3a). It stands in for what a capture
/// would show, so that it goes through the same panel.
@MainActor
enum PlaceholderPicture {
    private static let cornerRadius: CGFloat = 10
    private static let titleBarHeight: CGFloat = 28
    private static let iconSize: CGFloat = 16
    /// Where the icon starts, past where a window's buttons are.
    private static let iconInset: CGFloat = 76
    private static let iconGap: CGFloat = 6
    private static let trailingInset: CGFloat = 12
    private static let titleFontSize: CGFloat = 13
    private static let darkPlane = NSColor(white: 0.14, alpha: 1)
    private static let darkBar = NSColor(white: 0.21, alpha: 1)
    private static let lightPlane = NSColor(white: 0.96, alpha: 1)
    private static let lightBar = NSColor(white: 0.88, alpha: 1)

    /// The picture for a window of `size` points, at `scale` pixels a point, or `nil` when
    /// no bitmap of that size can be made.
    static func make(
        title: String, icon: NSImage?, size: CGSize, scale: CGFloat, isDark: Bool
    ) -> StandInPanel.Picture? {
        guard
            let space = CGColorSpace(name: CGColorSpace.sRGB),
            let context = CGContext(
                data: nil, width: Int(size.width * scale), height: Int(size.height * scale),
                bitsPerComponent: 8, bytesPerRow: 0, space: space,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { return nil }
        context.scaleBy(x: scale, y: scale)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
        draw(title: title, icon: icon, size: size, isDark: isDark)
        NSGraphicsContext.restoreGraphicsState()
        return context.makeImage().map { StandInPanel.Picture(image: $0, size: size) }
    }

    private static func draw(title: String, icon: NSImage?, size: CGSize, isDark: Bool) {
        let bounds = CGRect(origin: .zero, size: size)
        NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius).setClip()
        (isDark ? darkPlane : lightPlane).setFill()
        bounds.fill()
        let bar = CGRect(
            x: 0, y: size.height - titleBarHeight, width: size.width, height: titleBarHeight)
        (isDark ? darkBar : lightBar).setFill()
        bar.fill()
        let iconRect = CGRect(
            x: iconInset, y: bar.midY - iconSize / 2, width: iconSize, height: iconSize)
        icon?.draw(in: iconRect)
        drawTitle(title, after: iconRect, in: bar, isDark: isDark)
    }

    private static func drawTitle(_ title: String, after icon: CGRect, in bar: CGRect, isDark: Bool)
    {
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail
        let font = NSFont.titleBarFont(ofSize: titleFontSize)
        let text = NSAttributedString(
            string: title,
            attributes: [
                .font: font, .paragraphStyle: style,
                .foregroundColor: isDark ? NSColor.white : NSColor.black,
            ])
        let lineHeight = ceil(font.ascender - font.descender + font.leading)
        let start = icon.maxX + iconGap
        text.draw(
            in: CGRect(
                x: start, y: bar.midY - lineHeight / 2,
                width: max(0, bar.width - start - trailingInset), height: lineHeight))
    }
}
