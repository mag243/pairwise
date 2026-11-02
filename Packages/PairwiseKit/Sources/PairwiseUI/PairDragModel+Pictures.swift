import PairwiseCore

/// Asking for the pictures of a press, with placeholders when a capture fails (ADR 0064).
extension PairDragModel {
    /// Asks for pictures of `first` beside `second`. When a capture fails this drag goes on with
    /// placeholders, and the next drag tries a capture again, as the permission may be back.
    func askForPictures(
        of first: any MovableWindow, beside second: any MovableWindow, isFallback: Bool = false
    ) {
        let current = request
        system.makePairStandIn(of: first, beside: second) { [weak self] result in
            guard let self, current == request else { return }
            if isFallback {
                applyDragPictures()
            } else if !system.showsPlaceholders {
                if case .failure(.captureFailed) = result {
                    hasCaptureFailed = true
                    system.showsPlaceholders = true
                    askForPictures(of: first, beside: second, isFallback: true)
                    return
                }
                if case .success = result { hasCaptureFailed = false }
            }
            receive(result)
        }
    }
}
