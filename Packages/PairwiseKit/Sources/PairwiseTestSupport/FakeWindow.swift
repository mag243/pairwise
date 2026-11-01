import PairwiseCore

/// A window in memory, which records where it was moved.
@MainActor
public final class FakeWindow: MovableWindow {
    public var currentFrame: WindowFrame
    /// What `serverFrame()` gives; without one the window server does not tell.
    public var currentServerFrame: WindowFrame?
    public private(set) var moves: [ScreenPoint] = []
    /// When set, reading the frame throws this.
    public var frameError: WindowSystemError?
    /// When set, moving throws this and the window stays where it is.
    public var moveError: WindowSystemError?
    public private(set) var raises = 0
    /// When set, raising throws this.
    public var raiseError: WindowSystemError?
    /// Runs during each raise, to let a test see what stands at that moment.
    public var duringRaise: (() -> Void)?
    /// Runs during each move, to let a test advance time or the pointer.
    public var duringMove: (() -> Void)?

    public init(frame: WindowFrame) {
        currentFrame = frame
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

    public func raise() throws(WindowSystemError) {
        if let raiseError { throw raiseError }
        raises += 1
        duringRaise?()
    }
}
