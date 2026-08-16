//
//  OnboardingFlow.swift
//  Gym TrakerUITests
//
//  Every UI test starts by getting past onboarding, so the walk-through lives
//  in one place. Three copies of it drifted apart the moment a step was added.
//

import XCTest

extension XCTestCase {

    /// Walks the five onboarding steps and leaves the app on Home with a plan.
    /// - Parameter shoot: optional hook for capturing each step.
    func completeOnboarding(
        in app: XCUIApplication,
        name: String = "Davide",
        experience: String = "Intermediate",
        split: String = "Push / Pull / Legs",
        shoot: ((String) -> Void)? = nil
    ) {
        // Step 0 — what the app is.
        let intro = app.staticTexts["Three things, done properly."]
        XCTAssertTrue(intro.waitForExistence(timeout: 20), "Onboarding did not appear")
        shoot?("00-onboarding-intro")
        app.buttons["Continue"].tap()

        // Step 1 — name and units.
        let nameField = app.textFields["Optional"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "Name step did not appear")
        nameField.tap()
        nameField.typeText(name)
        shoot?("01-onboarding-welcome")
        app.buttons["Continue"].tap()

        // Step 2 — calibration.
        XCTAssertTrue(app.staticTexts["Calibration"].waitForExistence(timeout: 5), "Calibration step is missing")
        shoot?("02-onboarding-calibration")
        app.buttons["Continue"].tap()

        // Step 3 — experience.
        let level = app.staticTexts[experience]
        XCTAssertTrue(level.waitForExistence(timeout: 5), "Experience step is missing")
        level.tap()
        shoot?("03-onboarding-experience")
        app.buttons["Continue"].tap()

        // Step 4 — a ready plan, then a split.
        let readyPlan = app.buttons.containing(.staticText, identifier: "Give me a plan").firstMatch
        XCTAssertTrue(readyPlan.waitForExistence(timeout: 5), "Plan choice did not appear")
        readyPlan.tap()

        let preset = app.buttons.containing(.staticText, identifier: split).firstMatch
        XCTAssertTrue(preset.waitForExistence(timeout: 5), "Preset list did not appear")
        preset.tap()
        shoot?("04-onboarding-plan")

        app.buttons["Start training"].tap()
        XCTAssertTrue(
            app.buttons["Start workout"].waitForExistence(timeout: 20),
            "Home did not load a session"
        )
    }

    /// Stops on the calibration step, for tests that only care about it.
    func advanceToCalibration(in app: XCUIApplication) {
        XCTAssertTrue(
            app.staticTexts["Three things, done properly."].waitForExistence(timeout: 20),
            "Onboarding did not appear"
        )
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.textFields["Optional"].waitForExistence(timeout: 5))
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Calibration"].waitForExistence(timeout: 5), "Calibration step is missing")
    }
}
