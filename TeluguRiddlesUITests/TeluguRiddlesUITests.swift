import XCTest

final class TeluguRiddlesUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testHomeScreenLoadsWithStartButton() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["తెలుగు పొడుపు కథలు"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["ఆట ప్రారంభించు"].exists)
    }

    func testEnglishModeChangesCommonControlsToEnglish() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.buttons["English"].waitForExistence(timeout: 5))
        app.buttons["English"].tap()

        XCTAssertTrue(app.staticTexts["Game Options"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.buttons["Start Game"].exists)
    }
}
