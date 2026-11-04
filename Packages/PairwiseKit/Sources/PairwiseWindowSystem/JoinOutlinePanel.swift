import AppKit
import PairwiseCore

/// An amber outline above other windows, around the window a dragged window would join, also
/// when that window lies hidden (ADR 0069). It takes neither focus nor clicks.
@MainActor
final class JoinOutlinePanel: ScreenMark {
    private static let lineWidth = 3.0
    /// About the corners of a window on macOS 15; a little off on another version does no harm.
    private static let cornerRadius = 10.0

    private let panel: NSPanel

    init() {
        panel = NSPanel(
            contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered,
            defer: false)
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.level = .floating
        panel.collectionBehavior = [.transient, .ignoresCycle, .fullScreenAuxiliary]
        let view = NSView()
        view.wantsLayer = true
        view.layer?.borderColor = SeamColour.amber.cgColor
        view.layer?.borderWidth = Self.lineWidth
        view.layer?.cornerRadius = Self.cornerRadius
        panel.contentView = view
    }

    /// Shows the outline around `frame`, or moves it there.
    func show(at frame: WindowFrame) {
        panel.setFrame(NSScreen.appKitFrame(frame), display: true)
        panel.orderFrontRegardless()
    }

    /// Takes the outline off the screen.
    func hide() {
        panel.close()
    }
}
