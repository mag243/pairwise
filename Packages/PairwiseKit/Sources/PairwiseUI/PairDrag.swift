import Foundation
import PairwiseCore

/// Where a drag taken over by `PairDragModel` stands (ADR 0024).
@MainActor
enum PairDrag {
    case none
    /// The events pass: nothing is taken over, until the next press.
    case passing
    case pressed(Pressed)
    case moving(Moving)
    case placing(Placing)
    /// Both windows are placed; the panel stays until they have had time to draw.
    case settling(standIn: any WindowStandIn, until: TimeInterval)

    @MainActor
    struct Pressed {
        let window: any MovableWindow
        let partner: any MovableWindow
        let startTime: TimeInterval
        /// The window's frame at the press. macOS keeps a window at this distance from the
        /// pointer, so this and `pointer` tell where it belongs, also while it lags behind.
        let frame: WindowFrame
        /// The pointer's place at the press.
        let pointer: ScreenPoint
        var standIn: (any WindowStandIn)?
        var hasWindowMoved = false
        var lastPointer: ScreenPoint
    }

    @MainActor
    struct Moving {
        let window: any MovableWindow
        let partner: any MovableWindow
        let standIn: any WindowStandIn
        let frame: WindowFrame
        let pointer: ScreenPoint
        let startTime: TimeInterval
        let panelDelay: TimeInterval
        var lastPointer: ScreenPoint
        var isWindowParked = false
        var isPartnerParked = false

        func origin(forPointer point: ScreenPoint) -> ScreenPoint {
            ScreenPoint(
                x: frame.origin.x + point.x - pointer.x, y: frame.origin.y + point.y - pointer.y)
        }
    }

    @MainActor
    struct Placing {
        let window: any MovableWindow
        let partner: any MovableWindow
        let standIn: any WindowStandIn
        let target: ScreenPoint
        let size: WindowSize
        let deadline: TimeInterval
        var isWindowPlaced = false
    }
}
