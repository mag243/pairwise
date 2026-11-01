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
            // Showing it before the partner leaves keeps the place from flashing empty.
            guard
                let place = following.target(
                    serverFrame: following.window.serverFrame(), pointer: system.pointerLocation)
            else { return }
            standIn.show(at: place)
            let now = system.uptime
            following.standIn = standIn
            following.lastTarget = nil
            following.standInDelay = now - following.startTime
            following.startTime = now
            stats = FollowStats()
            drag = .following(following)
        }
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
