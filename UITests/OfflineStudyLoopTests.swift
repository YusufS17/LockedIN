import XCTest

final class OfflineStudyLoopTests: XCTestCase {
    private var app: XCUIApplication!
    private var suite = ""

    override func setUpWithError() throws {
        continueAfterFailure = false
        suite = "LockedIN.ui-tests.\(UUID().uuidString)"
        app = XCUIApplication()
        // Onboarding tests launch their own first-run configuration.
        if !name.contains("testOnboarding") { launch(reset: true) }
    }

    override func tearDownWithError() throws {
        app.terminate()
        // Clear the isolated suite through a lightweight Debug route. Avoid
        // rendering another complete Home just to discard disposable fixtures.
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

    private func tap(_ identifier: String) {
        let button = app.buttons[identifier].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 15), "Missing button: \(identifier)")
        for _ in 0..<6 {
            // Scroll content can report hittable behind the pinned break button.
            // Bring the full participant control above that inset before tapping.
            let coveredByBreak = identifier == "study.participants" &&
                button.frame.maxY > app.buttons["study.break"].frame.minY - 12
            let coveredByStart = identifier == "study.club" &&
                button.frame.maxY > app.buttons["study.start"].frame.minY - 12
            if button.isHittable && !coveredByBreak && !coveredByStart { break }
            app.swipeUp()
        }
        XCTAssertTrue(button.isHittable)
        button.tap()
    }

    private func capture(_ name: String) {
        // Allow short SwiftUI text/button transitions to settle for visual review.
        Thread.sleep(forTimeInterval: 0.7)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func startStudy() {
        tap("study.start")
        let goal = app.descendants(matching: .any).matching(identifier: "study.goal").firstMatch
        XCTAssertTrue(goal.waitForExistence(timeout: 15))
        goal.tap()
        goal.typeText("Finish chapter four")
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }
        tap("study.begin")
        XCTAssertTrue(app.buttons["study.break"].waitForExistence(timeout: 15))
    }

    func testOnboardingArrivalAndSavedIdentity() {
        app.terminate()
        app.launchArguments = ["-ui-test-suite", suite, "-ui-test-reset"]
        app.launch()
        tap("onboarding.continue")
        capture("onboarding-02-value")
        tap("onboarding.continue")
        capture("onboarding-03-gallery")
        tap("onboarding.continue")
        tap("Save avatar")
        let name = app.textFields["onboarding.name"]
        XCTAssertTrue(name.waitForExistence(timeout: 15))
        name.tap()
        name.typeText(" River")
        capture("onboarding-05-name")
        tap("onboarding.continue")
        capture("onboarding-06-arrival")
        tap("onboarding.finish")
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 15))
        app.terminate()
        app.launchArguments = ["-ui-test-suite", suite]
        app.launch()
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["onboarding.continue"].exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "River")).firstMatch.exists)
        capture("onboarding-07-saved-home")
    }

    func testOnboardingAtLargestAccessibilitySize() {
        app.terminate()
        app.launchArguments = ["-ui-test-suite", suite, "-ui-test-reset",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        capture("accessibility-welcome-largest")
        tap("onboarding.continue")
        capture("accessibility-value-largest")
        tap("onboarding.continue")
        capture("accessibility-gallery-largest")
        tap("onboarding.continue")
        tap("Save avatar")
        capture("accessibility-name-largest")
        tap("onboarding.continue")
        capture("accessibility-arrival-largest")
        tap("onboarding.finish")
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 15))
    }

    func testHomeAndSetupAtLargestAccessibilitySize() {
        app.terminate()
        app.launchArguments = ["-smoke-room", "home", "-ui-test-suite", suite,
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 30))
        capture("accessibility-home-largest")
        tap("study.start")
        let goal = app.descendants(matching: .any).matching(identifier: "study.goal").firstMatch
        XCTAssertTrue(goal.waitForExistence(timeout: 15))
        goal.tap()
        goal.typeText("Review my notes")
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }
        capture("accessibility-setup-largest")
        tap("study.begin")
        XCTAssertTrue(app.buttons["study.break"].waitForExistence(timeout: 15))
        capture("accessibility-focus-largest")
        app.swipeUp()
        capture("accessibility-room-largest")
        app.swipeDown()
        tap("study.break")
        capture("accessibility-break-largest")
        tap("study.break")
        app.terminate()
        app.launchArguments += ["-ui-test-elapsed", "1600"]
        app.launch()
        tap("study.start")
        capture("accessibility-check-in-largest")
        tap("study.review.partly")
        XCTAssertTrue(app.staticTexts["study.coins"].waitForExistence(timeout: 15))
        capture("accessibility-results-largest")
        app.swipeUp()
        capture("accessibility-result-details-largest")
    }

    func testStudyRestoreGoalRewardAndUpgrade() {
        capture("01-home")
        startStudy()
        capture("02-focus")
        tap("study.break")
        XCTAssertEqual(app.buttons["study.break"].label, "Back to focus")
        capture("03-break")
        app.terminate()
        launch()
        XCTAssertTrue(app.buttons["study.start"].label.contains("Return to your session"))
        tap("study.start")
        XCTAssertTrue(app.buttons["study.break"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.buttons["study.break"].label, "Back to focus")
        tap("study.break")
        // Advance only the disposable save's restoration date. Production timers stay real.
        app.terminate()
        launch(elapsed: 1600)
        XCTAssertTrue(app.buttons["study.start"].label.contains("Finish your check-in"))
        tap("study.start")
        capture("04-goal-check")
        tap("study.review.partly")
        XCTAssertTrue(app.staticTexts["study.coins"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["room.buySuggested"].waitForExistence(timeout: 15))
        let balance = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "You have ")).firstMatch.label
        app.terminate()
        launch()
        XCTAssertTrue(app.buttons["study.start"].label.contains("View your results"))
        tap("study.start")
        XCTAssertTrue(app.buttons["room.buySuggested"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "You have ")).firstMatch.label, balance)
        tap("room.buySuggested")
        XCTAssertTrue(app.staticTexts["room.purchaseConfirmation"].waitForExistence(timeout: 15))
        capture("05-earned-room-upgrade")
        tap("study.done")
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["study.start"].label.contains("Start studying"))
        capture("06-room-after-study")
        app.terminate()
        launch()
        XCTAssertTrue(app.buttons["study.start"].label.contains("Start studying"))
        capture("07-restored-room")
    }

    func testAvatarAndDecoratingPersist() {
        tap("Edit avatar")
        tap("Skin")
        tap("Deep")
        capture("wardrobe-selected-skin")
        tap("Save avatar")
        tap("Decorate")
        tap("Floor")
        tap("Walnut, owned")
        capture("decorating-selected-floor")
        tap("Back to my room")
        app.terminate()
        launch()
        tap("Edit avatar")
        tap("Skin")
        XCTAssertTrue(app.buttons["Deep, selected"].waitForExistence(timeout: 15))
        capture("wardrobe-restored")
        tap("Save avatar")
        tap("Decorate")
        tap("Floor")
        XCTAssertTrue(app.buttons["Walnut, placed"].waitForExistence(timeout: 15))
        capture("decorating-restored")
        tap("Back to my room")
    }

    private func avatarCategory(_ category: String) {
        let rail = app.scrollViews["avatar.categories"]
        XCTAssertTrue(rail.waitForExistence(timeout: 15))
        let button = app.buttons["avatar.category.\(category)"]
        // Partly clipped horizontal tabs can report hittable without accepting
        // the tap. Bring the entire tab inside the rail before selecting it.
        for _ in 0..<5 {
            if button.frame.minX >= rail.frame.minX + 2 &&
                button.frame.maxX <= rail.frame.maxX - 2 { break }
            let movingLeft = button.frame.midX > rail.frame.midX
            let start = rail.coordinate(withNormalizedOffset: CGVector(dx: movingLeft ? 0.7 : 0.3, dy: 0.5))
            let end = rail.coordinate(withNormalizedOffset: CGVector(dx: movingLeft ? 0.4 : 0.6, dy: 0.5))
            start.press(forDuration: 0.1, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.2)
        }
        XCTAssertTrue(button.isHittable)
        button.tap()
        XCTAssertTrue(button.isSelected)
    }

    func testWardrobeDiscardProtectionAndLargeEditors() {
        tap("Edit avatar")
        tap("Skin")
        tap("Deep")
        tap("avatar.close")
        XCTAssertTrue(app.buttons["avatar.keepEditing"].waitForExistence(timeout: 15))
        tap("avatar.keepEditing")
        XCTAssertTrue(app.buttons["Deep, selected"].exists)
        tap("avatar.close")
        tap("avatar.discard")
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 15))
        tap("Edit avatar")
        tap("Skin")
        XCTAssertFalse(app.buttons["Deep, selected"].exists)
        tap("Save avatar")
        app.terminate()
        app.launchArguments = ["-smoke-room", "home", "-ui-test-suite", suite,
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        tap("Edit avatar")
        capture("accessibility-wardrobe-largest")
        tap("Save avatar")
        tap("Decorate")
        capture("accessibility-decorating-largest")
        tap("room.done")
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 15))
    }

    func testIndependentGarmentsPersist() {
        tap("Edit avatar")
        avatarCategory("top")
        tap("Jacket")
        avatarCategory("bottoms")
        tap("Skirt")
        avatarCategory("shoes")
        tap("Boots")
        capture("garments-selected")
        tap("Save avatar")
        app.terminate()
        launch()
        tap("Edit avatar")
        avatarCategory("top")
        XCTAssertTrue(app.buttons["Jacket, selected"].waitForExistence(timeout: 15))
        avatarCategory("bottoms")
        XCTAssertTrue(app.buttons["Skirt, selected"].waitForExistence(timeout: 15))
        avatarCategory("shoes")
        XCTAssertTrue(app.buttons["Boots, selected"].waitForExistence(timeout: 15))
        capture("garments-restored")
        tap("Save avatar")
        startStudy()
        capture("garments-seated")
        tap("study.break")
        capture("garments-break")
    }

    func testDemoClubRestorationAndResults() {
        tap("study.club")
        XCTAssertTrue(app.staticTexts["Demo room · simulated companions"].waitForExistence(timeout: 15))
        capture("club-01-setup")
        let goal = app.descendants(matching: .any).matching(identifier: "study.goal").firstMatch
        XCTAssertTrue(goal.waitForExistence(timeout: 15))
        goal.tap()
        goal.typeText("Review together")
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }
        tap("study.begin")
        XCTAssertTrue(app.buttons["study.break"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Demo room · simulated companions"].exists)
        capture("club-02-focus")
        // Check the wider status text after the demo companion's actual timer transition.
        let deepFocus = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Maya, Deep focus")).firstMatch
        XCTAssertTrue(deepFocus.waitForExistence(timeout: 30))
        capture("club-02b-deep-focus")
        tap("study.break")
        XCTAssertEqual(app.buttons["study.break"].label, "Back to focus")
        capture("club-03-break")
        app.terminate()
        launch()
        tap("study.start")
        XCTAssertTrue(app.buttons["study.break"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Demo room · simulated companions"].exists)
        XCTAssertEqual(app.buttons["study.break"].label, "Back to focus")
        capture("club-04-restored-break")
        tap("study.break")
        app.terminate()
        launch(elapsed: 1600)
        tap("study.start")
        tap("study.review.achieved")
        XCTAssertTrue(app.staticTexts["study.coins"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["room.buySuggested"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts["study.coins"].label, "+15 coins")
        capture("club-05-results")
        tap("study.done")
        XCTAssertTrue(app.buttons["study.start"].label.contains("Start studying"))
    }

    private func enterClubGoal(_ text: String) {
        let goal = app.descendants(matching: .any).matching(identifier: "study.goal").firstMatch
        XCTAssertTrue(goal.waitForExistence(timeout: 15))
        for _ in 0..<5 where !goal.isHittable { app.swipeUp() }
        goal.tap()
        goal.typeText(text)
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }
    }

    func testEightPersonClubAreasIntentAndRestoration() {
        tap("study.club")
        for _ in 0..<4 { tap("study.clubSize.increase") }
        XCTAssertEqual(app.staticTexts["study.clubSize"].label, "8 study seats")
        XCTAssertFalse(app.buttons["study.clubSize.increase"].isEnabled)
        capture("eight-01-setup")
        enterClubGoal("Explain momentum")
        tap("study.begin")
        XCTAssertTrue(app.buttons["study.break"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["study.area.1"].isSelected)
        capture("eight-02-area-one")
        tap("study.area.2")
        XCTAssertTrue(app.buttons["study.area.2"].isSelected)
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Kai, ")).firstMatch.exists)
        capture("eight-03-area-two")
        tap("study.participants")
        let me = app.descendants(matching: .any).matching(identifier: "study.person.you").firstMatch
        XCTAssertTrue(me.waitForExistence(timeout: 15))
        XCTAssertTrue(me.label.contains("Explain momentum"))
        let maya = app.descendants(matching: .any).matching(identifier: "study.person.maya").firstMatch
        XCTAssertTrue(maya.label.localizedCaseInsensitiveContains("Biology"))
        XCTAssertTrue(maya.label.contains("Review cell division notes"))
        capture("eight-04-shared-goals")
        app.swipeUp()
        let kai = app.descendants(matching: .any).matching(identifier: "study.person.kai").firstMatch
        for _ in 0..<6 {
            if kai.exists && kai.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(kai.waitForExistence(timeout: 15))
        XCTAssertTrue(kai.label.contains("Practise new vocabulary"))
        capture("eight-05-more-goals")
        tap("study.participants.done")
        tap("study.break")
        XCTAssertTrue(app.buttons["study.area.1"].isSelected)
        for _ in 0..<2 { app.swipeDown() }
        capture("eight-06-break")
        app.terminate()
        launch()
        tap("study.start")
        XCTAssertTrue(app.buttons["study.break"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.buttons["study.break"].label, "Back to focus")
        XCTAssertTrue(app.buttons["study.area.2"].exists)
        capture("eight-07-restored")
        tap("study.area.2")
        XCTAssertTrue(app.buttons["study.area.2"].isSelected)
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Kai, Deep focus")).firstMatch.waitForExistence(timeout: 15))
        XCTAssertFalse(app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "You, on break")).firstMatch.exists)
        capture("eight-07b-other-area-during-break")
        tap("study.participants")
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "study.person.you").firstMatch.label.contains("Explain momentum"))
        tap("study.participants.done")
        tap("study.break")
        app.terminate()
        launch(elapsed: 1600)
        tap("study.start")
        tap("study.review.achieved")
        XCTAssertTrue(app.staticTexts["study.coins"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts["study.coins"].label, "+15 coins")
        capture("eight-08-results")
        tap("study.done")
    }

    func testTwoPersonClub() {
        tap("study.club")
        for _ in 0..<2 { tap("study.clubSize.decrease") }
        XCTAssertEqual(app.staticTexts["study.clubSize"].label, "2 study seats")
        XCTAssertFalse(app.buttons["study.clubSize.decrease"].isEnabled)
        capture("two-01-setup")
        enterClubGoal("Read one section")
        tap("study.begin")
        XCTAssertTrue(app.buttons["study.break"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["study.area.2"].exists)
        capture("two-02-focus")
        tap("study.break")
        capture("two-03-break")
        tap("study.leave")
        app.sheets.buttons["Leave session"].tap()
        XCTAssertTrue(app.staticTexts["study.coins"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts["study.coins"].label, "+0 coins")
        tap("study.done")
    }

    func testEarlyExitDoesNotAwardCoins() {
        startStudy()
        tap("study.leave")
        app.sheets.buttons["Leave session"].tap()
        XCTAssertTrue(app.staticTexts["study.coins"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts["study.coins"].label, "+0 coins")
        capture("early-exit-results")
        tap("study.done")
        XCTAssertTrue(app.buttons["study.start"].label.contains("Start studying"))
    }
}
