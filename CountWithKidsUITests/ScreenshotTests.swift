import XCTest

@MainActor
final class ScreenshotTests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        setupSnapshot(app)
        app.launch()
    }

    func testCaptureScreenshots() {
        // 1. Practice tab (default on launch)
        snapshot("01_Practice")

        // 2. Settings tab — shows theme picker
        app.tabBars.buttons.element(boundBy: 2).tap()
        sleep(1)
        snapshot("02_Settings")

        // 3. Back to Practice — start a session
        app.tabBars.buttons.element(boundBy: 0).tap()
        sleep(1)

        // Tap the start/play button
        let startButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Start' OR label CONTAINS[c] 'Play' OR label CONTAINS[c] 'Go'")).firstMatch
        if startButton.waitForExistence(timeout: 3) {
            startButton.tap()
            sleep(2)
            snapshot("03_PracticeInProgress")
        }

        // 4. Dashboard tab
        app.tabBars.buttons.element(boundBy: 1).tap()
        sleep(1)
        snapshot("04_Dashboard")
    }
}
