import Foundation
import PairwiseCore

/// The end of a drag: the partner back in its place, in front.
extension FollowModel {
    /// The button is up, so the drag ends whatever the apps answer here, except that a
    /// stand-in stays up while a busy partner may still come back.
    func release() {
        guard case .following(let following) = drag else {
            endDrag()
            return
        }
        let pointer = system.pointerLocation
        var placement: ScreenPoint?
        do {
            placement = try following.placementFromRealFrame()
        } catch {
            problem = error
            placement = pointer.map(following.target(forPointer:))
        }
        lastDrag = stats.report(
            elapsed: system.uptime - following.startTime,
            standInDelay: following.standInDelay,
            mostSlip: mostSlip)
        lastDrag?.log(
            to: Self.logger, lookAhead: lookAhead(for: following),
            predicting: following.standIn != nil && predictsStandIn)
        guard let finalTarget = placement else {
            endDrag()
            return
        }
        guard let standIn = following.standIn else {
            moveAtRelease(following.partner, to: finalTarget)
            return
        }
        let placing = FollowDrag.Placing(
            partner: following.partner, standIn: standIn, target: finalTarget,
            deadline: system.uptime + Self.placingPatience)
        drag = .placing(placing)
        place(placing)
    }

    func moveAtRelease(_ partner: any MovableWindow, to target: ScreenPoint) {
        defer { endDrag() }
        do {
            try partner.move(to: target)
            try? partner.raise()
        } catch {
            problem = error
        }
    }

    func place(_ placing: FollowDrag.Placing) {
        do {
            try placing.partner.move(to: placing.target)
            // It stays in front as the stand-in was; it is in its place either way.
            try? placing.partner.raise()
            endDrag()
        } catch {
            if error == .windowBusy, system.uptime < placing.deadline { return }
            problem = error
            endDrag()
        }
    }

    /// One last try for a partner that is parked or on its way back, when something other
    /// than the release ends the drag.
    func putPartnerBack() {
        switch drag {
        case .following(let following) where following.standIn != nil:
            if let target = try? following.placementFromRealFrame() {
                try? following.partner.move(to: target)
            }
        case .placing(let placing):
            try? placing.partner.move(to: placing.target)
        default:
            break
        }
    }
}
