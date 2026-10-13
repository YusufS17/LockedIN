import XCTest

/// Changes only the existing QA simulator's Motion setting and restores its
/// initial value. This is not a full VoiceOver or physical-device acceptance test.
final class SystemAccessibilityTests: XCTestCase {
    private var app: XCUIApplication!
    private var settings: XCUIApplication!
    private var suite = ""
    private var originalReduceMotion: Bool?

    override func setUpWithError() throws {
        continueAfterFailure = false
        suite = "LockedIN.ui-tests.system-accessibility.\(UUID().uuidString)"
        app = XCUIApplication()
        settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
    }

    override func tearDownWithError() throws {
        if let originalReduceMotion {
            settings.activate()
            let toggle = settings.switches["Reduce Motion"].firstMatch
            XCTAssertTrue(toggle.waitForExistence(timeout: 15), "Restore the original simulator Motion setting")
            if (toggle.value as? String == "1") != originalReduceMotion { toggle.tap() }
            XCTAssertEqual(toggle.value as? String, originalReduceMotion ? "1" : "0")
        }
        app.terminate()
        app.launchArguments = ["-ui-test-suite", suite, "-ui-test-reset", "-ui-test-cleanup"]
        app.launch()
        XCTAssertTrue(app.staticTexts["ui-test.cleaned"].waitForExistence(timeout: 15))
        app.terminate()
        settings.terminate()
    }

    private func openSetting(_ label: String) {
        let row = settings.staticTexts[label].firstMatch
        for _ in 0..<10 {
            if row.exists && row.isHittable { row.tap(); return }
            settings.swipeUp()
        }
        XCTFail("Cannot navigate Settings to \(label)")
    }

    private func setMotion(_ reduced: Bool) {
        settings.activate()
        let toggle = settings.switches["Reduce Motion"].firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 15))
        if (toggle.value as? String == "1") != reduced { toggle.tap() }
        XCTAssertEqual(toggle.value as? String, reduced ? "1" : "0")
        app.activate()
        let mode = app.staticTexts["qa.motion.mode"]
        XCTAssertTrue(mode.waitForExistence(timeout: 15))
        let expected = reduced ? "Motion reduced" : "Motion enabled"
        let predicate = NSPredicate(format: "label == %@", expected)
        expectation(for: predicate, evaluatedWith: mode)
        waitForExpectations(timeout: 15)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = reduced ? "system-motion-reduced" : "system-motion-enabled"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    @MainActor
    func testActualSystemReduceMotionAndElementDescriptions() throws {
        settings.launch()
        openSetting("Accessibility")
        openSetting("Motion")
        let toggle = settings.switches["Reduce Motion"].firstMatch
        XCTAssertTrue(toggle.waitForExistence(timeout: 15))
        XCTAssertTrue(["0", "1"].contains(toggle.value as? String ?? ""))
        originalReduceMotion = toggle.value as? String == "1"
        // No fixture reduction flag: renderer/probe use the real system environment.
        app.launchArguments = ["-smoke-room", "world", "-ui-test-suite", suite,
                               "-ui-test-reset", "-ui-test-motion-status"]
        app.launch()
        XCTAssertTrue(app.buttons["world.back"].waitForExistence(timeout: 30))
        setMotion(false)
        setMotion(true)
        // Public XCTest audit checks descriptions of currently visible elements.
        // It does not establish spoken focus order or a complete accessibility audit.
        try app.performAccessibilityAudit(for: .sufficientElementDescription)
    }
}
