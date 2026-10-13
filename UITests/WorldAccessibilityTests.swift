import XCTest

/// Uses a disposable preferences suite; never resets the installed user's saves.
final class WorldAccessibilityTests: XCTestCase {
    private var app: XCUIApplication!
    private var suite = ""

    override func setUpWithError() throws {
        continueAfterFailure = false
        suite = "LockedIN.ui-tests.world.\(UUID().uuidString)"
        app = XCUIApplication()
        app.launchArguments = ["-smoke-room", "home", "-ui-test-suite", suite, "-ui-test-reduce-motion",
                               "-ui-test-reset", "-UIPreferredContentSizeCategoryName",
                               "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 30))
    }

    override func tearDownWithError() throws {
        app.terminate()
        app.launchArguments = ["-ui-test-suite", suite, "-ui-test-reset", "-ui-test-cleanup"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ui-test.cleaned"].waitForExistence(timeout: 15))
        app.terminate()
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func reveal(_ element: XCUIElement) {
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<12 {
            if element.exists && element.isHittable && element.frame.maxY < app.frame.maxY - 24 { return }
            let aboveViewport = element.exists && element.frame.midY < scroll.frame.minY
            // Small drags avoid skipping the first grid tile after dismissing an editor.
            let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: aboveViewport ? 0.35 : 0.7))
            let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: aboveViewport ? 0.7 : 0.35))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "world-reveal-failure-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        capture("world-reveal-failure")
        XCTAssertTrue(element.isHittable)
    }

    func testLargestTextWorldDistrictAndRoomJourney() {
        app.buttons["0 coins. View progress"].tap()
        XCTAssertTrue(app.buttons["world.back"].waitForExistence(timeout: 15))
        capture("world-largest-header")

        let decorate = app.buttons["Customise room"]
        reveal(decorate)
        decorate.tap()
        XCTAssertTrue(app.buttons["room.done"].waitForExistence(timeout: 15))
        app.buttons["room.done"].tap()
        XCTAssertTrue(app.buttons["world.back"].waitForExistence(timeout: 15))

        let library = app.descendants(matching: .any).matching(identifier: "world.building.libraryHub").firstMatch
        reveal(library)
        XCTAssertEqual(library.label, "Library Hub")
        XCTAssertTrue(library.isSelected)
        library.tap()
        XCTAssertTrue(app.staticTexts["Your next session will help grow Library Hub."].exists)
        capture("world-largest-library")

        let cafe = app.descendants(matching: .any).matching(identifier: "world.building.languageCafe").firstMatch
        reveal(cafe)
        XCTAssertEqual(cafe.value as? String, "Locked")
        XCTAssertFalse(cafe.isEnabled)
        // Accessibility sizes use one full-width column, preserving room for names.
        XCTAssertGreaterThan(cafe.frame.width, app.frame.width * 0.7)
        capture("world-largest-locked-plots")

        let courtyard = app.descendants(matching: .any).matching(identifier: "world.building.courtyard").firstMatch
        reveal(courtyard)
        XCTAssertEqual(courtyard.label, "Student Courtyard")
        XCTAssertFalse(courtyard.isEnabled)
        app.scrollViews.firstMatch.swipeUp()
        capture("world-largest-stats")
        app.buttons["world.back"].tap()
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 15))
    }
}
