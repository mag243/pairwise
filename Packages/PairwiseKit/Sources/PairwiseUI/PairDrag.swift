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
    /// The join key is down: macOS drags the window alone, and it may join another at the release.
    case joining(Joining)
    case placing(Placing)
    /// Both windows are placed; the panel stays until they have had time to draw.
    case settling(standIn: any WindowStandIn, until: TimeInterval)

    @MainActor
    struct Pressed {
        let number: UInt32
        let window: any MovableWindow
        let partner: PairDrag.Partner
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
    struct Joining {
        let window: any MovableWindow
        let number: UInt32
        let frame: WindowFrame
        var pointer: ScreenPoint
        var isKeyDown = true
        /// Whether the window is to take the other's height.
        var isTakingHeight = false
        /// Set when the drag events are withheld, so that Pairwise moves the window (ADR 0040).
        var held: Held?
        var target: JoinTarget?
    }

    /// A window that Pairwise moves itself, as its drag events are withheld: it keeps its
    /// distance to the pointer from the press.
    @MainActor
    struct Held {
        let frame: WindowFrame
        let pointer: ScreenPoint
        var lastPlace: ScreenPoint?

        func origin(forPointer point: ScreenPoint) -> ScreenPoint {
            ScreenPoint(
                x: frame.origin.x + point.x - pointer.x, y: frame.origin.y + point.y - pointer.y)
        }
    }

    /// The other window of a pair.
    @MainActor
    struct Partner {
        let window: any MovableWindow
        let origin: ScreenPoint
        let size: WindowSize
        let side: PairSide
    }

    @MainActor
    struct Moving {
        let number: UInt32
        let window: any MovableWindow
        let partner: PairDrag.Partner
        let standIn: any WindowStandIn
        let frame: WindowFrame
        let pointer: ScreenPoint
        let startTime: TimeInterval
        let panelDelay: TimeInterval
        var lastPointer: ScreenPoint
        var isWindowParked = false
        /// The join key came during the drag: the next tick parts the pair (ADR 0040).
        var wantsParting = false
        var isPartnerParked = false

        /// Where the dragged window belongs for a pointer at `point`.
        func origin(forPointer point: ScreenPoint) -> ScreenPoint {
            ScreenPoint(
                x: frame.origin.x + point.x - pointer.x, y: frame.origin.y + point.y - pointer.y)
        }

        /// Where the panel goes: its origin is that of the pair's left window.
        func panelOrigin(forPointer point: ScreenPoint) -> ScreenPoint {
            let origin = origin(forPointer: point)
            return partner.side == .left
                ? ScreenPoint(x: origin.x - partner.size.width, y: origin.y) : origin
        }
    }

    @MainActor
    struct Placing {
        let window: any MovableWindow
        let partner: PairDrag.Partner
        let standIn: any WindowStandIn
        let target: ScreenPoint
        let size: WindowSize
        let deadline: TimeInterval
        var isWindowPlaced = false
    }
}
