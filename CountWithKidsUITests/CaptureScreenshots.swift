import XCTest

@MainActor
final class CaptureScreenshots: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    private func saveScreenshot(_ name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func switchLanguage(to langName: String) {
        // Go to Settings tab
        app.tabBars.buttons.element(boundBy: 2).tap()
        sleep(1)

        // Swipe up in the form to reveal language section
        let form = app.collectionViews.firstMatch
        if form.exists {
            form.swipeUp()
        } else {
            app.swipeUp()
        }
        sleep(1)

        // Tap the Language picker row (it's a navigation-style picker in a Form)
        let langRow = app.staticTexts[langName]
        if langRow.waitForExistence(timeout: 3) {
            langRow.tap()
            sleep(1)
        } else {
            // Try tapping the picker row that shows current language
            let picker = app.cells.containing(.staticText, identifier: "Language").firstMatch
            if picker.waitForExistence(timeout: 2) {
                picker.tap()
                sleep(1)
                let option = app.staticTexts[langName]
                if option.waitForExistence(timeout: 2) {
                    option.tap()
                    sleep(1)
                }
                // Go back if we navigated
                if app.navigationBars.buttons.firstMatch.exists {
                    app.navigationBars.buttons.firstMatch.tap()
                    sleep(1)
                }
            }
        }
    }

    private func captureAllScreens(prefix: String) {
        // 1. Practice tab
        app.tabBars.buttons.element(boundBy: 0).tap()
        sleep(1)
        saveScreenshot("\(prefix)_01_Practice")

        // 2. Tap Start button (find any button with "!" which all languages have)
        let buttons = app.buttons.allElementsBoundByIndex
        for btn in buttons {
            if btn.exists && btn.isHittable && btn.label.contains("!") {
                btn.tap()
                sleep(2)
                saveScreenshot("\(prefix)_02_PracticeInProgress")
                break
            }
        }

        // 3. Dashboard tab
        app.tabBars.buttons.element(boundBy: 1).tap()
        sleep(1)
        saveScreenshot("\(prefix)_03_Dashboard")

        // 4. Settings tab
        app.tabBars.buttons.element(boundBy: 2).tap()
        sleep(1)
        saveScreenshot("\(prefix)_04_Settings")
    }

    // MARK: - Test Methods

    func testA_CaptureEnglishScreenshots() {
        captureAllScreens(prefix: "en-US")
    }

    func testB_CaptureCzechScreenshots() {
        switchLanguage(to: "Čeština")
        sleep(1)
        captureAllScreens(prefix: "cs")
    }

    func testC_CaptureHebrewScreenshots() {
        switchLanguage(to: "עברית")
        sleep(1)
        captureAllScreens(prefix: "he")
        // Switch back to English
        switchLanguage(to: "English")
    }
}
