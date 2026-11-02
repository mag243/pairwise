import AppKit

/// A placeholder as layers, for a seam: only their places change as the window's width does, as
/// drawing a picture anew at every move of the pointer is too slow (on trial, plan M3a).
@MainActor
final class PlaceholderLayers {
    /// The layer to add to the panel, which holds all the others.
    let root = StandInPanel.stillLayer()
    private let bar = StandInPanel.stillLayer()
    private let barIcon = StandInPanel.stillLayer()
    private let bodyIcon = StandInPanel.stillLayer()
    private let buttons = PlaceholderPicture.buttonColours.map { colour in
        let layer = StandInPanel.stillLayer()
        layer.backgroundColor = colour.cgColor
        layer.cornerRadius = PlaceholderPicture.buttonDiameter / 2
        return layer
    }
    private let title = CATextLayer()

    init(title text: String, icon: NSImage?, scale: CGFloat, isDark: Bool) {
        root.backgroundColor =
            (isDark ? PlaceholderPicture.darkPlane : PlaceholderPicture.lightPlane).cgColor
        root.cornerRadius = PlaceholderPicture.cornerRadius
        root.masksToBounds = true
        bar.backgroundColor = PlaceholderPicture.barColour(isDark: isDark).cgColor
        barIcon.contents = icon
        bodyIcon.contents = icon
        bodyIcon.contentsGravity = .resizeAspect
        barIcon.contentsGravity = .resizeAspect
        title.string = text
        title.font = PlaceholderPicture.titleFont
        title.fontSize = PlaceholderPicture.titleFontSize
        title.foregroundColor = (isDark ? NSColor.white : NSColor.black).cgColor
        title.truncationMode = .end
        title.contentsScale = scale
        title.actions = StandInPanel.stillLayer().actions
        for layer in [bar, bodyIcon] + buttons + [barIcon, title] {
            root.addSublayer(layer)
        }
    }

    /// Puts everything in its place for a window of `size`. A layer's origin is at its bottom left.
    func layOut(size: CGSize) {
        root.frame = CGRect(origin: .zero, size: size)
        let places = PlaceholderPicture.places(for: size)
        bar.frame = places.bar
        barIcon.frame = places.barIcon
        title.frame = places.title
        bodyIcon.frame = places.bodyIcon ?? .zero
        for (layer, place) in zip(buttons, places.buttons) {
            layer.frame = place
        }
    }
}
