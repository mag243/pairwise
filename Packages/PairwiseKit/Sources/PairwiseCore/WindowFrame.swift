/// A window's place and size in global screen coordinates (see `ScreenPoint`).
public struct WindowFrame: Equatable, Sendable {
    public var origin: ScreenPoint
    public var size: WindowSize

    public init(origin: ScreenPoint, size: WindowSize) {
        self.origin = origin
        self.size = size
    }

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.init(origin: ScreenPoint(x: x, y: y), size: WindowSize(width: width, height: height))
    }

    /// Whether `point` is on the window, its edges included.
    public func contains(_ point: ScreenPoint) -> Bool {
        point.x >= origin.x && point.x <= maxX && point.y >= origin.y && point.y <= maxY
    }

    /// The x of the window's right edge.
    public var maxX: Double { origin.x + size.width }

    /// The y of the window's bottom edge.
    public var maxY: Double { origin.y + size.height }
}
