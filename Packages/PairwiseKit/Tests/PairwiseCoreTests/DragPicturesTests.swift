import PairwiseCore
import Testing

@Suite struct DragPicturesTests {
    @Test func aUserWhoHasNotChosenGetsPlaceholders() {
        #expect(DragPictures.standard == .placeholder)
    }

    @Test func onlyLiveRunsAStream() {
        #expect(DragPictures.placeholder.framesPerSecond == 0)
        #expect(DragPictures.still.framesPerSecond == 0)
        #expect(DragPictures.live.framesPerSecond > 0)
    }

    @Test func placeholdersNeedNoScreenRecording() {
        #expect(!DragPictures.placeholder.needsScreenRecording)
    }

    @Test(arguments: [DragPictures.still, .live])
    func picturesOfWindowsNeedScreenRecording(pictures: DragPictures) {
        #expect(pictures.needsScreenRecording)
    }
}
