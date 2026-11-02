import Foundation
import PairwiseCore
import Testing

@Suite struct ParkingRecordTests {
    private static let frame = WindowFrame(x: 10, y: 20, width: 300, height: 200)
    private static let parked = WindowFrame(x: 9000, y: 9000, width: 300, height: 200)

    private func record(savedAt: TimeInterval = 100) -> ParkingRecord {
        ParkingRecord(
            savedAt: savedAt,
            windows: [ParkedWindow(number: 1, owner: 40, frame: Self.frame)])
    }

    @Test func aRecordSurvivesBeingWritten() throws {
        let data = try #require(record().encoded())
        #expect(ParkingRecord(data: data) == record())
    }

    @Test func dataThatIsNotARecordGivesNone() {
        #expect(ParkingRecord(data: Data("not a record".utf8)) == nil)
    }

    @Test func aWindowOfTheSameProcessIsPutBack() {
        let windows = [ScreenWindow(number: 1, frame: Self.parked, owner: 40)]
        #expect(record().windowsToPutBack(now: 200, among: windows).count == 1)
    }

    @Test func aWindowOfAnotherProcessWithThatNumberIsLeftAlone() {
        let windows = [ScreenWindow(number: 1, frame: Self.parked, owner: 41)]
        #expect(record().windowsToPutBack(now: 200, among: windows).isEmpty)
    }

    @Test func aWindowThatHasGoneIsSkipped() {
        #expect(record().windowsToPutBack(now: 200, among: []).isEmpty)
    }

    @Test func aRecordFromBeforeARestartOfTheMacPutsNothingBack() {
        let windows = [ScreenWindow(number: 1, frame: Self.parked, owner: 40)]
        #expect(record(savedAt: 300).windowsToPutBack(now: 200, among: windows).isEmpty)
    }
}
