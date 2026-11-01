import PairwiseCore
import Testing

@Suite struct PairBookTests {
    @Test func aWindowCannotPairWithItself() {
        var book = PairBook()
        #expect(throws: PairError.sameWindow) { try book.join(1, to: 1, on: .left) }
    }

    @Test func aWindowOnTheLeftIsLeft() throws {
        var book = PairBook()
        try book.join(1, to: 2, on: .left)
        #expect(book.pairs.first?.left == 1)
        #expect(book.pairs.first?.right == 2)
    }

    @Test func aWindowOnTheRightIsRight() throws {
        var book = PairBook()
        try book.join(1, to: 2, on: .right)
        #expect(book.pairs.first?.left == 2)
        #expect(book.pairs.first?.right == 1)
    }

    @Test(arguments: [(UInt32(1), UInt32(3)), (3, 1), (2, 3), (3, 2)])
    func aWindowIsInOnePairAtMost(first: UInt32, second: UInt32) throws {
        var book = PairBook()
        try book.join(1, to: 2, on: .left)
        #expect(throws: PairError.alreadyInPair) { try book.join(first, to: second, on: .left) }
    }

    @Test func aPairIsFoundFromEitherWindow() throws {
        var book = PairBook()
        try book.join(1, to: 2, on: .left)
        #expect(book.pair(containing: 1) == book.pair(containing: 2))
        #expect(book.pair(containing: 1) != nil)
        #expect(book.pair(containing: 3) == nil)
    }

    @Test func thePartnerAndItsSideComeFromEitherWindow() throws {
        var book = PairBook()
        try book.join(1, to: 2, on: .left)
        let ofLeft = book.partner(of: 1)
        let ofRight = book.partner(of: 2)
        #expect(ofLeft?.window == 2)
        #expect(ofLeft?.side == .right)
        #expect(ofRight?.window == 1)
        #expect(ofRight?.side == .left)
        #expect(book.partner(of: 3) == nil)
    }

    @Test func anEndedPairLeavesBothFree() throws {
        var book = PairBook()
        try book.join(1, to: 2, on: .left)
        book.end(pairContaining: 2)
        #expect(book.pairs.isEmpty)
        try book.join(1, to: 3, on: .left)
        #expect(book.pairs.count == 1)
    }
}
