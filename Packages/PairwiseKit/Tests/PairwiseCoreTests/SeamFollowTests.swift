import PairwiseCore
import Testing

@Suite struct SeamFollowTests {
    private static let left = WindowFrame(x: 100, y: 100, width: 400, height: 300)
    private static let right = WindowFrame(x: 500, y: 100, width: 200, height: 200)

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

    @Test func aWindowOnTheRightMeetsTheSeamAndKeepsItsFarEdge() {
        #expect(
            SeamFollow.frame(start: Self.right, on: .right, seamAt: 550)
                == WindowFrame(x: 550, y: 100, width: 150, height: 200))
    }

    @Test func aWindowOnTheLeftMeetsTheSeamAndKeepsItsFarEdge() {
        #expect(
            SeamFollow.frame(start: Self.left, on: .left, seamAt: 450)
                == WindowFrame(x: 100, y: 100, width: 350, height: 300))
    }

    @Test func aWindowNeverGetsANegativeWidth() {
        let frame = SeamFollow.frame(start: Self.right, on: .right, seamAt: 900)
        #expect(frame.size.width == SeamFollow.smallestWidth)
        #expect(frame.maxX == 700)
    }

    @Test func aWindowOnTheRightOfAnotherSizeKeepsItsFarEdge() {
        #expect(
            SeamFollow.frame(start: Self.right, on: .right, withWidth: 150)
                == WindowFrame(x: 550, y: 100, width: 150, height: 200))
    }

    @Test func aWindowOnTheLeftOfAnotherSizeKeepsItsFarEdge() {
        #expect(
            SeamFollow.frame(start: Self.left, on: .left, withWidth: 350)
                == WindowFrame(x: 100, y: 100, width: 350, height: 300))
    }

    @Test func aWindowSeesItsSeamOnTheSideOfItsPartner() {
        #expect(SeamFollow.seam(of: Self.left, partnerOn: .right) == 500)
        #expect(SeamFollow.seam(of: Self.right, partnerOn: .left) == 500)
    }

    @Test func theOtherSideIsTheOpposite() {
        #expect(PairSide.left.opposite == .right)
        #expect(PairSide.right.opposite == .left)
    }
}
