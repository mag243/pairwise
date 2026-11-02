import Foundation
import PairwiseCore
import Testing

@Suite struct PairRestoreTests {
    private static let leftFrame = WindowFrame(x: 100, y: 100, width: 400, height: 300)
    private static let rightFrame = WindowFrame(x: 500, y: 100, width: 200, height: 200)

    private func identity(
        _ number: UInt32, owner: Int32 = 40, app: String? = "app.one", title: String? = "a",
        frame: WindowFrame = leftFrame
    ) -> WindowIdentity {
        WindowIdentity(number: number, owner: owner, app: app, titleKey: title, frame: frame)
    }

    private var saved: SavedPair {
        SavedPair(
            left: identity(1, title: "left"),
            right: identity(2, owner: 41, app: "app.two", title: "right", frame: Self.rightFrame))
    }

    private func found(
        _ windows: [WindowIdentity], sameBoot: Bool = true
    ) -> WindowPair? {
        PairRestore.find(saved, among: windows, isSameBoot: sameBoot)
    }

    @Test func theSameNumbersAndProcessesFindThePair() {
        let windows = [saved.left, saved.right]
        #expect(found(windows) == WindowPair(left: 1, right: 2))
    }

    @Test func aNewBootDoesNotTrustANumber() {
        // A window with that number, of the same process number, in another place and title.
        let other = identity(1, title: "else", frame: Self.leftFrame.moved(byX: 900))
        #expect(found([other, saved.right], sameBoot: false) == nil)
    }

    @Test func aNumberOfAnotherProcessIsAnotherWindow() {
        let other = identity(1, owner: 99, title: "else", frame: Self.leftFrame.moved(byX: 900))
        #expect(found([other, saved.right]) == nil)
    }

    @Test func aNewProcessIsFoundByAppAndFrame() {
        let left = identity(7, owner: 77, title: "changed")
        let right = identity(
            8, owner: 88, app: "app.two", title: "changed too", frame: Self.rightFrame)
        #expect(found([left, right], sameBoot: false) == WindowPair(left: 7, right: 8))
    }

    @Test func twoWindowsOfAnAppAtOneFrameAreNotToldApart() {
        let first = identity(7, owner: 77, title: "x")
        let second = identity(9, owner: 77, title: "y")
        let right = identity(8, owner: 88, app: "app.two", title: "z", frame: Self.rightFrame)
        #expect(found([first, second, right], sameBoot: false) == nil)
    }

    @Test func aWindowElsewhereIsFoundByAppTitleAndSizeIfThePairStillStandsSideBySide() {
        let left = identity(7, owner: 77, title: "left", frame: Self.leftFrame.moved(byX: 50))
        let right = identity(
            8, owner: 88, app: "app.two", title: "right", frame: Self.rightFrame.moved(byX: 50))
        #expect(found([left, right], sameBoot: false) == WindowPair(left: 7, right: 8))
    }

    @Test func noTitleFindsNothingByTitle() {
        let saved = SavedPair(
            left: identity(1, title: nil), right: identity(2, title: nil, frame: Self.rightFrame))
        let left = identity(7, owner: 77, title: nil, frame: Self.leftFrame.moved(byX: 50))
        let right = identity(8, owner: 88, title: nil, frame: Self.rightFrame.moved(byX: 50))
        #expect(PairRestore.find(saved, among: [left, right], isSameBoot: false) == nil)
    }

    @Test func anotherAppIsNeverFound() {
        let left = identity(7, owner: 77, app: "app.else", title: "left")
        #expect(found([left, saved.right], sameBoot: false) == nil)
    }

    @Test func noAppIsNeverFoundByFrame() {
        let saved = SavedPair(
            left: identity(1, app: nil), right: identity(2, app: nil, frame: Self.rightFrame))
        let left = identity(7, owner: 77, app: nil)
        let right = identity(8, owner: 88, app: nil, frame: Self.rightFrame)
        #expect(PairRestore.find(saved, among: [left, right], isSameBoot: false) == nil)
    }

    @Test func windowsNoLongerSideBySideAreNoPair() {
        let right = identity(
            2, owner: 41, app: "app.two", title: "right", frame: Self.rightFrame.moved(byX: 300))
        #expect(found([saved.left, right]) == nil)
    }

    @Test func topsNoLongerLevelAreNoPair() {
        var frame = Self.rightFrame
        frame.origin.y += 40
        let right = identity(2, owner: 41, app: "app.two", title: "right", frame: frame)
        #expect(found([saved.left, right]) == nil)
    }

    @Test func oneWindowIsNotAPairWithItself() {
        let saved = SavedPair(left: identity(1), right: identity(1))
        #expect(PairRestore.find(saved, among: [identity(1)], isSameBoot: true) == nil)
    }

    @Test func savedPairsSurviveBeingWritten() throws {
        let record = SavedPairs(savedAt: 5, pairs: [saved])
        let data = try #require(record.encoded())
        #expect(SavedPairs(data: data) == record)
    }

    @Test func dataThatIsNoRecordGivesNone() {
        #expect(SavedPairs(data: Data("no".utf8)) == nil)
    }
}

extension WindowFrame {
    fileprivate func moved(byX distance: Double) -> WindowFrame {
        WindowFrame(
            x: origin.x + distance, y: origin.y, width: size.width, height: size.height)
    }
}
