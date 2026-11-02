import CoreGraphics
import PairwiseCore
import Testing

@testable import PairwiseWindowSystem

@MainActor
@Suite struct WindowCaptureTests {
    private static let rect = CGRect(x: 10, y: 20, width: 300, height: 200)
    private static let frame = WindowFrame(x: 10, y: 20, width: 300, height: 200)

    private struct Failure: Error {}

    private let access = FakeSystemAccess()
    private let service = FakeCaptureService()
    private let capture: WindowCapture
    private let window: AccessibilityWindow

    init() {
        capture = WindowCapture(service: service)
        window = AccessibilityWindow(
            element: FakeElement.window(frame: Self.rect), access: access)
    }

    private func onScreen() {
        service.windows = [FakeCapturable(processID: 1, frame: Self.frame)]
    }

    @Test func aWindowOnTheListGetsAPicture() async {
        onScreen()
        let result = await capture.standIn(of: [window], framesPerSecond: 30)
        #expect(throws: Never.self) { try result.get() }
        #expect(service.pictureFrames == [Self.frame])
    }

    @Test func theFrameRateIsPassedOn() async {
        onScreen()
        _ = await capture.standIn(of: [window], framesPerSecond: 15)
        #expect(service.standInFramesPerSecond == 15)
    }

    @Test func aPreparedListIsUsedWithoutAskingAgain() async {
        onScreen()
        await capture.prepare()
        _ = await capture.standIn(of: [window], framesPerSecond: 30)
        #expect(service.listRequests == 1)
    }

    @Test func aListWithoutTheWindowIsAskedForAgain() async {
        await capture.prepare()
        onScreen()
        let result = await capture.standIn(of: [window], framesPerSecond: 30)
        #expect(throws: Never.self) { try result.get() }
        #expect(service.listRequests == 2)
    }

    /// A window that had another window's size in an older list, as after a resize at a seam.
    @Test func aWindowWithANumberIsFoundByItAndNotByItsSize() async {
        let numbered = AccessibilityWindow(
            element: FakeElement.window(frame: Self.rect), serverWindowNumber: 7, access: access)
        service.windows = [
            FakeCapturable(processID: 1, frame: Self.frame, windowNumber: 8),
            FakeCapturable(
                processID: 1, frame: WindowFrame(x: 900, y: 20, width: 500, height: 200),
                windowNumber: 7),
        ]
        await capture.prepare()
        _ = await capture.standIn(of: [numbered], framesPerSecond: 30)
        #expect(service.picturedNumbers == [7])
    }

    @Test func aWindowWithANumberNotOnTheListAsksForAFreshList() async {
        let numbered = AccessibilityWindow(
            element: FakeElement.window(frame: Self.rect), serverWindowNumber: 7, access: access)
        service.windows = [FakeCapturable(processID: 1, frame: Self.frame, windowNumber: 8)]
        await capture.prepare()
        service.windows.append(
            FakeCapturable(processID: 1, frame: Self.frame, windowNumber: 7))
        _ = await capture.standIn(of: [numbered], framesPerSecond: 30)
        #expect(service.listRequests == 2)
        #expect(service.picturedNumbers == [7])
    }

    @Test func aWindowOfAnotherAppIsNotPictured() async {
        service.windows = [FakeCapturable(processID: 2, frame: Self.frame)]
        let result = await capture.standIn(of: [window], framesPerSecond: 30)
        #expect(throws: WindowSystemError.captureFailed) { try result.get() }
    }

    @Test func aWindowOfAnotherSizeIsNotPictured() async {
        service.windows = [
            FakeCapturable(processID: 1, frame: WindowFrame(x: 10, y: 20, width: 9, height: 9))
        ]
        let result = await capture.standIn(of: [window], framesPerSecond: 30)
        #expect(throws: WindowSystemError.captureFailed) { try result.get() }
    }

    @Test func aMovedWindowIsStillFound() async {
        service.windows = [
            FakeCapturable(processID: 1, frame: WindowFrame(x: 90, y: 90, width: 300, height: 200))
        ]
        let result = await capture.standIn(of: [window], framesPerSecond: 30)
        #expect(throws: Never.self) { try result.get() }
    }

    @Test func aFailingListIsNoPicture() async {
        service.listError = Failure()
        let result = await capture.standIn(of: [window], framesPerSecond: 30)
        #expect(throws: WindowSystemError.captureFailed) { try result.get() }
    }

    @Test func aFailingPrepareIsForLater() async {
        service.listError = Failure()
        await capture.prepare()
        service.listError = nil
        onScreen()
        let result = await capture.standIn(of: [window], framesPerSecond: 30)
        #expect(throws: Never.self) { try result.get() }
    }

    @Test func aFailingPictureIsNoPicture() async {
        onScreen()
        service.pictureError = Failure()
        let result = await capture.standIn(of: [window], framesPerSecond: 30)
        #expect(throws: WindowSystemError.captureFailed) { try result.get() }
    }

    @Test func aWindowThatHasGoneSaysSo() async {
        let element = FakeElement.window(frame: Self.rect)
        element.errors["AXPosition"] = .invalidUIElement
        let gone = AccessibilityWindow(element: element, access: access)
        let result = await capture.standIn(of: [gone], framesPerSecond: 30)
        #expect(throws: WindowSystemError.windowGone) { try result.get() }
    }
}
