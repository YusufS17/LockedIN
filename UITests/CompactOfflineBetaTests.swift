import XCTest

/// Real screens on the existing compact iPhone16e; the clock advance and storage
/// suite are isolated fixtures. This is not a physical-device or attention test.
final class CompactOfflineBetaTests: XCTestCase {
    private var app: XCUIApplication!
    private var suite = ""

    override func setUpWithError() throws {
        continueAfterFailure = false
        suite = "LockedIN.ui-tests.compact.\(UUID().uuidString)"
        app = XCUIApplication()
        launch(reset: true)
        XCTAssertLessThanOrEqual(app.frame.width, 375, "Run compact acceptance on iPhone16e or a smaller existing phone")
    }

    override func tearDownWithError() throws {
        app.terminate()
        app.launchArguments = ["-ui-test-suite", suite, "-ui-test-reset", "-ui-test-cleanup"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ui-test.cleaned"].waitForExistence(timeout: 15))
        app.terminate()
    }

    private func launch(reset: Bool = false, elapsed: Int = 0) {
        app.launchArguments = ["-smoke-room", "home", "-ui-test-suite", suite]
        if reset { app.launchArguments += ["-ui-test-reset"] }
        if elapsed > 0 { app.launchArguments += ["-ui-test-elapsed", String(elapsed)] }
        app.launch()
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 30))
    }

    private func reveal(_ element: XCUIElement) {
        for _ in 0..<10 {
            let dock = app.buttons["study.break"].exists ? app.buttons["study.break"] : app.buttons["study.start"]
            let clearOfDock = !dock.exists || element.frame.maxY < dock.frame.minY - 8
            if element.exists && element.isHittable && clearOfDock { return }
            app.scrollViews.firstMatch.swipeUp()
        }
        let tree = XCTAttachment(string: app.debugDescription)
        tree.name = "compact-navigation-failure"
        tree.lifetime = .keepAlways
        add(tree)
        XCTAssertTrue(element.isHittable)
    }

    private func tap(_ identifier: String) {
        let button = app.buttons[identifier].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 15), "Missing \(identifier)")
        // Pinned actions are already visible; content routes need to clear the dock.
        if !["study.start", "study.break", "room.done", "world.back"].contains(identifier) { reveal(button) }
        button.tap()
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCompactStudyResultsAndUpgradeSurviveRelaunch() {
        capture("compact-home")
        tap("study.start")
        let goal = app.descendants(matching: .any).matching(identifier: "study.goal").firstMatch
        XCTAssertTrue(goal.waitForExistence(timeout: 15))
        goal.tap()
        goal.typeText("Review one paragraph")
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }
        capture("compact-setup")
        tap("study.begin")
        XCTAssertTrue(app.buttons["study.break"].waitForExistence(timeout: 15))
        capture("compact-focus")
        tap("study.break")
        XCTAssertEqual(app.buttons["study.break"].label, "Back to focus")
        capture("compact-break")
        app.terminate()
        launch()
        tap("study.start")
        XCTAssertEqual(app.buttons["study.break"].label, "Back to focus")
        tap("study.break")
        app.terminate()
        launch(elapsed: 1600)
        tap("study.start")
        capture("compact-goal-check")
        tap("study.review.partly")
        XCTAssertTrue(app.staticTexts["study.coins"].waitForExistence(timeout: 15))
        // Interrupt presentation with a process relaunch; persisted rewards must not replay.
        app.terminate()
        launch()
        XCTAssertEqual(app.buttons["study.start"].label, "View your results")
        tap("study.start")
        XCTAssertTrue(app.buttons["room.buySuggested"].waitForExistence(timeout: 15))
        let coins = app.staticTexts["study.coins"].label
        XCTAssertNotEqual(coins, "+0 coins")
        capture("compact-results")
        tap("View world")
        XCTAssertTrue(app.buttons["world.back"].waitForExistence(timeout: 15))
        capture("compact-world")
        tap("world.back")
        XCTAssertTrue(app.buttons["room.buySuggested"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts["study.coins"].label, coins)
        tap("room.buySuggested")
        XCTAssertTrue(app.staticTexts["room.purchaseConfirmation"].waitForExistence(timeout: 15))
        capture("compact-earned-upgrade")
        tap("study.done")
        XCTAssertEqual(app.buttons["study.start"].label, "Start studying")
        app.terminate()
        launch()
        XCTAssertEqual(app.buttons["study.start"].label, "Start studying")
        tap("Decorate")
        tap("room.category.rug")
        XCTAssertTrue(app.buttons["room.item.rug.teal"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["room.item.rug.teal"].isSelected)
        capture("compact-persisted-upgrade")
        tap("room.done")
    }
}
