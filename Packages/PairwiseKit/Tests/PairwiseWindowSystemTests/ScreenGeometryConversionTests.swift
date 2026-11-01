import CoreGraphics
import PairwiseCore
import Testing

@testable import PairwiseWindowSystem

@Suite struct ScreenGeometryConversionTests {
    @Test func aPointKeepsItsCoordinates() {
        let point = ScreenPoint(CGPoint(x: 3, y: -4))
        #expect(point == ScreenPoint(x: 3, y: -4))
        #expect(point.cgPoint == CGPoint(x: 3, y: -4))
    }

    @Test func aFrameKeepsItsPlaceAndSize() {
        let frame = WindowFrame(origin: CGPoint(x: 1, y: 2), size: CGSize(width: 3, height: 4))
        #expect(frame == WindowFrame(x: 1, y: 2, width: 3, height: 4))
    }
}
