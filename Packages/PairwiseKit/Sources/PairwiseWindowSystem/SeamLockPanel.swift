import AppKit
import PairwiseCore

/// A small lock above other windows, in the amber of the app's seam (ADR 0042). It takes
/// neither focus nor clicks: the tap sees a press on its place first.
@MainActor
final class SeamLockPanel: SeamLockMark {
    private static let colour = NSColor(srgbRed: 0.96, green: 0.65, blue: 0.14, alpha: 1)
    private static let symbolColour = NSColor(white: 0.1, alpha: 1)
    private static let symbolSize = 13.0
    private static let closedSymbol = "lock.fill"
    private static let openSymbol = "lock.open.fill"

    private let panel: NSPanel
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
        background.layer?.backgroundColor = Self.colour.cgColor
        symbol.contentTintColor = Self.symbolColour
        symbol.symbolConfiguration = .init(pointSize: Self.symbolSize, weight: .semibold)
        symbol.imageAlignment = .alignCenter
        symbol.autoresizingMask = [.width, .height]
        background.addSubview(symbol)
        panel.contentView = background
    }

    /// Shows the closed lock over `frame`, or moves it there.
    func showClosed(at frame: WindowFrame) {
        show(Self.closedSymbol, at: frame)
    }

    /// Shows the open lock over `frame`.
    func showOpen(at frame: WindowFrame) {
        show(Self.openSymbol, at: frame)
    }

    /// Takes the lock off the screen.
    func hide() {
        panel.close()
    }

    private func show(_ name: String, at frame: WindowFrame) {
        symbol.image = NSImage(systemSymbolName: name, accessibilityDescription: nil)
        panel.setFrame(NSScreen.appKitFrame(frame), display: false)
        let content = panel.contentView
        symbol.frame = content?.bounds ?? .zero
        content?.layer?.cornerRadius = frame.size.width / 2
        panel.invalidateShadow()
        panel.orderFrontRegardless()
    }
}
