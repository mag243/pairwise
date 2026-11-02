import AppKit
import ApplicationServices
import CoreVideo
import PairwiseCore
import Testing

@testable import PairwiseWindowSystem

/// Calls that need no permission and show nothing. They check little more than that the
/// forwarding runs; the stress test covers the rest (ADR 0031).
@MainActor
@Suite struct LiveCallsTests {
    private let access = LiveSystemAccess()

    @Test func anElementKnowsItsProcess() {
        let element = access.application(access.ownProcess)
        element.limitMessagingTime()
        #expect(element.processID == access.ownProcess)
    }

    @Test func anElementIsTheSameAsItself() {
        let element = access.application(access.ownProcess)
        #expect(element.isSame(as: element))
    }

    @Test func differentAppsAreDifferentElements() {
        let own = access.application(access.ownProcess)
        #expect(!own.isSame(as: access.application(1)))
    }

    @Test func anUnknownAttributeGivesNothing() {
        let element = access.application(access.ownProcess)
        #expect(element.attribute("PairwiseNoSuchAttribute") == nil)
        #expect(element.elements(of: "PairwiseNoSuchAttribute").isEmpty)
        #expect(element.elementAttribute("PairwiseNoSuchAttribute") == nil)
    }

    @Test func anUnknownActionOrAttributeIsRefused() {
        let element = access.application(access.ownProcess)
        #expect(element.performAction("PairwiseNoSuchAction") != .success)
        #expect(element.setAttribute("PairwiseNoSuchAttribute", to: kCFBooleanTrue) != .success)
    }

    @Test func theWindowListsRun() {
        _ = access.onScreenWindows()
        _ = access.displays()
        #expect(access.windowDescription(CGWindowID.max) == nil)
    }

    @Test func aPanelWithPicturesCanBeMovedAndDismissedUnseen() throws {
        let picture = StandInPanel.Picture(
            image: try FakeCaptureService.image(), size: CGSize(width: 10, height: 10))
        let panel = StandInPanel(pictures: [picture], streams: [])
        #expect(panel.liveFrames.isEmpty)
        panel.move(to: ScreenPoint(x: 0, y: 0))
        panel.dismiss()
    }

    @Test func theSystemWithRealCallsReadsItsState() {
        let system = AccessibilityWindowSystem()
        _ = system.isAccessibilityGranted
        _ = system.isScreenRecordingGranted
        _ = system.isPrimaryButtonDown
        _ = system.parkingOrigin
        #expect(system.uptime > 0)
    }

    @Test func aMarkCanBeMadeAndHiddenUnseen() {
        JoinMarkPanel().hide()
    }

    @Test func aHiddenGuideCostsNothing() {
        let system = AccessibilityWindowSystem()
        _ = system.isJoinKeyDown
        system.hideJoinGuide()
    }

    @Test func aTapWithNothingInstalledStopsQuietly() {
        HoldingTap { _ in true }.stop()
    }

    @Test func theCentrePixelOfAFrameIsRead() throws {
        var buffer: CVPixelBuffer?
        CVPixelBufferCreate(nil, 2, 2, kCVPixelFormatType_32BGRA, nil, &buffer)
        let frame = try #require(buffer)
        CVPixelBufferLockBaseAddress(frame, [])
        let base = try #require(CVPixelBufferGetBaseAddress(frame))
        let row = CVPixelBufferGetBytesPerRow(frame)
        base.storeBytes(
            of: UInt32(0xABCD), toByteOffset: row + MemoryLayout<UInt32>.size, as: UInt32.self)
        CVPixelBufferUnlockBaseAddress(frame, [])
        #expect(LiveStream.centrePixel(of: frame) == 0xABCD)
    }
}
