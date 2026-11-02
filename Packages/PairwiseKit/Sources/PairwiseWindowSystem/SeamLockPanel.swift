import AppKit
import PairwiseCore

/// A small lock above other windows: closed in the amber of the app's seam, and open in a
/// quiet grey (ADR 0044). It takes neither focus nor clicks: the tap sees a press on its
/// place first.
@MainActor
final class SeamLockPanel: SeamLockMark {
    private static let colour = SeamColour.amber
    private static let openColour = NSColor(white: 0.88, alpha: 1)
    private static let symbolColour = NSColor(white: 0.1, alpha: 1)
    private static let symbolSize = 13.0
    private static let closedSymbol = "lock.fill"
    private static let openSymbol = "lock.open.fill"

    let panel: NSPanel
    private let symbol = NSImageView()

    init() {
        panel = NSPanel(
            contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered,
            defer: false)
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = true
        // Above the guide's level, which the join test tells apart by level.
        panel.level = .modalPanel
        panel.collectionBehavior = [.transient, .ignoresCycle, .fullScreenAuxiliary]
        let background = NSView()
        background.wantsLayer = true
        symbol.contentTintColor = Self.symbolColour
        symbol.symbolConfiguration = .init(pointSize: Self.symbolSize, weight: .semibold)
        symbol.imageAlignment = .alignCenter
        symbol.autoresizingMask = [.width, .height]
        background.addSubview(symbol)
        panel.contentView = background
    }

    /// Shows the lock over `frame`, or moves or changes it there.
    func show(at frame: WindowFrame, isClosed: Bool) {
        symbol.image = NSImage(
            systemSymbolName: isClosed ? Self.closedSymbol : Self.openSymbol,
            accessibilityDescription: nil)
        panel.setFrame(NSScreen.appKitFrame(frame), display: false)
        let content = panel.contentView
        symbol.frame = content?.bounds ?? .zero
        content?.layer?.cornerRadius = frame.size.width / 2
        content?.layer?.backgroundColor = (isClosed ? Self.colour : Self.openColour).cgColor
        panel.invalidateShadow()
        panel.orderFrontRegardless()
    }

    /// Takes the lock off the screen.
    func hide() {
        panel.close()
    }
}
