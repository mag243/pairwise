import ApplicationServices
import CoreGraphics
import PairwiseCore
import Testing

@testable import PairwiseWindowSystem

@MainActor
@Suite struct AccessibilityWindowSystemTests {
    private static let rect = CGRect(x: 100, y: 100, width: 300, height: 200)
    private static let onWindow = ScreenPoint(x: 150, y: 110)
    private static let windowFrame = WindowFrame(x: 100, y: 100, width: 300, height: 200)

    private let access = FakeSystemAccess()
    private let system: AccessibilityWindowSystem

    init() {
        system = AccessibilityWindowSystem(
            access: access, captureService: FakeCaptureService())
    }

    /// An app with process `process` and one window at `rect`, on the screen.
    @discardableResult
    private func addWindow(process: pid_t = 5, number: Int = 7) -> FakeElement {
        let element = FakeElement.window(frame: Self.rect, processID: process)
        let app = FakeElement(processID: process)
        app.children[kAXWindowsAttribute] = [element]
        access.apps[process] = app
        access.windows.append(
            FakeSystemAccess.description(
                number: number, process: Int(process), frame: Self.rect))
        return element
    }

    @Test func theWindowAtAPointIsFound() throws {
        let element = addWindow()
        let window = try #require(system.window(at: Self.onWindow) as? AccessibilityWindow)
        #expect(window.element.isSame(as: element))
    }

    @Test func nothingAtThePointIsNoWindow() {
        #expect(system.window(at: Self.onWindow) == nil)
    }

    @Test func anOwnWindowOnTopIsNoWindow() {
        addWindow(process: access.ownProcess)
        #expect(system.window(at: Self.onWindow) == nil)
    }

    @Test func anAppWhoseWindowsDoNotMatchGivesNoWindow() {
        addWindow()
        access.apps[5]?.children[kAXWindowsAttribute] = []
        #expect(system.window(at: Self.onWindow) == nil)
    }

    @Test func aFoundWindowKnowsItsNumberWithoutLookingAgain() throws {
        addWindow()
        let window = try #require(system.window(at: Self.onWindow))
        #expect(window.serverFrame() == WindowFrame(x: 100, y: 100, width: 300, height: 200))
    }

    @Test func ticksCanStartAndStop() {
        system.startTicking(every: 1) {}
        system.stopTicking()
    }

    @Test func holdingCanEndWithoutHavingStarted() {
        system.stopHoldingDrags()
    }

    @Test func aPairStandInComesFromThePictures() async {
        let service = FakeCaptureService()
        service.windows = [FakeCapturable(processID: 1, frame: Self.windowFrame)]
        let system = AccessibilityWindowSystem(access: access, captureService: service)
        let first = AccessibilityWindow(
            element: FakeElement.window(frame: Self.rect), access: access)
        let second = AccessibilityWindow(
            element: FakeElement.window(frame: Self.rect), access: access)
        let succeeded = await withCheckedContinuation { continuation in
            system.makePairStandIn(of: first, beside: second) { result in
                if case .success = result {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
        #expect(succeeded)
    }

    @Test func aWindowOfAnotherKindHasNoPicture() async {
        let plain = FakePlainWindow()
        let failed = await withCheckedContinuation { continuation in
            system.makePairStandIn(of: plain, beside: plain) { result in
                if case .failure(.captureFailed) = result {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
        #expect(failed)
    }

    @Test func theNumberAtAPointAsksNoApp() {
        addWindow()
        access.apps[5] = nil
        #expect(system.windowNumber(at: Self.onWindow) == 7)
    }

    @Test func nothingAtAPointHasNoNumber() {
        #expect(system.windowNumber(at: Self.onWindow) == nil)
    }

    @Test func parkingIsPastAllDisplays() {
        access.displayFrames = [WindowFrame(x: 0, y: 0, width: 100, height: 50)]
        #expect(system.parkingOrigin == ScreenPoint(x: 99, y: 49))
    }
}
