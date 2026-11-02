import AppKit
import IOSurface
import PairwiseCore
import Testing

@testable import PairwiseWindowSystem

/// What the panel does with a seam and with live frames. It is never shown.
@MainActor
@Suite struct StandInPanelTests {
    private static let left = CGSize(width: 100, height: 80)
    private static let right = CGSize(width: 50, height: 200)

    /// A picture of one colour, with a white stripe in the given columns.
    private func picture(
        size: CGSize, stripe: ClosedRange<Int>? = nil, gray: CGFloat = 0
    ) throws -> StandInPanel.Picture {
        let context = try #require(
            CGContext(
                data: nil, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8,
                bytesPerRow: Int(size.width) * 4, space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.setFillColor(CGColor(gray: gray, alpha: 1))
        context.fill(CGRect(origin: .zero, size: size))
        if let stripe {
            context.setFillColor(CGColor(gray: 1, alpha: 1))
            context.fill(
                CGRect(
                    x: CGFloat(stripe.lowerBound), y: 0, width: CGFloat(stripe.count),
                    height: size.height))
        }
        return StandInPanel.Picture(image: try #require(context.makeImage()), size: size)
    }

    private func panel() throws -> StandInPanel {
        StandInPanel(
            pictures: [try picture(size: Self.left), try picture(size: Self.right)], streams: [])
    }

    private func surface() throws -> IOSurfaceRef {
        let properties: [IOSurfacePropertyKey: Any] = [
            .width: 400, .height: 200, .bytesPerElement: 4,
            .pixelFormat: kCVPixelFormatType_32BGRA,
        ]
        return try #require(IOSurface(properties: properties))
    }

    @Test func aSeamPutsBothSlotsAgainstIt() throws {
        let panel = try panel()
        panel.setSeam(atOffset: 90)
        #expect(panel.slots[0].frame.width == 90)
        #expect(panel.slots[1].frame.origin.x == 90)
        #expect(panel.slots[1].frame.width == 60)
    }

    @Test func aSeamPutsTheAmberLineOnIt() throws {
        let panel = try panel()
        panel.setSeam(atOffset: 90)
        #expect(panel.seamLineLayer.frame.midX == 90)
        #expect(panel.seamLineLayer.superlayer != nil)
    }

    @Test func picturesThatStayStillAreDividedWithTheirWholeLayerHidden() throws {
        let panel = try panel()
        panel.setSeam(atOffset: 90)
        let areHidden = panel.images.allSatisfy(\.isHidden)
        #expect(areHidden)
        #expect(panel.parts.count == 2)
        #expect(panel.parts[0].tail.frame.maxX == 90)
    }

    @Test func aSecondSeamPreparesNothingNew() throws {
        let panel = try panel()
        panel.setSeam(atOffset: 90)
        let count = panel.slots[0].sublayers?.count
        panel.setSeam(atOffset: 80)
        #expect(panel.slots[0].sublayers?.count == count)
        #expect(panel.slots[0].frame.width == 80)
    }

    @Test func anOpaqueBackingLiesUnderEachPicture() throws {
        let panel = try panel()
        panel.setSeam(atOffset: 90)
        #expect(panel.backings.count == 2)
        #expect(panel.slots[0].sublayers?.first === panel.backings[0])
        #expect(panel.backings[0].backgroundColor?.alpha == 1)
        #expect(panel.backings[0].frame == panel.images[0].frame)
    }

    @Test func aLiveFrameFillsTheLayerWithThePartThatHoldsTheWindow() throws {
        let panel = try panel()
        panel.setSeam(atOffset: 90)
        panel.show(try surface(), rect: CGRect(x: 0, y: 0, width: 100, height: 50), scale: 2, at: 0)
        #expect(panel.images[0].contents != nil)
        #expect(panel.images[0].contentsRect == CGRect(x: 0, y: 0, width: 0.5, height: 0.5))
        #expect(panel.images[0].frame.width == 90)
    }

    @Test func aFrameForNoPictureOrWithNoWidthIsIgnored() throws {
        let panel = try panel()
        panel.setSeam(atOffset: 90)
        let before = panel.images[0].contentsRect
        panel.show(try surface(), rect: CGRect(x: 0, y: 0, width: 100, height: 50), scale: 2, at: 5)
        panel.show(try surface(), rect: .zero, scale: 2, at: 0)
        #expect(panel.images[0].contentsRect == before)
    }

    @Test func theButtonsPatchLiesOverTheFrames() throws {
        let panel = try panel()
        panel.setSeam(atOffset: 90)
        panel.addButtonsPatch(over: 0)
        let patch = try #require(panel.slots[0].sublayers?.last)
        #expect(patch.contents != nil)
        #expect(patch.frame == StandInPanel.buttonsPatch(ofPictureSize: Self.left).frame)
    }

    @Test func aPictureDividesBesideItsText() throws {
        // About as wide as a word in a window of this width.
        let image = try picture(size: CGSize(width: 640, height: 40), stripe: 315...325)
        let split = StandInPanel.quietSplit(of: image)
        #expect(!(314...326).contains(split))
        #expect((160...480).contains(split))
    }

    @Test func aPictureOfNoSizeDividesInItsMiddle() throws {
        let image = try picture(size: CGSize(width: 10, height: 10))
        let empty = StandInPanel.Picture(image: image.image, size: .zero)
        #expect(StandInPanel.quietSplit(of: empty) == 0)
    }
}

/// The marks and the calls to the system. A mark that shows stands far off every screen.
@MainActor
@Suite struct SystemMarksAndCallsTests {
    private static let offScreen = WindowFrame(x: -30000, y: -30000, width: 28, height: 28)

    @Test(arguments: [true, false])
    func aLockShowsAndGoes(isClosed: Bool) {
        let lock = SeamLockPanel()
        lock.show(at: Self.offScreen, isClosed: isClosed)
        #expect(lock.panel.isVisible)
        lock.hide()
        #expect(!lock.panel.isVisible)
    }

    @Test func aLockChangesWithItsState() {
        let lock = SeamLockPanel()
        lock.show(at: Self.offScreen, isClosed: true)
        let closed = lock.panel.contentView?.layer?.backgroundColor
        lock.show(at: Self.offScreen, isClosed: false)
        #expect(lock.panel.contentView?.layer?.backgroundColor != closed)
        lock.hide()
    }

    @Test func aMarkShowsAndGoes() {
        let mark = JoinMarkPanel()
        mark.show(at: Self.offScreen)
        mark.hide()
    }

    @Test func theSystemsOwnMarksComeAndGo() {
        let system = AccessibilityWindowSystem()
        system.showJoinGuide(at: Self.offScreen)
        system.hideJoinGuide()
        system.showSeamLock(at: Self.offScreen, isClosed: true)
        system.hideSeamLock()
    }

    @Test func thePointersPlaceComesFromTheAccess() {
        let access = FakeSystemAccess()
        access.pointerLocation = ScreenPoint(x: 3, y: 4)
        let system = AccessibilityWindowSystem(
            access: access, captureService: FakeCaptureService())
        #expect(system.pointerLocation == ScreenPoint(x: 3, y: 4))
    }

    @Test func watchingThePointerCanStartAgainAndStop() {
        let system = AccessibilityWindowSystem(
            access: FakeSystemAccess(), captureService: FakeCaptureService())
        system.startWatchingPointer(every: 60) {}
        system.startWatchingPointer(every: 60) {}
        system.stopWatchingPointer()
    }

    @Test func aRecordThatCannotBeWrittenLeavesNothing() throws {
        let file = FileManager.default.temporaryDirectory
            .appending(path: "PairwiseTests-\(UUID().uuidString)")
        try Data().write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        let system = AccessibilityWindowSystem(
            access: FakeSystemAccess(), captureService: FakeCaptureService(), recordsFolder: file)
        system.savePairsRecord(Data("x".utf8))
        #expect(system.loadPairsRecord() == nil)
    }

    private func description(number: Int, process: Int32, title: String?) -> [String: Any] {
        var description: [String: Any] = [
            kCGWindowNumber as String: CGWindowID(number),
            kCGWindowOwnerPID as String: process,
            kCGWindowLayer as String: 0,
            kCGWindowBounds as String: CGRect(x: 1, y: 2, width: 3, height: 4)
                .dictionaryRepresentation,
        ]
        description[kCGWindowName as String] = title
        return description
    }

    @Test func windowIdentitiesSayWhatTheWindowServerAndAppSay() throws {
        let access = FakeSystemAccess()
        access.appIdentifiers[7] = "app.one"
        access.windows = [description(number: 5, process: 7, title: "Private")]
        let system = AccessibilityWindowSystem(
            access: access, captureService: FakeCaptureService())
        let identity = try #require(system.windowIdentities().first)
        #expect(identity.number == 5)
        #expect(identity.owner == 7)
        #expect(identity.app == "app.one")
        #expect(identity.frame == WindowFrame(x: 1, y: 2, width: 3, height: 4))
        #expect(identity.titleKey != nil && identity.titleKey != "Private")
    }

    @Test func windowIdentitiesLeaveOutPairwisesOwnAndOtherLayers() {
        let access = FakeSystemAccess()
        var menu = description(number: 6, process: 7, title: nil)
        menu[kCGWindowLayer as String] = 25
        access.windows = [
            description(number: 5, process: access.ownProcess, title: nil), menu,
        ]
        let system = AccessibilityWindowSystem(
            access: access, captureService: FakeCaptureService())
        #expect(system.windowIdentities().isEmpty)
    }

    @Test func theRealAccessKnowsThePointerAndThisApp() {
        let access = LiveSystemAccess()
        _ = access.pointerLocation
        #expect(access.appIdentifier(of: -1) == nil)
    }

    @Test func aDeadElementHasNoAttributes() {
        let element = AXUIElementCreateApplication(-1)
        #expect(element.attributeNames.isEmpty)
    }
}
