import XCTest

/// Focused render checks using disposable, namespaced saves.
/// The results case seeds a recorded completed session and explicitly requests the
/// Debug Reduce Motion fixture. It does not verify a live timer or an OS setting.
final class ResultsReadabilityTests: XCTestCase {
    private var app: XCUIApplication!
    private var suite = ""

    override func setUpWithError() throws {
        continueAfterFailure = false
        suite = "LockedIN.ui-tests.results-readability.\(UUID().uuidString)"
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app.terminate()
        app.launchArguments = ["-ui-test-suite", suite, "-ui-test-reset", "-ui-test-cleanup"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ui-test.cleaned"].waitForExistence(timeout: 15))
        app.terminate()
    }

    private func launch(reset: Bool, recordedResults: Bool = false, reducedMotion: Bool = false,
                        destinations: Bool = false, largestText: Bool = true) {
        app.launchArguments = ["-smoke-room", "home", "-ui-test-suite", suite]
        if largestText {
            app.launchArguments += ["-UIPreferredContentSizeCategoryName",
                                    "UICTContentSizeCategoryAccessibilityXXXL"]
        }
        if reset { app.launchArguments += ["-ui-test-reset"] }
        if recordedResults { app.launchArguments += ["-ui-test-pending-results"] }
        if destinations { app.launchArguments += ["-ui-test-world-destinations"] }
        if recordedResults || reducedMotion { app.launchArguments += ["-ui-test-reduce-motion"] }
        app.launch()
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 30))
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func centreTap(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 15))
        XCTAssertTrue(element.isEnabled)
        XCTAssertTrue(element.isHittable)
        // Reproduces a tap in the gap between wrapped text lines on a large button.
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func reveal(_ element: XCUIElement) {
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<16 {
            // Results actions are inside the scroll view, including View world
            // below Return home. Neither action is a pinned bottom dock.
            if element.exists && element.isHittable &&
                element.frame.minY >= scroll.frame.minY &&
                element.frame.maxY <= scroll.frame.maxY { return }
            let aboveViewport = element.exists && element.frame.midY < scroll.frame.minY
            let start = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: aboveViewport ? 0.35 : 0.7))
            let end = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: aboveViewport ? 0.7 : 0.35))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        let hierarchy = XCTAttachment(string: app.debugDescription)
        hierarchy.name = "results-reveal-failure-hierarchy"
        hierarchy.lifetime = .keepAlways
        add(hierarchy)
        XCTFail("Could not reveal \(element.identifier)")
    }

    func testLargestTextHomeButtonCentreOpensSetup() {
        // Ordinary animations: this case intentionally has no Reduce Motion override.
        launch(reset: true)
        capture("largest-text-home-before-centre-tap")
        centreTap(app.buttons["study.start"])
        let back = app.buttons["studio.back"]
        XCTAssertTrue(back.waitForExistence(timeout: 15))
        capture("largest-text-setup-after-centre-tap")
        centreTap(back)
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 15))
    }

    func testResultsKeepSessionEarningsWhenStudyDestinationChanges() {
        launch(reset: true, recordedResults: true, destinations: true, largestText: false)
        centreTap(app.buttons["study.start"])
        let earnings = app.staticTexts["study.focusXP"]
        XCTAssertTrue(earnings.waitForExistence(timeout: 15))
        reveal(earnings)
        XCTAssertEqual(earnings.label, "+120 Focus XP earned this session")
        XCTAssertEqual(app.staticTexts["study.world.destination"].label, "Next study destination: Library Hub")
        XCTAssertEqual(app.staticTexts["study.world.progress"].label, "Level 1 · 50% to next")
        capture("results-original-destination-and-session-xp")

        let viewWorld = app.buttons["View world"]
        reveal(viewWorld)
        centreTap(viewWorld)
        XCTAssertTrue(app.buttons["world.back"].waitForExistence(timeout: 15))
        let cafe = app.buttons["world.building.languageCafe"]
        reveal(cafe)
        XCTAssertEqual(cafe.value as? String, "Level 1, 245 of 350 XP")
        centreTap(cafe)
        XCTAssertTrue(cafe.isSelected)
        centreTap(app.buttons["world.back"])
        reveal(earnings)
        XCTAssertEqual(earnings.label, "+120 Focus XP earned this session")
        XCTAssertEqual(app.staticTexts["study.world.destination"].label, "Next study destination: Language Café")
        XCTAssertEqual(app.staticTexts["study.world.progress"].label, "Level 1 · 70% to next")
        capture("results-current-destination-changed-session-xp-preserved")

        app.terminate()
        // Keep pending results and the changed destination; do not reset or reseed.
        launch(reset: false, reducedMotion: true, largestText: false)
        XCTAssertTrue(app.buttons["15 coins. View progress"].exists)
        centreTap(app.buttons["study.start"])
        XCTAssertTrue(earnings.waitForExistence(timeout: 15))
        reveal(earnings)
        XCTAssertEqual(earnings.label, "+120 Focus XP earned this session")
        XCTAssertEqual(app.staticTexts["study.world.destination"].label, "Next study destination: Language Café")
        // Replaying the receipt must not add another 120 XP to the new destination.
        XCTAssertEqual(app.staticTexts["study.world.progress"].label, "Level 1 · 70% to next")
        XCTAssertEqual(app.staticTexts["study.coins"].label, "+15 coins")
        capture("results-destination-and-earnings-after-relaunch")
    }

    func testLargestTextRecordedResultsUpgradePersists() {
        launch(reset: true, recordedResults: true)
        XCTAssertTrue(app.buttons["study.start"].label.contains("View your results"))
        centreTap(app.buttons["study.start"])
        let coins = app.staticTexts["study.coins"]
        XCTAssertTrue(coins.waitForExistence(timeout: 15))
        let earned = expectation(for: NSPredicate(format: "label == %@", "+15 coins"), evaluatedWith: coins)
        wait(for: [earned], timeout: 15)
        capture("largest-text-seeded-results-reduced-motion")

        let sessionXP = app.staticTexts["study.focusXP"]
        reveal(sessionXP)
        XCTAssertEqual(sessionXP.label, "+120 Focus XP earned this session")
        capture("largest-text-session-xp-separate-from-destination")
        let worldProgress = app.staticTexts["study.world.progress"]
        reveal(worldProgress)
        XCTAssertEqual(app.staticTexts["study.world.destination"].label, "Next study destination: Library Hub")
        XCTAssertEqual(worldProgress.label, "Level 1 · 34% to next")
        capture("largest-text-current-world-destination-and-progress")

        let buy = app.buttons["room.buySuggested"]
        reveal(buy)
        centreTap(buy)
        let confirmation = app.staticTexts["room.purchaseConfirmation"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 15))
        XCTAssertEqual(confirmation.label, "Teal is in your room.")
        reveal(confirmation)
        capture("largest-text-earned-rug-confirmation-reduced-motion")
        let done = app.buttons["study.done"]
        reveal(done)
        centreTap(done)
        XCTAssertTrue(app.buttons["study.start"].waitForExistence(timeout: 15))

        app.terminate()
        // Reload without resetting or reseeding; retain the rendering fixture.
        launch(reset: false, reducedMotion: true)
        XCTAssertTrue(app.buttons["study.start"].label.contains("Start studying"))
        XCTAssertTrue(app.buttons["5 coins. View progress"].exists)
        capture("largest-text-restored-home-five-coins")
    }
}
