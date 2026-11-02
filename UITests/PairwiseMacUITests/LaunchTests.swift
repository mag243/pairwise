import XCTest

/// Starts the app and checks its window. Touches no other app's windows.
final class LaunchTests: XCTestCase {
    private static let launchTimeout: TimeInterval = 10

    @MainActor
    func testShowsWindow() {
        let app = XCUIApplication()
        app.launchArguments = ["--show-settings"]
        app.launch()
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: Self.launchTimeout))
        XCTAssertEqual(app.windows.firstMatch.title, "Pairwise")
        app.terminate()
    }
}
