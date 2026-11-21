import XCTest

/// Actual shortened first-run flow, isolated from the user's preferences. Checks
/// draft backtracking, editor discard protection and identity persistence.
final class OnboardingBacktrackingTests: XCTestCase {
    private var app: XCUIApplication!
    private var suite = ""

    override func setUpWithError() throws {
        continueAfterFailure = false
        suite = "LockedIN.ui-tests.onboarding-apartment.\(UUID().uuidString)"
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app.launchArguments = ["-ui-test-suite", suite, "-ui-test-reset", "-ui-test-cleanup"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ui-test.cleaned"].waitForExistence(timeout: 15))
        app.terminate()
    }

    private func launch(largestText: Bool = false, reset: Bool = true) {
        app.launchArguments = ["-ui-test-suite", suite, "-ui-test-reduce-motion"]
        if reset { app.launchArguments += ["-ui-test-reset"] }
        if largestText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        app.launch()
    }

    private func tap(_ identifier: String) {
        let button = app.buttons[identifier].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 15), "Missing \(identifier)")
        for _ in 0..<6 where !button.isHittable { app.scrollViews.firstMatch.swipeUp() }
        XCTAssertTrue(button.isHittable)
        XCTAssertTrue(button.isEnabled)
        if identifier == "onboarding.continue" {
            // A single exact-centre tap: no retry fallback after navigation misses.
            button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        } else {
            button.tap()
        }
    }

    private func revealHorizontal(_ button: XCUIElement, in rail: XCUIElement) {
        XCTAssertTrue(rail.waitForExistence(timeout: 15))
        XCTAssertTrue(button.waitForExistence(timeout: 15))
        for _ in 0..<8 {
            if button.isHittable && button.frame.minX >= rail.frame.minX &&
                button.frame.maxX <= rail.frame.maxX { return }
            if button.frame.midX > rail.frame.midX { rail.swipeLeft() }
            else { rail.swipeRight() }
        }
        XCTFail("Could not reveal horizontal option \(button.identifier)")
    }

    private func category(_ identifier: String) {
        let button = app.buttons["avatar.category.\(identifier)"]
        revealHorizontal(button, in: app.scrollViews["avatar.categories"])
        button.tap()
    }

    private func option(_ identifier: String) {
        let button = app.buttons[identifier]
        revealHorizontal(button, in: app.scrollViews["avatar.options"])
        button.tap()
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCreatorDraftBacktrackingAndSavedIdentity() {
        launch()
        XCTAssertTrue(app.progressIndicators["onboarding.progress"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["Skip introduction"].exists)
        XCTAssertFalse(app.buttons["onboarding.avatar.maya"].exists)
        capture("apartment-welcome")
        tap("onboarding.continue")
        XCTAssertTrue(app.buttons["avatar.skin.yellow"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["avatar.skin.yellow"].isSelected)
        capture("apartment-creator-yellow-starter")
        tap("avatar.skin.deep")
        tap("avatar.presentation.feminine")
        category("hair")
        option("avatar.hair.afro")
        capture("apartment-creator-free-hair")
        tap("avatar.continue")

        let name = app.textFields["onboarding.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 15))
        name.tap()
        name.typeText("River")
        tap("onboarding.back")
        XCTAssertTrue(app.buttons["avatar.skin.deep"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["avatar.skin.deep"].isSelected)
        XCTAssertTrue(app.buttons["avatar.presentation.feminine"].isSelected)
        // Only the editor's committed draft should survive returning to Welcome.
        tap("avatar.skin.light")
        tap("avatar.close")
        tap("avatar.keepEditing")
        XCTAssertTrue(app.buttons["avatar.skin.light"].isSelected)
        tap("avatar.close")
        tap("avatar.discard")
        tap("onboarding.continue")
        XCTAssertTrue(app.buttons["avatar.skin.deep"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["avatar.skin.deep"].isSelected)
        category("hair")
        XCTAssertTrue(app.buttons["avatar.hair.afro"].isSelected)
        tap("avatar.continue")
        XCTAssertTrue(name.waitForExistence(timeout: 15))
        XCTAssertEqual(name.value as? String, "River")
        tap("onboarding.continue")
        XCTAssertTrue(app.buttons["onboarding.finish"].waitForExistence(timeout: 15))
        capture("apartment-room-arrival")
        tap("onboarding.finish")
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 30))

        app.terminate()
        launch(reset: false)
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 30))
        XCTAssertFalse(app.buttons["onboarding.continue"].exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "River")).firstMatch.exists)
        app.tabBars.buttons["Profile"].tap()
        tap("Edit avatar")
        XCTAssertTrue(app.buttons["avatar.skin.deep"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["avatar.skin.deep"].isSelected)
        XCTAssertTrue(app.buttons["avatar.presentation.feminine"].isSelected)
        category("hair")
        XCTAssertTrue(app.buttons["avatar.hair.afro"].isSelected)
        capture("apartment-identity-restored")
    }

    func testNamedIdentityBeforeArrivalKeepsItsLookAfterRelaunch() {
        launch()
        tap("onboarding.continue")
        tap("avatar.skin.dark")
        tap("avatar.presentation.feminine")
        tap("avatar.continue")
        let name = app.textFields["onboarding.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 15))
        name.tap()
        name.typeText("Robin")
        tap("onboarding.continue")
        XCTAssertTrue(app.buttons["onboarding.finish"].waitForExistence(timeout: 15))
        // Identity is saved at naming, but the introduction is not yet complete.
        // Returning to the introduction must not replace it with a yellow starter.
        app.terminate()
        launch(reset: false)
        tap("onboarding.continue")
        XCTAssertTrue(app.buttons["avatar.skin.dark"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["avatar.skin.dark"].isSelected)
        XCTAssertTrue(app.buttons["avatar.presentation.feminine"].isSelected)
        tap("avatar.continue")
        XCTAssertTrue(name.waitForExistence(timeout: 15))
        XCTAssertEqual(name.value as? String, "Robin")
        capture("apartment-partial-introduction-identity-restored")
    }

    func testShortIntroductionAtLargestText() {
        launch(largestText: true)
        XCTAssertTrue(app.progressIndicators["onboarding.progress"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["Skip introduction"].exists)
        capture("apartment-welcome-largest-text")
        tap("onboarding.continue")
        XCTAssertTrue(app.buttons["avatar.skin.yellow"].waitForExistence(timeout: 15))
        capture("apartment-creator-largest-text")
        let randomize = app.buttons["avatar.randomize"]
        let next = app.buttons["avatar.continue"]
        for _ in 0..<8 {
            if randomize.isHittable && randomize.frame.maxY < next.frame.minY - 8 { break }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(randomize.isHittable)
        XCTAssertLessThan(randomize.frame.maxY, next.frame.minY - 8)
        randomize.tap()
        capture("apartment-creator-largest-text-scrolled-controls")
        tap("avatar.continue")
        XCTAssertTrue(app.textFields["onboarding.name"].waitForExistence(timeout: 15))
        tap("onboarding.continue")
        capture("apartment-arrival-largest-text")
        tap("onboarding.finish")
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 30))
    }
}
