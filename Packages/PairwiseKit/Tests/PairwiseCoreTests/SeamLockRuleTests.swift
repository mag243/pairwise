import PairwiseCore
import Testing

@Suite struct SeamLockRuleTests {
    private static let left = ScreenWindow(
        number: 1, frame: WindowFrame(x: 100, y: 100, width: 300, height: 200))
    private static let right = ScreenWindow(
        number: 2, frame: WindowFrame(x: 400, y: 100, width: 300, height: 400))
    private static let pair = WindowPair(left: 1, right: 2)
    /// The middle of the part the two windows share.
    private static let middle = ScreenPoint(x: 400, y: 200)

    private func lock(
        at pointer: ScreenPoint, among windows: [ScreenWindow] = [left, right],
        isShowing: Bool = false
    ) -> SeamLock? {
        SeamLockRule.lock(
            pointer: pointer, pairs: [Self.pair], windows: windows, isShowing: isShowing)
    }

    @Test func aSeamRunsAlongThePartBothWindowsShare() {
        let seam = Seam.between(left: Self.left.frame, right: Self.right.frame)
        #expect(seam == Seam(x: 400, top: 100, bottom: 300))
    }

    @Test func windowsApartHaveNoSeam() {
        let far = WindowFrame(x: 450, y: 100, width: 300, height: 400)
        #expect(Seam.between(left: Self.left.frame, right: far) == nil)
    }

    @Test func windowsOneAboveTheOtherHaveNoSeam() {
        let below = WindowFrame(x: 400, y: 300, width: 300, height: 400)
        #expect(Seam.between(left: Self.left.frame, right: below) == nil)
    }

    @Test func thePointerNearTheSeamShowsTheLockInItsMiddle() {
        let lock = lock(at: ScreenPoint(x: 410, y: 120))
        #expect(lock?.pair == Self.pair)
        #expect(lock?.frame == WindowFrame(x: 386, y: 186, width: 28, height: 28))
    }

    @Test func thePointerFarFromTheSeamShowsNoLock() {
        #expect(lock(at: ScreenPoint(x: 500, y: 200)) == nil)
    }

    @Test func thePointerBeyondTheEndOfTheSeamShowsNoLock() {
        #expect(lock(at: ScreenPoint(x: 400, y: 400)) == nil)
    }

    @Test func aShowingLockStaysALittleFurtherOut() {
        let between = ScreenPoint(x: 420, y: 200)
        #expect(lock(at: between) == nil)
        #expect(lock(at: between, isShowing: true) != nil)
    }

    @Test func aWindowOverThePointerHidesTheLock() {
        let cover = ScreenWindow(
            number: 3, frame: WindowFrame(x: 405, y: 110, width: 50, height: 50))
        let windows = [cover, Self.left, Self.right]
        #expect(lock(at: ScreenPoint(x: 410, y: 120), among: windows) == nil)
    }

    @Test func aWindowOverTheLocksPlaceHidesTheLock() {
        let cover = ScreenWindow(
            number: 3, frame: WindowFrame(x: 380, y: 180, width: 50, height: 50))
        let windows = [cover, Self.left, Self.right]
        #expect(lock(at: ScreenPoint(x: 410, y: 120), among: windows) == nil)
    }

    @Test func aWindowBehindThePairLeavesTheLock() {
        let behind = ScreenWindow(
            number: 3, frame: WindowFrame(x: 0, y: 0, width: 1000, height: 1000))
        let windows = [Self.left, Self.right, behind]
        #expect(lock(at: Self.middle, among: windows) != nil)
    }

    @Test func aPairWithAWindowOffTheScreenHasNoLock() {
        #expect(lock(at: Self.middle, among: [Self.left]) == nil)
    }

    @Test func noPairsMeanNoLock() {
        let lock = SeamLockRule.lock(
            pointer: Self.middle, pairs: [], windows: [Self.left, Self.right], isShowing: false)
        #expect(lock == nil)
    }
}
