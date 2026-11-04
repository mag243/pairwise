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

    @Test func aDragSaysWhetherControlWasDownInTheEventItself() {
        var seen: PointerButtonEvent?
        let tap = HoldingTap { event in
            seen = event
            return true
        }
        _ = tap.passes(.leftMouseDragged, at: Self.location, flags: [.maskCommand, .maskControl])
        #expect(
            seen == .dragged(ScreenPoint(x: 5, y: 6), isJoinKeyDown: true, isScopeKeyDown: true))
    }

    @Test func aChangeOfKeysSaysWhetherControlIsDown() {
        var seen: PointerButtonEvent?
        let tap = HoldingTap { event in
            seen = event
            return true
        }
        _ = tap.passes(.flagsChanged, at: Self.location, flags: [.maskCommand, .maskControl])
        #expect(
            seen
                == .keysChanged(
                    isJoinKeyDown: true, isEqualHeightKeyDown: false, isScopeKeyDown: true))
    }

    @Test func aChangeOfKeysIsReportedAndPassesWhateverTheAnswer() {
        var seen: PointerButtonEvent?
        let tap = HoldingTap { event in
            seen = event
            return false
        }
        #expect(tap.passes(.flagsChanged, at: Self.location, flags: .maskCommand))
        #expect(seen == .keysChanged(isJoinKeyDown: true, isEqualHeightKeyDown: false))
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

    private func tapSeeing(
        answer: Bool = false
    ) -> (tap: HoldingTap, seen: () -> PointerButtonEvent?) {
        final class Box { var event: PointerButtonEvent? }
        let box = Box()
        let tap = HoldingTap { event in
            box.event = event
            return answer
        }
        return (tap, { box.event })
    }

    private static let zKey: Int64 = 6
    private static let otherKey: Int64 = 0

    @Test func theChoiceKeyWithCommandIsDecidedOn() {
        let (tap, seen) = tapSeeing()
        #expect(!tap.passesKey(code: Self.zKey, flags: .maskCommand, isRepeat: false))
        #expect(seen() == .joinChoiceKey(isRepeat: false))
    }

    @Test func theChoiceKeySaysThatItRepeats() {
        let (tap, seen) = tapSeeing()
        _ = tap.passesKey(code: Self.zKey, flags: .maskCommand, isRepeat: true)
        #expect(seen() == .joinChoiceKey(isRepeat: true))
    }

    @Test func theChoiceKeyWithoutCommandPassesUnseen() {
        let (tap, seen) = tapSeeing()
        #expect(tap.passesKey(code: Self.zKey, flags: [], isRepeat: false))
        #expect(seen() == nil)
    }

    @Test func anotherKeyWithCommandPassesUnseen() {
        let (tap, seen) = tapSeeing()
        #expect(tap.passesKey(code: Self.otherKey, flags: .maskCommand, isRepeat: false))
        #expect(seen() == nil)
    }

    @Test func aWheelIsDecidedOnByItsLines() {
        let (tap, seen) = tapSeeing()
        #expect(!tap.passesScroll(lines: -3, points: -27, isContinuous: false))
        #expect(seen() == .scrolledWheel(lines: -3))
    }

    @Test func aTrackpadIsDecidedOnByItsPoints() {
        let (tap, seen) = tapSeeing(answer: true)
        #expect(tap.passesScroll(lines: -1, points: -12.5, isContinuous: true))
        #expect(seen() == .scrolledTrackpad(points: -12.5))
    }
}
