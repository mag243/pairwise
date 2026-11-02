import PairwiseCore
import Testing

@Suite struct SeamFollowTests {
    private static let left = WindowFrame(x: 100, y: 100, width: 400, height: 300)
    private static let right = WindowFrame(x: 500, y: 100, width: 200, height: 200)
    private static let reach = SeamFollow.reachUnderHeldWindow

    @Test func aHeldWindowsSeamEdgeOnItsRightCounts() {
        let now = WindowFrame(x: 100, y: 100, width: 450, height: 300)
        #expect(SeamFollow.movesSeam(from: Self.left, to: now, partnerOn: .right))
    }

    @Test func aHeldWindowsSeamEdgeOnItsLeftCounts() {
        let now = WindowFrame(x: 450, y: 100, width: 250, height: 200)
        #expect(SeamFollow.movesSeam(from: Self.right, to: now, partnerOn: .left))
    }

    @Test func anOuterEdgeDoesNotCount() {
        let now = WindowFrame(x: 50, y: 100, width: 450, height: 300)
        #expect(!SeamFollow.movesSeam(from: Self.left, to: now, partnerOn: .right))
    }

    @Test func theBottomEdgeDoesNotCount() {
        let now = WindowFrame(x: 100, y: 100, width: 400, height: 350)
        #expect(!SeamFollow.movesSeam(from: Self.left, to: now, partnerOn: .right))
    }

    @Test func aPartnerOnTheRightMeetsTheSeamAndKeepsItsFarEdge() {
        let held = WindowFrame(x: 100, y: 100, width: 450, height: 300)
        let frame = SeamFollow.partnerFrame(
            start: Self.right, partnerOn: .right, beside: held, reach: 0)
        #expect(frame == WindowFrame(x: 550, y: 100, width: 150, height: 200))
    }

    @Test func aPartnerOnTheLeftMeetsTheSeamAndKeepsItsFarEdge() {
        let held = WindowFrame(x: 450, y: 100, width: 250, height: 200)
        let frame = SeamFollow.partnerFrame(
            start: Self.left, partnerOn: .left, beside: held, reach: 0)
        #expect(frame == WindowFrame(x: 100, y: 100, width: 350, height: 300))
    }

    @Test func aPartnerOnTheRightReachesUnderTheHeldWindow() {
        let frame = SeamFollow.partnerFrame(
            start: Self.right, partnerOn: .right, beside: Self.left, reach: Self.reach)
        #expect(frame.origin.x == 500 - Self.reach)
        #expect(frame.maxX == 700)
    }

    @Test func aPartnerOnTheLeftReachesUnderTheHeldWindow() {
        let frame = SeamFollow.partnerFrame(
            start: Self.left, partnerOn: .left, beside: Self.right, reach: Self.reach)
        #expect(frame.origin.x == 100)
        #expect(frame.maxX == 500 + Self.reach)
    }

    @Test func aPartnerNeverGetsANegativeWidth() {
        let held = WindowFrame(x: 100, y: 100, width: 900, height: 300)
        let frame = SeamFollow.partnerFrame(
            start: Self.right, partnerOn: .right, beside: held, reach: 0)
        #expect(frame.size.width == SeamFollow.smallestWidth)
    }

    @Test func aHeldWindowComesBackToAPartnerOnItsRightThatRefused() {
        let held = WindowFrame(x: 100, y: 100, width: 600, height: 300)
        let partner = WindowFrame(x: 650, y: 100, width: 50, height: 200)
        #expect(
            SeamFollow.heldFrame(held, meeting: partner, partnerOn: .right)
                == WindowFrame(x: 100, y: 100, width: 550, height: 300))
    }

    @Test func aHeldWindowComesBackToAPartnerOnItsLeftThatRefused() {
        let held = WindowFrame(x: 200, y: 100, width: 500, height: 300)
        let partner = WindowFrame(x: 100, y: 100, width: 150, height: 200)
        #expect(
            SeamFollow.heldFrame(held, meeting: partner, partnerOn: .left)
                == WindowFrame(x: 250, y: 100, width: 450, height: 300))
    }

    @Test func aHeldWindowAtThePartnersEdgeStays() {
        let partner = WindowFrame(x: 500, y: 100, width: 200, height: 200)
        #expect(SeamFollow.heldFrame(Self.left, meeting: partner, partnerOn: .right) == Self.left)
    }
}
