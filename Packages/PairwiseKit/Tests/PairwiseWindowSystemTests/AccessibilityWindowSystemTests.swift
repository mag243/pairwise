import ApplicationServices
import CoreGraphics
import PairwiseCore
import Testing

@testable import PairwiseWindowSystem

@MainActor
@Suite struct AccessibilityWindowSystemTests {
    private static let rect = CGRect(x: 100, y: 100, width: 300, height: 200)
    private static let onWindow = ScreenPoint(x: 150, y: 110)
    private static let finder = "com.apple.finder"

    private let access = FakeSystemAccess()
    private let system: AccessibilityWindowSystem

    init() {
        system = AccessibilityWindowSystem(access: access)
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

    @Test func thePartnerIsAWindowOfTheChosenApp() throws {
        let element = addWindow()
        access.bundleProcesses[Self.finder] = [5]
        let dragged = FakeElement.window(frame: Self.rect)
        let window = AccessibilityWindow(element: dragged, access: access)
        let partner = try #require(try system.partner(for: window) as? AccessibilityWindow)
        #expect(partner.element.isSame(as: element))
    }

    @Test func thePartnerIsNotTheDraggedWindow() {
        let element = addWindow()
        access.bundleProcesses[Self.finder] = [5]
        let window = AccessibilityWindow(element: element, access: access)
        #expect(throws: WindowSystemError.noPartner) { try system.partner(for: window) }
    }

    @Test func aMinimizedWindowIsNoPartner() {
        let element = addWindow()
        element.attributes[kAXMinimizedAttribute] = kCFBooleanTrue
        access.bundleProcesses[Self.finder] = [5]
        let window = AccessibilityWindow(element: FakeElement(), access: access)
        #expect(throws: WindowSystemError.noPartner) { try system.partner(for: window) }
    }

    @Test func anAppThatIsNotRunningGivesNoPartner() {
        let window = AccessibilityWindow(element: FakeElement(), access: access)
        #expect(throws: WindowSystemError.noPartner) { try system.partner(for: window) }
    }

    @Test func aPinnedPartnerGoesFirst() throws {
        let pinned = AccessibilityWindow(element: FakeElement(), access: access)
        system.pinnedPartner = pinned
        let window = AccessibilityWindow(element: FakeElement(), access: access)
        #expect(try system.partner(for: window) === pinned)
    }

    @Test func thePartnerAppsAreInOrderOfName() {
        access.runningApps = [
            PartnerApp(bundleIdentifier: "b", name: "Zed"),
            PartnerApp(bundleIdentifier: "a", name: "Arc"),
        ]
        #expect(system.partnerApps.map(\.name) == ["Arc", "Zed"])
    }

    @Test func parkingIsPastAllDisplays() {
        access.displayFrames = [WindowFrame(x: 0, y: 0, width: 100, height: 50)]
        #expect(system.parkingOrigin == ScreenPoint(x: 99, y: 49))
    }
}
