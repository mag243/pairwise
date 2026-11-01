import PairwiseCore
import Testing

@Suite struct DragStatsTests {
    @Test func noMovesGiveNoReport() {
        #expect(DragStats().report(elapsed: 1, panelDelay: 0) == nil)
    }

    @Test func noElapsedTimeGivesNoReport() {
        var stats = DragStats()
        stats.record(moveDuration: 0.01)
        #expect(stats.report(elapsed: 0, panelDelay: 0) == nil)
    }

    @Test func reportsRateMeanLongestAndDelay() throws {
        var stats = DragStats()
        stats.record(moveDuration: 0.002)
        stats.record(moveDuration: 0.004)
        let report = try #require(stats.report(elapsed: 0.5, panelDelay: 0.08))
        #expect(report.moves == 2)
        #expect(report.movesPerSecond == 4)
        #expect(abs(report.meanMove - 0.003) < 1e-9)
        #expect(report.longestMove == 0.004)
        #expect(report.panelDelay == 0.08)
    }

    @Test func theReportCarriesTheLiveFrames() throws {
        var stats = DragStats()
        stats.record(moveDuration: 0.001)
        let report = try #require(stats.report(elapsed: 1, panelDelay: 0, liveFrames: [3, 4]))
        #expect(report.liveFrames == [3, 4])
    }

    @Test func percentileIsTheNearestRank() throws {
        var stats = DragStats()
        for milliseconds in 1...100 {
            stats.record(moveDuration: Double(milliseconds) / 1000)
        }
        let report = try #require(stats.report(elapsed: 1, panelDelay: 0))
        #expect(report.percentile95Move == 0.095)
    }
}
