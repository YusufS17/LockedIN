import XCTest

final class WorldRecoveryTests: XCTestCase {
    private var app: XCUIApplication!
    private var suite = ""

    override func setUpWithError() throws {
        continueAfterFailure = false
        suite = "LockedIN.ui-tests.recovery.\(UUID().uuidString)"
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app.launchArguments = ["-ui-test-suite", suite, "-ui-test-reset", "-ui-test-cleanup"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ui-test.cleaned"].waitForExistence(timeout: 15))
        app.terminate()
    }

    private func launch(seed: Bool, pendingResults: Bool) {
        app.launchArguments = ["-smoke-room", "home", "-ui-test-suite", suite, "-ui-test-reduce-motion"]
        if seed { app.launchArguments += ["-ui-test-reset", "-ui-test-world-corrupt"] }
        if seed && pendingResults { app.launchArguments += ["-ui-test-pending-results"] }
        app.launch()
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 30))
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testUnreadableWorldPausesNewStudyAndHidesSeededProgress() {
        launch(seed: true, pendingResults: false)
        XCTAssertTrue(app.staticTexts["Your saved world needs attention"].exists)
        XCTAssertFalse(app.buttons["study.start"].isEnabled)
        XCTAssertFalse(app.staticTexts["Your study room"].exists)
        capture("recovery-home")
        app.buttons["Saved world unavailable. View details"].tap()
        XCTAssertTrue(app.buttons["world.back"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Your saved world needs attention"].exists)
        XCTAssertFalse(app.buttons["world.building.libraryHub"].exists)
        capture("recovery-world")
        app.buttons["world.back"].tap()
        app.terminate()
        launch(seed: false, pendingResults: false)
        XCTAssertFalse(app.buttons["study.start"].isEnabled)
    }

    func testPendingResultsSurviveReturningHomeWhenWorldCannotSave() {
        launch(seed: true, pendingResults: true)
        XCTAssertTrue(app.buttons["study.start"].isEnabled)
        XCTAssertEqual(app.buttons["study.start"].label, "View your results")
        app.buttons["study.start"].tap()
        XCTAssertTrue(app.staticTexts["Your results are kept"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Reward not saved yet"].exists)
        XCTAssertEqual(app.staticTexts["study.coins"].label, "+0 coins")
        let done = app.buttons["study.done"]
        for _ in 0..<10 {
            if done.exists && done.isHittable { break }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(done.isHittable)
        capture("recovery-results-kept")
        done.tap()
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.buttons["study.start"].label, "View your results")
        app.terminate()
        launch(seed: false, pendingResults: true)
        XCTAssertEqual(app.buttons["study.start"].label, "View your results")
        app.buttons["study.start"].tap()
        XCTAssertTrue(app.staticTexts["Your results are kept"].waitForExistence(timeout: 15))
    }
}
