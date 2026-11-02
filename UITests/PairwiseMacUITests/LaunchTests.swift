import XCTest

/// Starts the app and checks its window. Touches no other app's windows.
final class LaunchTests: XCTestCase {
    private static let launchTimeout: TimeInterval = 10
    /// How long the app has to quit by itself, if it would.
    private static let stayTime: TimeInterval = 3

    @MainActor
    func testShowsWindow() {
        let app = XCUIApplication()
        app.launchArguments = ["--show-settings"]
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: Self.launchTimeout))
        XCTAssertEqual(app.windows.firstMatch.title, "Pairwise")
        app.terminate()
    }

    /// A menu bar app has no window open, and must go on running without one.
    @MainActor
    func testKeepsRunningWithoutAWindow() {
        let app = XCUIApplication()
        app.launch()
        let quit = XCTNSPredicateExpectation(
            predicate: NSPredicate(
                format: "state == %d", XCUIApplication.State.notRunning.rawValue),
            object: app)
        XCTAssertEqual(XCTWaiter().wait(for: [quit], timeout: Self.stayTime), .timedOut)
        app.terminate()
    }
}
