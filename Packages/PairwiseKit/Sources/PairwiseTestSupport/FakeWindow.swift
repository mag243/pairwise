import PairwiseCore

/// A window in memory, which records where it was moved.
@MainActor
public final class FakeWindow: MovableWindow {
    public var currentFrame: WindowFrame
    public var windowNumber: UInt32?
    /// The process that owns the window, as the window server tells it.
    public var owner: Int32 = 0
    public var isAvailable = true
    public var isMinimized = false
    /// The identifier of the window's app.
    public var appID: String?
    /// The hash of the window's title.
    public var titleKey: String?
    /// What the window was asked to become, in order.
    public private(set) var minimizeRequests: [Bool] = []
    /// What `serverFrame()` gives; without one the window server does not tell.
    public var currentServerFrame: WindowFrame?
    public private(set) var moves: [ScreenPoint] = []
    /// When set, reading the frame throws this.
    public var frameError: WindowSystemError?
    /// When set, moving throws this and the window stays where it is.
    public var moveError: WindowSystemError?
    public private(set) var raises = 0
    public private(set) var resizes: [WindowSize] = []
    /// When set, resizing throws this.
    public var resizeError: WindowSystemError?
    /// When set, a width asked for is rounded down to a multiple of this, as with an app that
    /// sizes in whole characters.
    public var widthStep: Double?
    /// When set, a width is kept from going below this, as an app does without saying so.
    public var minimumWidth: Double?
    /// When set, a width is kept from going above this, as an app does without saying so.
    public var maximumWidth: Double?
    /// When set, raising throws this.
    public var raiseError: WindowSystemError?
    /// Runs during each raise, to let a test see what stands at that moment.
    public var duringRaise: (() -> Void)?
    /// Runs during each move, to let a test advance time or the pointer.
    public var duringMove: (() -> Void)?

    public init(frame: WindowFrame, number: UInt32? = nil) {
        currentFrame = frame
        windowNumber = number
    }

    public func frame() throws(WindowSystemError) -> WindowFrame {
        if let frameError { throw frameError }
        return currentFrame
    }

    public func serverFrame() -> WindowFrame? {
        currentServerFrame
    }

    public func move(to origin: ScreenPoint) throws(WindowSystemError) {
        if let moveError { throw moveError }
        moves.append(origin)
        currentFrame.origin = origin
        duringMove?()
    }

    public func resize(to size: WindowSize) throws(WindowSystemError) {
        if let resizeError { throw resizeError }
        resizes.append(size)
        currentFrame.size = size
        if let widthStep {
            currentFrame.size.width = (size.width / widthStep).rounded(.down) * widthStep
        }
        if let minimumWidth { currentFrame.size.width = max(currentFrame.size.width, minimumWidth) }
        if let maximumWidth { currentFrame.size.width = min(currentFrame.size.width, maximumWidth) }
    }

    public func setMinimized(_ isMinimized: Bool) throws(WindowSystemError) {
        minimizeRequests.append(isMinimized)
        self.isMinimized = isMinimized
    }

    public func raise() throws(WindowSystemError) {
        if let raiseError { throw raiseError }
        raises += 1
        duringRaise?()
    }
}
