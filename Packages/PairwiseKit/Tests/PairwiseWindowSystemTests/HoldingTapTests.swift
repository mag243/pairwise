import CoreGraphics
import PairwiseCore
import Testing

@testable import PairwiseWindowSystem

@MainActor
@Suite struct HoldingTapTests {
    private static let location = CGPoint(x: 5, y: 6)

    @Test(arguments: [
        (CGEventType.leftMouseDown, PointerButtonEvent.pressed(ScreenPoint(x: 5, y: 6))),
        (CGEventType.leftMouseDragged, PointerButtonEvent.dragged(ScreenPoint(x: 5, y: 6))),
        (CGEventType.leftMouseUp, PointerButtonEvent.released(ScreenPoint(x: 5, y: 6))),
    ])
    func aButtonEventIsDecidedOn(type: CGEventType, expected: PointerButtonEvent) {
        var seen: PointerButtonEvent?
        let tap = HoldingTap { event in
            seen = event
            return false
        }
        #expect(!tap.passes(type, at: Self.location, flags: []))
        #expect(seen == expected)
    }

    @Test func aDragSaysWhetherTheJoinKeyWasDownInTheEventItself() {
        var seen: PointerButtonEvent?
        let tap = HoldingTap { event in
            seen = event
            return true
        }
        _ = tap.passes(.leftMouseDragged, at: Self.location, flags: .maskCommand)
        #expect(seen == .dragged(ScreenPoint(x: 5, y: 6), isJoinKeyDown: true))
    }

    @Test func aDragSaysWhetherShiftWasDownInTheEventItself() {
        var seen: PointerButtonEvent?
        let tap = HoldingTap { event in
            seen = event
            return true
        }
        _ = tap.passes(.leftMouseDragged, at: Self.location, flags: [.maskCommand, .maskShift])
        #expect(
            seen
                == .dragged(
                    ScreenPoint(x: 5, y: 6), isJoinKeyDown: true, isEqualHeightKeyDown: true))
    }

    @Test func aPressSaysWhetherTheJoinKeyWasDownInTheEventItself() {
        var seen: PointerButtonEvent?
        let tap = HoldingTap { event in
            seen = event
            return true
        }
        _ = tap.passes(.leftMouseDown, at: Self.location, flags: .maskCommand)
        #expect(seen == .pressed(ScreenPoint(x: 5, y: 6), isJoinKeyDown: true))
    }

    @Test(arguments: [
        CGEventType.tapDisabledByTimeout, .tapDisabledByUserInput, .mouseMoved,
    ])
    func everythingElsePasses(type: CGEventType) {
        var decisions = 0
        let tap = HoldingTap { _ in
            decisions += 1
            return false
        }
        #expect(tap.passes(type, at: Self.location, flags: []))
        #expect(decisions == 0)
    }
}
