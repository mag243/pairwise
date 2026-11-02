import ApplicationServices
import CoreGraphics
import PairwiseCore
import Testing

@testable import PairwiseWindowSystem

@MainActor
@Suite struct AccessibilityWindowTests {
    private static let rect = CGRect(x: 10, y: 20, width: 300, height: 200)
    private static let frame = WindowFrame(x: 10, y: 20, width: 300, height: 200)

    private let access = FakeSystemAccess()
    private let element = FakeElement.window(frame: Self.rect)

    private func makeWindow() -> AccessibilityWindow {
        AccessibilityWindow(element: element, access: access)
    }

    @Test func aWindowLimitsHowLongItsAppMayTake() {
        _ = makeWindow()
        #expect(element.timeLimits == 1)
    }

    @Test func theFrameComesFromPositionAndSize() throws {
        #expect(try makeWindow().frame() == Self.frame)
    }

    @Test func aWindowThatHasGoneSaysSo() {
        element.errors[kAXPositionAttribute] = .invalidUIElement
        #expect(throws: WindowSystemError.windowGone) { try makeWindow().frame() }
    }

    @Test func anAttributeOfTheWrongKindIsARefusal() {
        element.attributes[kAXSizeAttribute] = "wrong" as CFString
        #expect(throws: WindowSystemError.windowRefused) { try makeWindow().frame() }
    }

    @Test func aMoveSetsThePosition() throws {
        try makeWindow().move(to: ScreenPoint(x: 5, y: 6))
        #expect(try makeWindow().frame().origin == ScreenPoint(x: 5, y: 6))
    }

    @Test func aRefusedMoveSaysWhy() {
        element.setErrors[kAXPositionAttribute] = .cannotComplete
        #expect(throws: WindowSystemError.windowBusy) {
            try makeWindow().move(to: ScreenPoint(x: 5, y: 6))
        }
    }

    @Test func aMoveTurnsTheAppsAnimationOffAndBackOn() throws {
        let app = FakeElement()
        app.attributes["AXEnhancedUserInterface"] = kCFBooleanTrue
        access.apps[1] = app
        try makeWindow().move(to: ScreenPoint(x: 5, y: 6))
        let values = app.sets.map { $0.value as? Bool }
        #expect(values == [false, true])
    }

    @Test func aFailedMoveStillPutsTheAnimationBack() {
        let app = FakeElement()
        app.attributes["AXEnhancedUserInterface"] = kCFBooleanTrue
        access.apps[1] = app
        element.setErrors[kAXPositionAttribute] = .cannotComplete
        _ = try? makeWindow().move(to: ScreenPoint(x: 5, y: 6))
        #expect(app.attributes["AXEnhancedUserInterface"] as? Bool == true)
    }

    @Test func anAppWithoutTheAnimationIsLeftAlone() throws {
        let app = FakeElement()
        access.apps[1] = app
        try makeWindow().move(to: ScreenPoint(x: 5, y: 6))
        #expect(app.sets.isEmpty)
    }

    @Test func aWindowWithoutAProcessStillMoves() throws {
        element.processID = nil
        try makeWindow().move(to: ScreenPoint(x: 5, y: 6))
        #expect(element.sets.count == 1)
    }

    @Test func raiseAsksForTheRaiseAction() throws {
        try makeWindow().raise()
        #expect(element.actions == [kAXRaiseAction])
    }

    @Test func aRefusedRaiseSaysWhy() {
        element.actionError = .invalidUIElement
        #expect(throws: WindowSystemError.windowGone) { try makeWindow().raise() }
    }

    @Test func theServerFrameIsFoundByMatchingTheWindow() {
        access.windows = [
            FakeSystemAccess.description(number: 7, process: 1, frame: Self.rect)
        ]
        #expect(makeWindow().serverFrame() == Self.frame)
    }

    @Test func aKnownNumberNeedsNoMatching() {
        access.windows = [
            FakeSystemAccess.description(
                number: 7, process: 2, frame: CGRect(x: 0, y: 0, width: 9, height: 9))
        ]
        let window = AccessibilityWindow(element: element, serverWindowNumber: 7, access: access)
        #expect(window.serverFrame() == WindowFrame(x: 0, y: 0, width: 9, height: 9))
    }

    @Test func aWindowTheServerDoesNotKnowHasNoServerFrame() {
        #expect(makeWindow().serverFrame() == nil)
    }

    @Test func theNumberIsLookedUpOnce() {
        let window = makeWindow()
        _ = window.serverFrame()
        access.windows = [
            FakeSystemAccess.description(number: 7, process: 1, frame: Self.rect)
        ]
        #expect(window.serverFrame() == nil)
    }

    @Test func aWindowKnowsItsNumber() {
        access.windows = [
            FakeSystemAccess.description(number: 7, process: 1, frame: Self.rect)
        ]
        #expect(makeWindow().windowNumber == 7)
    }

    @Test func aNormalWindowIsAvailable() {
        #expect(makeWindow().isAvailable)
    }

    @Test func aMinimizedWindowIsNotAvailable() {
        element.attributes[kAXMinimizedAttribute] = kCFBooleanTrue
        #expect(!makeWindow().isAvailable)
    }

    @Test func aFullScreenWindowIsNotAvailable() {
        element.attributes["AXFullScreen"] = kCFBooleanTrue
        #expect(!makeWindow().isAvailable)
    }

    @Test func aClosedWindowIsNotAvailable() {
        element.errors[kAXPositionAttribute] = .invalidUIElement
        #expect(!makeWindow().isAvailable)
    }

    @Test func aResizeSetsTheSize() throws {
        try makeWindow().resize(to: WindowSize(width: 50, height: 60))
        #expect(try makeWindow().frame().size == WindowSize(width: 50, height: 60))
    }

    @Test func aRefusedResizeSaysWhy() {
        element.setErrors[kAXSizeAttribute] = .cannotComplete
        #expect(throws: WindowSystemError.windowBusy) {
            try makeWindow().resize(to: WindowSize(width: 50, height: 60))
        }
    }
}
