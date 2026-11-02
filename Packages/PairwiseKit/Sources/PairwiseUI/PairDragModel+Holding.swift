import PairwiseCore

/// Which drag events are withheld (ADR 0024, 0032).
extension PairDragModel {
    func holdsDrag(
        at point: ScreenPoint, isJoinKeyDown: Bool, isEqualHeightKeyDown: Bool, isScopeKeyDown: Bool
    ) -> Bool {
        switch drag {
        case .none:
            if isJoinKeyDown { startJoiningFreeWindow(at: point) }
            return false
        case .passing, .placing, .settling, .closingLock:
            return false
        case .clickingLock:
            return true
        case .joining(var joining):
            joining.pointer = point
            joining.isKeyDown = isJoinKeyDown
            joining.isTakingHeight = isEqualHeightKeyDown
            joining.isScopeKeyDown = isScopeKeyDown
            drag = .joining(joining)
            return joining.held != nil
        case .pressed(var pressed):
            pressed.lastPointer = point
            drag = .pressed(pressed)
            if isJoinKeyDown { return part(pressed, at: point) }
            guard pressed.hasWindowMoved else { return false }
            let elapsed = system.uptime - pressed.startTime
            if pressed.standIn == nil, !DragHoldRule.mayWaitForPictures(after: elapsed) {
                Self.logger.info("pictures took too long: the drag passes")
                problem = .captureFailed
                letDragPass()
                return false
            }
            return true
        case .moving(var moving):
            let before = system.uptime
            moving.standIn.move(to: moving.panelOrigin(forPointer: point))
            stats.record(moveDuration: system.uptime - before)
            moving.lastPointer = point
            moving.wantsParting = moving.wantsParting || isJoinKeyDown
            drag = .moving(moving)
            return true
        }
    }
}
