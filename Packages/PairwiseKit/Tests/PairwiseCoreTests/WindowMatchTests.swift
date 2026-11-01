import PairwiseCore
import Testing

@Suite struct WindowMatchTests {
    private static let frame = WindowFrame(x: 100, y: 100, width: 400, height: 300)

    @Test func noCandidatesMatchNothing() {
        #expect(WindowMatch.index(of: Self.frame, among: []) == nil)
    }

    @Test func aDifferentSizeDoesNotMatch() {
        let other = WindowFrame(x: 100, y: 100, width: 500, height: 300)
        #expect(WindowMatch.index(of: Self.frame, among: [other]) == nil)
    }

    @Test func aSizeWithinAPointMatches() {
        let close = WindowFrame(x: 100, y: 100, width: 400.5, height: 299.5)
        #expect(WindowMatch.index(of: Self.frame, among: [close]) == 0)
    }

    @Test func aMovingWindowMatchesAtAnotherOrigin() {
        let moved = WindowFrame(x: 180, y: 90, width: 400, height: 300)
        #expect(WindowMatch.index(of: Self.frame, among: [moved]) == 0)
    }

    @Test func ofTwoOfTheSameSizeTheClosestMatches() {
        let far = WindowFrame(x: 900, y: 700, width: 400, height: 300)
        let near = WindowFrame(x: 110, y: 100, width: 400, height: 300)
        #expect(WindowMatch.index(of: Self.frame, among: [far, near]) == 1)
    }
}
