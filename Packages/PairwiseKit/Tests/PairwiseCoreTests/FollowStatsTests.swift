import PairwiseCore
import Testing

@Suite struct FollowStatsTests {
    @Test func noMovesGiveNoReport() {
        #expect(FollowStats().report(elapsed: 1) == nil)
    }

    @Test func noElapsedTimeGivesNoReport() {
        var stats = FollowStats()
        stats.record(moveDuration: 0.01, pointsBehind: 1)
        #expect(stats.report(elapsed: 0) == nil)
    }

    @Test func reportsRateMeanAndLongest() throws {
        var stats = FollowStats()
        stats.record(moveDuration: 0.002, pointsBehind: 1)
        stats.record(moveDuration: 0.004, pointsBehind: 5)
        let report = try #require(stats.report(elapsed: 0.5))
        #expect(report.moves == 2)
        #expect(report.movesPerSecond == 4)
        #expect(abs(report.meanMove - 0.003) < 1e-9)
        #expect(report.longestMove == 0.004)
        #expect(report.meanPointsBehind == 3)
        #expect(report.mostPointsBehind == 5)
    }

    @Test func percentileIsTheNearestRank() throws {
        var stats = FollowStats()
        for milliseconds in 1...100 {
            stats.record(moveDuration: Double(milliseconds) / 1000, pointsBehind: 0)
        }
        let report = try #require(stats.report(elapsed: 1))
        #expect(report.percentile95Move == 0.095)
    }
}
