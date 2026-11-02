import PairwiseCore
import Testing

@Suite struct SeamFollowTests {
    private static let left = WindowFrame(x: 100, y: 100, width: 400, height: 300)
    private static let right = WindowFrame(x: 500, y: 100, width: 200, height: 200)
    private static let reach = SeamFollow.reachUnderHeldWindow

    @Test func aGrowingPartnerReachesAsFarAsTheSeamTravelsInAFewFrames() {
        #expect(SeamFollow.reach(after: 0, widthChange: 5) == 15)
    }

    @Test func aFastSeamReachesNoFurtherThanTheMost() {
        #expect(SeamFollow.reach(after: 0, widthChange: 100) == SeamFollow.reachUnderHeldWindow)
    }

    @Test func aSlowerSeamDoesNotCutTheReachAtOnce() {
        #expect(SeamFollow.reach(after: 30, widthChange: 1) == 21)
    }

    @Test func aStillSeamShrinksTheReach() {
        #expect(SeamFollow.reach(after: 20, widthChange: 0) == 14)
    }

    @Test func aSmallReachOnAStillSeamIsGone() {
        #expect(SeamFollow.reach(after: 1, widthChange: 0) == 0)
    }

    @Test func aShrinkingPartnerHasNoReach() {
        #expect(SeamFollow.reach(after: 30, widthChange: -5) == 0)
    }

    /// Notes the same answer as many times as it takes to count as a limit.
    private func limits(
        partnerOn side: PairSide, start: WindowFrame, asked: Double, reached: Double
    ) -> SeamLimits {
        var limits = SeamLimits()
        for _ in 0..<SeamLimits.answersForALimit {
            limits.note(asked: asked, reached: reached, start: start, partnerOn: side)
        }
        return limits
    }

    @Test func aPartnerOnTheRightAtItsMinimumStopsTheSeamGoingRight() {
        let limits = limits(partnerOn: .right, start: Self.right, asked: 100, reached: 150)
        #expect(limits.allows(seamAt: 550))
        #expect(!limits.allows(seamAt: 551))
        #expect(limits.allows(seamAt: 400))
    }

    @Test func aPartnerOnTheRightAtItsMaximumStopsTheSeamGoingLeft() {
        let limits = limits(partnerOn: .right, start: Self.right, asked: 300, reached: 250)
        #expect(limits.allows(seamAt: 450))
        #expect(!limits.allows(seamAt: 449))
        #expect(limits.allows(seamAt: 600))
    }

    @Test func aPartnerOnTheLeftAtItsMinimumStopsTheSeamGoingLeft() {
        let limits = limits(partnerOn: .left, start: Self.left, asked: 200, reached: 300)
        #expect(limits.allows(seamAt: 400))
        #expect(!limits.allows(seamAt: 399))
    }

    @Test func aPartnerOnTheLeftAtItsMaximumStopsTheSeamGoingRight() {
        let limits = limits(partnerOn: .left, start: Self.left, asked: 600, reached: 500)
        #expect(limits.allows(seamAt: 600))
        #expect(!limits.allows(seamAt: 601))
    }

    @Test func aFewAnswersAreNoLimitYet() {
        var limits = SeamLimits()
        for _ in 1..<SeamLimits.answersForALimit {
            limits.note(asked: 100, reached: 150, start: Self.right, partnerOn: .right)
        }
        #expect(limits.allows(seamAt: 700))
    }

    @Test func aPartnerStillCatchingUpIsNoLimit() {
        var limits = SeamLimits()
        for reached in [150.0, 149, 148, 147, 146] {
            limits.note(asked: 100, reached: reached, start: Self.right, partnerOn: .right)
        }
        #expect(limits.allows(seamAt: 700))
    }

    @Test func aRoundedWidthIsNoLimit() {
        var limits = SeamLimits()
        for _ in 0..<SeamLimits.answersForALimit * 2 {
            limits.note(asked: 100, reached: 108, start: Self.right, partnerOn: .right)
        }
        #expect(limits.allows(seamAt: 700))
    }

    @Test func anAnswerAsAskedStartsTheCountAnew() {
        var limits = SeamLimits()
        for _ in 1..<SeamLimits.answersForALimit {
            limits.note(asked: 100, reached: 150, start: Self.right, partnerOn: .right)
        }
        limits.note(asked: 150, reached: 150, start: Self.right, partnerOn: .right)
        limits.note(asked: 100, reached: 150, start: Self.right, partnerOn: .right)
        #expect(limits.allows(seamAt: 700))
    }

    @Test func aSeamPastALimitIsBroughtBackToIt() {
        let limits = limits(partnerOn: .right, start: Self.right, asked: 100, reached: 150)
        #expect(limits.clamped(seamAt: 600) == 550)
        #expect(limits.clamped(seamAt: 500) == 500)
    }

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

    @Test func aPartnerOnTheRightOfAnotherSizeKeepsItsFarEdge() {
        let frame = SeamFollow.partnerFrame(
            start: Self.right, partnerOn: .right, withWidth: 150)
        #expect(frame == WindowFrame(x: 550, y: 100, width: 150, height: 200))
    }

    @Test func aPartnerOnTheLeftOfAnotherSizeKeepsItsFarEdge() {
        let frame = SeamFollow.partnerFrame(
            start: Self.left, partnerOn: .left, withWidth: 350)
        #expect(frame == WindowFrame(x: 100, y: 100, width: 350, height: 300))
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
