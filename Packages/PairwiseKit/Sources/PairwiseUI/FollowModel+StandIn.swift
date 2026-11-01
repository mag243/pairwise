import Foundation
import PairwiseCore

/// The stand-in of ADR 0014: its picture, its moves and the partner out of sight.
extension FollowModel {
    /// Takes the picture at the press, so it is there when the drag is seen. Having no
    /// partner is no problem yet: this press may be a click.
    func prepareStandIn(for window: any MovableWindow) {
        guard
            system.isScreenRecordingGranted,
            let partner = try? system.partner(for: window)
        else { return }
        pressPartner = partner
        let request = standInRequest
        system.makeStandIn(of: partner) { [weak self] result in
            guard let self, request == standInRequest else { return }
            if case .pressed = drag {
                earlyPicture = result
            } else {
                receive(result)
            }
        }
    }

    /// A failure leaves the partner following as itself.
    func receive(_ result: Result<any WindowStandIn, WindowSystemError>) {
        guard case .following(var following) = drag else { return }
        switch result {
        case .failure(let error):
            problem = error
        case .success(let standIn):
            guard let pointer = system.pointerLocation else { return }
            // Showing it before the partner leaves keeps the place from flashing empty.
            standIn.show(at: following.target(forPointer: pointer))
            let now = system.uptime
            following.standIn = standIn
            following.standInDelay = now - following.startTime
            following.startTime = now
            stats = FollowStats()
            drag = .following(following)
        }
    }

    /// A stand-in's move calls no other app, so it need not wait for the next tick. A
    /// partner moving as itself stays on the ticks, or slow calls would queue up.
    func moveStandIn(toward pointer: ScreenPoint) {
        guard case .following(let following) = drag, following.standIn != nil else { return }
        do {
            try follow(following, pointer: pointer)
        } catch {
            fail(error)
        }
    }

    func measureGrip(of following: FollowDrag.Following, pointer: ScreenPoint) {
        guard
            stillPointer.hasSettled(at: pointer, time: system.uptime),
            let frame = try? following.window.frame()
        else { return }
        let offset = following.grip.windowOrigin(forPointer: pointer).distance(to: frame.origin)
        gripOffset = max(gripOffset ?? 0, offset)
    }

    func park(_ following: FollowDrag.Following) throws(WindowSystemError) {
        if let origin = system.parkingOrigin {
            try following.partner.move(to: origin)
        }
        var parked = following
        parked.isParked = true
        drag = .following(parked)
    }
}
