import PairwiseCore
import Testing

@Suite struct QuietColumnTests {
    /// A picture of 8 by 2 with text, a change from column to column, in the given columns.
    private func picture(textAt columns: Set<Int>) -> [UInt8] {
        let row = (0..<8).map { columns.contains($0) ? UInt8(255) : UInt8(0) }
        return row + row
    }

    @Test func aFlatPictureUsesItsMiddle() {
        #expect(QuietColumn.index(inGray: picture(textAt: []), width: 8, height: 2) == 4)
    }

    @Test func textInTheMiddleMovesTheColumnAway() {
        let index = QuietColumn.index(inGray: picture(textAt: [4, 5]), width: 8, height: 2)
        #expect(index == 2)
    }

    @Test func theColumnStaysInTheMiddleHalf() {
        let text = picture(textAt: [2, 3, 4, 5, 6])
        let index = QuietColumn.index(inGray: text, width: 8, height: 2)
        #expect((2..<6).contains(index))
    }

    @Test func aPictureOfOneColumnUsesIt() {
        #expect(QuietColumn.index(inGray: [1, 1], width: 1, height: 2) == 0)
    }
}
