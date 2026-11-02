import AppKit

/// A picture of a window that captures nothing: an empty plane with the app's icon, and a title
/// bar with a window's three buttons, the icon and the title (on trial, plan M3a).
@MainActor
enum PlaceholderPicture {
    /// Where the parts of a placeholder go, with the origin at its bottom left.
    struct Places {
        let bar: CGRect
        let barIcon: CGRect
        let title: CGRect
        let buttons: [CGRect]
        /// `nil` when the plane has no room for it.
        let bodyIcon: CGRect?
    }

    static let cornerRadius: CGFloat = 10
    static let buttonDiameter: CGFloat = 12
    static let titleFontSize: CGFloat = 13
    static let darkPlane = NSColor(white: 0.14, alpha: 1)
    static let lightPlane = NSColor(white: 0.96, alpha: 1)
    static let buttonColours = [
        NSColor(srgbRed: 1, green: 0.37, blue: 0.34, alpha: 1),
        NSColor(srgbRed: 1, green: 0.74, blue: 0.18, alpha: 1),
        NSColor(srgbRed: 0.16, green: 0.78, blue: 0.25, alpha: 1),
    ]
    static var titleFont: NSFont { .titleBarFont(ofSize: titleFontSize) }

    private static let titleBarHeight: CGFloat = 28
    private static let iconSize: CGFloat = 16
    /// Where the icon starts, past the buttons.
    private static let iconInset: CGFloat = 76
    private static let iconGap: CGFloat = 6
    private static let trailingInset: CGFloat = 12
    /// The middle of the first button from the window's left edge, and between buttons.
    private static let firstButtonX: CGFloat = 14
    private static let buttonSpacing: CGFloat = 20
    private static let bodyIconSize: CGFloat = 96
    private static let darkBar = NSColor(white: 0.21, alpha: 1)
    private static let lightBar = NSColor(white: 0.88, alpha: 1)

    static func barColour(isDark: Bool) -> NSColor { isDark ? darkBar : lightBar }

    /// Where the parts go in a window of `size`.
    static func places(for size: CGSize) -> Places {
        let bar = CGRect(
            x: 0, y: size.height - titleBarHeight, width: size.width, height: titleBarHeight)
        let barIcon = CGRect(
            x: iconInset, y: bar.midY - iconSize / 2, width: iconSize, height: iconSize)
        let lineHeight = ceil(titleFont.ascender - titleFont.descender + titleFont.leading)
        let titleStart = barIcon.maxX + iconGap
        let title = CGRect(
            x: titleStart, y: bar.midY - lineHeight / 2,
            width: max(0, bar.width - titleStart - trailingInset), height: lineHeight)
        let buttons = buttonColours.indices.map { index in
            CGRect(
                x: firstButtonX + CGFloat(index) * buttonSpacing - buttonDiameter / 2,
                y: bar.midY - buttonDiameter / 2, width: buttonDiameter, height: buttonDiameter)
        }
        let hasRoom = bar.minY >= bodyIconSize && bar.width >= bodyIconSize
        let bodyIcon = CGRect(
            x: bar.midX - bodyIconSize / 2, y: bar.minY / 2 - bodyIconSize / 2,
            width: bodyIconSize, height: bodyIconSize)
        return Places(
            bar: bar, barIcon: barIcon, title: title, buttons: buttons,
            bodyIcon: hasRoom ? bodyIcon : nil)
    }

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
        let places = places(for: size)
        NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius).setClip()
        (isDark ? darkPlane : lightPlane).setFill()
        bounds.fill()
        barColour(isDark: isDark).setFill()
        places.bar.fill()
        icon?.draw(in: places.barIcon)
        for (colour, place) in zip(buttonColours, places.buttons) {
            colour.setFill()
            NSBezierPath(ovalIn: place).fill()
        }
        if let bodyIcon = places.bodyIcon { icon?.draw(in: bodyIcon) }
        let style = NSMutableParagraphStyle()
        style.lineBreakMode = .byTruncatingTail
        NSAttributedString(
            string: title,
            attributes: [
                .font: titleFont, .paragraphStyle: style,
                .foregroundColor: isDark ? NSColor.white : NSColor.black,
            ]
        ).draw(in: places.title)
    }
}
