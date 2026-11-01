/// Where the pointer holds a dragged window: the distance from the window's top left
/// corner to the pointer, kept from the start of the drag.
public struct DragGrip: Equatable, Sendable {
    private let offsetX: Double
    private let offsetY: Double

    public init(pointer: ScreenPoint, windowOrigin: ScreenPoint) {
        offsetX = pointer.x - windowOrigin.x
        offsetY = pointer.y - windowOrigin.y
    }

    /// The dragged window's top left corner when the pointer is at `pointer`.
    public func windowOrigin(forPointer pointer: ScreenPoint) -> ScreenPoint {
        ScreenPoint(x: pointer.x - offsetX, y: pointer.y - offsetY)
    }
}
