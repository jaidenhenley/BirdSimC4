import XCTest

final class BirdSimUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    func testMainMenuButtonsPresent() {
        XCTAssertTrue(app.buttons["Resume Game"].exists)
        XCTAssertTrue(app.buttons["Start New Game"].exists)
        XCTAssertTrue(app.buttons["Instructions"].exists)
        XCTAssertTrue(app.buttons["Settings"].exists)
    }

    func testInstructionsSheetPresentationAndDismiss() {
        app.buttons["Instructions"].tap()

        let title = app.staticTexts["Survival Guide"]
        XCTAssertTrue(title.waitForExistence(timeout: 3.0))

        let doneButton = app.buttons["Ready to Fly"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 2.0))
        doneButton.tap()

        XCTAssertTrue(app.buttons["Instructions"].waitForExistence(timeout: 2.0))
    }

    func testSettingsSheetPresentationAndDismiss() {
        app.buttons["Settings"].tap()

        let title = app.staticTexts["Settings"]
        XCTAssertTrue(title.waitForExistence(timeout: 3.0))

        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.waitForExistence(timeout: 2.0))
        doneButton.tap()

        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 2.0))
    }

    func testStartNewGameLeavesMenu() {
        app.buttons["Start New Game"].tap()

        let menuButton = app.buttons["Start New Game"]
        let menuGonePredicate = NSPredicate(format: "exists == false")
        expectation(for: menuGonePredicate, evaluatedWith: menuButton, handler: nil)
        waitForExpectations(timeout: 3.0)
    }
}
