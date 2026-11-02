import PairwiseCore
import Testing

@Suite struct DragPicturesTests {
    @Test func aUserWhoHasNotChosenGetsStillPictures() {
        #expect(DragPictures.standard == .still)
    }

    @Test func stillRunsNoStream() {
        #expect(DragPictures.still.framesPerSecond == 0)
    }

    @Test func liveRunsAStream() {
        #expect(DragPictures.live.framesPerSecond > 0)
    }

    @Test(arguments: DragPictures.allCases)
    func aChoiceSurvivesItsFrameRate(pictures: DragPictures) {
        #expect(DragPictures(framesPerSecond: pictures.framesPerSecond) == pictures)
    }

    @Test func anyOtherFrameRateCountsAsLive() {
        #expect(DragPictures(framesPerSecond: 15) == .live)
    }
}
