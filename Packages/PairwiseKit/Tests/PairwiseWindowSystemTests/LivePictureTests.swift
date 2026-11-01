import IOSurface
import QuartzCore
import Testing

@testable import PairwiseWindowSystem

@MainActor
@Suite struct LivePictureTests {
    private let picture = LivePicture()
    private let layer = CALayer()

    init() {
        picture.layer = layer
    }

    private func surface() throws -> IOSurfaceRef {
        let properties: [IOSurfacePropertyKey: Any] = [
            .width: 1, .height: 1, .bytesPerElement: 4, .pixelFormat: kCVPixelFormatType_32BGRA,
        ]
        return try #require(IOSurface(properties: properties))
    }

    @Test func aFrameGoesOnTheLayer() throws {
        let frame = try surface()
        picture.show(frame, centrePixel: 1)
        #expect(layer.contents != nil)
    }

    @Test func framesThatChangeAreCounted() throws {
        let frame = try surface()
        picture.show(frame, centrePixel: 1)
        picture.show(frame, centrePixel: 2)
        picture.show(frame, centrePixel: 2)
        #expect(picture.changes == 1)
    }

    @Test func aPictureWithoutALayerStillCounts() throws {
        let frame = try surface()
        picture.layer = nil
        picture.show(frame, centrePixel: 1)
        picture.show(frame, centrePixel: 2)
        #expect(picture.changes == 1)
    }
}
