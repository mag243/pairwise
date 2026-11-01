import Foundation
import PairwiseCore
import os

/// Where a drag stands, from the press to the partner being back in place.
@MainActor
enum FollowDrag {
    case none
    case pressed(window: any MovableWindow, frame: WindowFrame, pointer: ScreenPoint)
    case following(Following)
    case placing(Placing)

    /// A drag that has been seen, with the partner or its stand-in going along.
    @MainActor
    struct Following {
        let window: any MovableWindow
        let partner: any MovableWindow
        let size: WindowSize
        let grip: DragGrip
        /// When the moves being measured began.
        var startTime: TimeInterval
        var standIn: (any WindowStandIn)?
        var standInDelay: TimeInterval?
        var isParked = false
        /// Where the partner or its stand-in was last sent.
        var lastTarget: ScreenPoint?

        /// Where the partner belongs: beside the window server's place of the dragged
        /// window, or from the pointer and the grip when the window server does not tell.
        func target(serverFrame: WindowFrame?, pointer: ScreenPoint?) -> ScreenPoint? {
            if let serverFrame {
                return PartnerPlacement.origin(besideWindowAt: serverFrame.origin, size: size)
            }
            return pointer.map(target(forPointer:))
        }

        /// Where the partner belongs for a pointer at `pointer`, without asking any app.
        func target(forPointer pointer: ScreenPoint) -> ScreenPoint {
            PartnerPlacement.origin(
                besideWindowAt: grip.windowOrigin(forPointer: pointer), size: size)
        }

        /// Where the partner belongs beside the dragged window's real frame.
        func placementFromRealFrame() throws(WindowSystemError) -> ScreenPoint {
            let frame = try window.liveFrame()
            return PartnerPlacement.origin(besideWindowAt: frame.origin, size: frame.size)
        }
    }

    /// The button is up, and a busy partner still has to go back to its place.
    @MainActor
    struct Placing {
        let partner: any MovableWindow
        let standIn: any WindowStandIn
        let target: ScreenPoint
        let deadline: TimeInterval
    }
}

extension MovableWindow {
    /// The window's frame from the window server, or from its app when the window server
    /// does not tell.
    func liveFrame() throws(WindowSystemError) -> WindowFrame {
        if let serverFrame = serverFrame() { return serverFrame }
        return try frame()
    }
}

extension FollowReport {
    /// Writes the measurements to `logger`; a negative number means it is not known.
    func log(to logger: Logger) {
        logger.info(
            """
            drag: \(moves) moves, \(movesPerSecond) per second, \
            mean \(meanMove) s, p95 \(percentile95Move) s, \
            longest \(longestMove) s, \
            behind mean \(meanPointsBehind), most \(mostPointsBehind), \
            stand-in after \(standInDelay ?? -1) s, slip \(mostSlip ?? -1)
            """)
    }
}
