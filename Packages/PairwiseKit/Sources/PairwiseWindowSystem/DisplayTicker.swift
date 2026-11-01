import AppKit
import QuartzCore

/// Calls its handler once per frame of the main display, on the main run loop (ADR 0021).
@MainActor
final class DisplayTicker: NSObject {
    private let handler: @MainActor () -> Void
    private var link: CADisplayLink?

    /// Fails when there is no main display to follow.
    init?(handler: @escaping @MainActor () -> Void) {
        guard let screen = NSScreen.main else { return nil }
        self.handler = handler
        super.init()
        let link = screen.displayLink(target: self, selector: #selector(fire))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    /// Ends the ticking and releases the display link, which holds on to this object.
    func stop() {
        link?.invalidate()
        link = nil
    }

    @objc private func fire() {
        handler()
    }
}
