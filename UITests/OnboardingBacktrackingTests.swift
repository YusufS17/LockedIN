import XCTest

/// Exercises the actual first-run flow in disposable storage, including the
/// customizer's existing discard protection and the gallery's base replacement.
final class OnboardingBacktrackingTests: XCTestCase {
    private var app: XCUIApplication!
    private var suite = ""

    override func setUpWithError() throws {
        continueAfterFailure = false
        suite = "LockedIN.ui-tests.\(UUID().uuidString)"
        app = XCUIApplication()
        app.launchArguments = ["-ui-test-suite", suite, "-ui-test-reset"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app.launchArguments = ["-ui-test-suite", suite, "-ui-test-reset", "-ui-test-cleanup"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ui-test.cleaned"].waitForExistence(timeout: 15))
        app.terminate()
    }

    private func tap(_ identifier: String) {
        let button = app.buttons[identifier].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 15), "Missing \(identifier)")
        for _ in 0..<5 where !button.isHittable { app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(button.isHittable)
        button.tap()
    }

    private func topCategory() {
        let rail = app.scrollViews["avatar.categories"]
        XCTAssertTrue(rail.waitForExistence(timeout: 15))
        let button = app.buttons["avatar.category.top"]
        for _ in 0..<5 {
            if button.frame.minX >= rail.frame.minX + 2 && button.frame.maxX <= rail.frame.maxX - 2 { break }
            let movingLeft = button.frame.midX > rail.frame.midX
            let start = rail.coordinate(withNormalizedOffset: CGVector(dx: movingLeft ? 0.7 : 0.3, dy: 0.5))
            let end = rail.coordinate(withNormalizedOffset: CGVector(dx: movingLeft ? 0.4 : 0.6, dy: 0.5))
            start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
        }
        button.tap()
        XCTAssertTrue(button.isSelected)
    }

    private func backToGalleryFromReveal() {
        tap("onboarding.back")
        tap("avatar.close")
        XCTAssertTrue(app.buttons["onboarding.continue"].waitForExistence(timeout: 15))
    }

    func testCustomisedBaseBacktrackingReplacementAndRelaunch() {
        tap("onboarding.continue")
        tap("onboarding.continue")
        tap("onboarding.continue")
        topCategory()
        tap("Jacket")
        tap("avatar.save")

        backToGalleryFromReveal()
        tap("onboarding.continue")
        topCategory()
        XCTAssertTrue(app.buttons["Jacket, selected"].waitForExistence(timeout: 15))
        // Uncommitted editor changes still have their separate discard protection.
        tap("Tee")
        tap("avatar.close")
        tap("avatar.keepEditing")
        XCTAssertTrue(app.buttons["Tee, selected"].exists)
        tap("avatar.close")
        tap("avatar.discard")

        tap("onboarding.avatar.leo")
        tap("onboarding.continue")
        tap("onboarding.keepLook")
        XCTAssertTrue(app.buttons["onboarding.avatar.maya"].isSelected)
        tap("onboarding.continue")
        topCategory()
        XCTAssertTrue(app.buttons["Jacket, selected"].waitForExistence(timeout: 15))
        tap("avatar.close")

        tap("onboarding.avatar.leo")
        tap("onboarding.continue")
        tap("onboarding.replaceLook")
        topCategory()
        XCTAssertTrue(app.buttons["Hoodie, selected"].waitForExistence(timeout: 15))
        tap("Jacket")
        tap("avatar.save")
        let name = app.textFields["onboarding.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 15))
        name.tap()
        name.typeText(" River")
        tap("onboarding.continue")
        tap("onboarding.finish")
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 30))

        app.terminate()
        app.launchArguments = ["-ui-test-suite", suite]
        app.launch()
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 30))
        XCTAssertFalse(app.buttons["onboarding.continue"].exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "River")).firstMatch.exists)
        tap("Edit avatar")
        topCategory()
        XCTAssertTrue(app.buttons["Jacket, selected"].waitForExistence(timeout: 15))
    }
}
