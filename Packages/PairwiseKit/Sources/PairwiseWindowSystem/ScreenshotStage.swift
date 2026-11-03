#if DEBUG

import AppKit
import ScreenCaptureKit

/// Why the page's pictures could not be made.
struct ScreenshotFailure: Error, CustomStringConvertible {
    let description: String
}

/// Where the page's pictures are taken (ADR 0065): a backdrop of its own over the desktop, a strip
/// with Pairwise's icon over the status items, and a capture of the main display that holds only
/// the menu bar, these windows and the apps it names.
@MainActor
final class ScreenshotStage {
    /// Light and dark colours, as the windows and the menu bar follow the system.
    private static let lightBackdrop = (
        top: NSColor(red: 0.80, green: 0.87, blue: 0.95, alpha: 1),
        bottom: NSColor(red: 0.58, green: 0.69, blue: 0.84, alpha: 1)
    )
    /// The menu bar is see-through, so on a plain backdrop it would not read as a bar.
    private static let lightBar = (
        fill: NSColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1),
        line: NSColor(white: 0, alpha: 0.18)
    )
    private static let darkBar = (
        fill: NSColor(red: 0.10, green: 0.11, blue: 0.14, alpha: 1),
        line: NSColor(white: 1, alpha: 0.18)
    )
    private static let barLine = 1.0
    private static let iconName = "MenuBarIcon"
    private static let iconSize = 18.0
    private static let networkIconName = "wifi"
    private static let networkIconPointSize = 14.0
    /// A fixed time, without a date, so the pictures stay the same and do not age.
    private static let clockText = "Mon 9:41"
    /// How far the clock lies from the picture's right edge, and what lies between the items.
    private static let barInset = 14.0
    private static let barSpacing = 16.0
    /// The width at the screen's right edge left out of a picture. macOS draws its purple dot
    /// there after a capture, above every window, so only leaving it out keeps it away.
    static let rightEdgeLeftOut = 40.0
    private static let darkBackdrop = (
        top: NSColor(red: 0.20, green: 0.25, blue: 0.33, alpha: 1),
        bottom: NSColor(red: 0.09, green: 0.12, blue: 0.18, alpha: 1)
    )

    /// The screen with the menu bar, in points from its top left.
    let bounds: CGRect
    let menuBarHeight: Double
    private let scale: Double
    private let folder: URL
    private let keptApps: Set<String>
    private let stripColour: NSColor
    private let backdrop: NSWindow
    private var strip: NSWindow?

    /// Pictures go in `folder`, and only the apps in `keptApps` and this one show.
    init(folder: URL, keptApps: Set<String>) throws {
        guard let screen = NSScreen.screens.first else {
            throw ScreenshotFailure(description: "there is no screen")
        }
        bounds = CGRect(origin: .zero, size: screen.frame.size)
        menuBarHeight = screen.frame.maxY - screen.visibleFrame.maxY
        scale = screen.backingScaleFactor
        self.folder = folder
        self.keptApps = keptApps.union([Bundle.main.bundleIdentifier].compactMap { $0 })
        backdrop = NSWindow(
            contentRect: screen.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        backdrop.isReleasedWhenClosed = false
        backdrop.ignoresMouseEvents = true
        // Under every normal window, so it is never the window on top at a press.
        backdrop.level = NSWindow.Level(NSWindow.Level.normal.rawValue - 1)
        let gradient = CAGradientLayer()
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        let colours = isDark ? Self.darkBackdrop : Self.lightBackdrop
        let bar = isDark ? Self.darkBar : Self.lightBar
        stripColour = bar.fill
        gradient.colors = [colours.bottom.cgColor, colours.top.cgColor]
        gradient.frame = CGRect(origin: .zero, size: screen.frame.size)
        let view = NSView(frame: gradient.frame)
        view.wantsLayer = true
        view.layer = gradient
        let top = screen.frame.height - menuBarHeight
        view.addSubview(
            Self.plane(
                CGRect(x: 0, y: top, width: screen.frame.width, height: menuBarHeight), bar.fill))
        view.addSubview(
            Self.plane(
                CGRect(
                    x: 0, y: top - Self.barLine, width: screen.frame.width, height: Self.barLine),
                bar.line))
        backdrop.contentView = view
        backdrop.setFrame(screen.frame, display: true)
        backdrop.orderFrontRegardless()
        try coverStatusItems(on: screen)
    }

    private static func plane(_ frame: CGRect, _ colour: NSColor) -> NSView {
        let view = NSView(frame: frame)
        view.wantsLayer = true
        view.layer?.backgroundColor = colour.cgColor
        return view
    }

    func close() {
        backdrop.close()
        strip?.close()
    }

    /// Covers the right half of the menu bar, where the app menus do not come, and shows Pairwise's
    /// icon there, with a network icon and a clock. Where the real icon is depends on the Mac: a
    /// tool can hide it, or a notch. Only the strip's own items show, so nothing of this Mac does.
    private func coverStatusItems(on screen: NSScreen) throws {
        guard let icon = NSImage(named: Self.iconName),
            let network = NSImage(
                systemSymbolName: Self.networkIconName, accessibilityDescription: nil)?
                .withSymbolConfiguration(
                    .init(pointSize: Self.networkIconPointSize, weight: .regular))
        else { throw ScreenshotFailure(description: "the menu bar's icons are not on this Mac") }
        icon.isTemplate = true
        let frame = CGRect(
            x: screen.frame.midX, y: screen.frame.maxY - menuBarHeight,
            width: screen.frame.width / 2, height: menuBarHeight)
        let strip = NSWindow(
            contentRect: frame, styleMask: [.borderless], backing: .buffered, defer: false)
        strip.isReleasedWhenClosed = false
        strip.ignoresMouseEvents = true
        strip.level = .popUpMenu
        strip.backgroundColor = stripColour
        strip.setFrame(frame, display: true)
        let clock = NSTextField(labelWithString: Self.clockText)
        clock.font = .menuBarFont(ofSize: 0)
        clock.textColor = .labelColor
        let iconView = NSImageView(image: icon)
        iconView.setFrameSize(CGSize(width: Self.iconSize, height: Self.iconSize))
        let networkView = NSImageView(image: network)
        for view in [iconView, networkView] { view.contentTintColor = .labelColor }
        // From right to left, each in the middle of the bar's height.
        var right = frame.width - Self.rightEdgeLeftOut - Self.barInset
        for view in [clock, networkView, iconView] {
            let size = view === iconView ? iconView.frame.size : view.fittingSize
            view.frame = CGRect(
                x: right - size.width, y: (menuBarHeight - size.height) / 2,
                width: size.width, height: size.height)
            strip.contentView?.addSubview(view)
            right -= size.width + Self.barSpacing
        }
        strip.orderFrontRegardless()
        self.strip = strip
    }

    /// Saves `area` of the main display as `name`.png, and says at what scale.
    /// Precondition: `area` lies within `bounds`.
    func capture(_ name: String, area: CGRect) async throws -> String {
        precondition(bounds.contains(area), "A picture lies within the screen.")
        let content = try await SCShareableContent.excludingDesktopWindows(
            false, onScreenWindowsOnly: true)
        guard let display = content.displays.first(where: { $0.displayID == CGMainDisplayID() })
        else { throw ScreenshotFailure(description: "the main display is not on offer") }
        let left = content.applications.filter { !keptApps.contains($0.bundleIdentifier) }
        let configuration = SCStreamConfiguration()
        configuration.sourceRect = area
        configuration.width = Int(area.width * scale)
        configuration.height = Int(area.height * scale)
        configuration.showsCursor = true
        let image = try await SCScreenshotManager.captureImage(
            contentFilter: SCContentFilter(
                display: display, excludingApplications: left, exceptingWindows: []),
            configuration: configuration)
        let file = folder.appendingPathComponent(name).appendingPathExtension("png")
        guard
            let destination = CGImageDestinationCreateWithURL(
                file as CFURL, "public.png" as CFString, 1, nil)
        else { throw ScreenshotFailure(description: "\(name) cannot be written") }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw ScreenshotFailure(description: "\(name) cannot be written")
        }
        return "\(name): scale \(scale)"
    }
}

#endif
