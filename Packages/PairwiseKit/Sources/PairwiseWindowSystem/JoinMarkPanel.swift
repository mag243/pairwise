import AppKit
import PairwiseCore

/// A coloured area above other windows, in the amber of the app's seam: the guide of where a
/// window will land, and a seam that lights up (ADR 0035). It takes neither focus nor clicks.
@MainActor
final class JoinMarkPanel {
    private static let colour = NSColor(srgbRed: 0.96, green: 0.65, blue: 0.14, alpha: 1)
    private static let fillOpacity = 0.3

    private let panel: NSPanel

    init() {
        panel = NSPanel(
            contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered,
            defer: false)
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = Self.colour.withAlphaComponent(Self.fillOpacity)
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.level = .floating
        panel.collectionBehavior = [.transient, .ignoresCycle, .fullScreenAuxiliary]
    }

    /// Shows the mark over `frame`, or moves it there.
    func show(at frame: WindowFrame) {
        panel.setFrame(NSScreen.appKitFrame(frame), display: true)
        panel.orderFrontRegardless()
    }

    /// Takes the mark off the screen.
    func hide() {
        panel.close()
    }
}
