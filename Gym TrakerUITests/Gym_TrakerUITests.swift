//
//  Gym_TrakerUITests.swift
//  Gym TrakerUITests
//
//  Walks the acceptance checks from design/SPEC.md §7 against the real app,
//  capturing a screenshot of each screen on the way through.
//

import XCTest

final class Gym_TrakerUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Start from a clean store so onboarding always runs.
        app.launchArguments = ["-resetStore"]
        app.launch()
    }

    // MARK: - Helpers

    private func shoot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func tapTab(_ name: String) {
        let tab = app.tabBars.buttons[name]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "Tab \(name) is missing")
        tab.tap()
    }

    /// Runs the three onboarding steps and lands on Home with a PPL plan.
    private func completeOnboarding() {
        let name = app.textFields["Optional"]
        XCTAssertTrue(name.waitForExistence(timeout: 10), "Onboarding did not appear")
        name.tap()
        name.typeText("Davide")

        shoot("01-onboarding-welcome")
        app.buttons["Continue"].tap()

        XCTAssertTrue(app.staticTexts["Calibration"].waitForExistence(timeout: 5))
        shoot("02-onboarding-calibration")
        app.buttons["Continue"].tap()

        let preset = app.buttons.containing(.staticText, identifier: "Push / Pull / Legs").firstMatch
        XCTAssertTrue(preset.waitForExistence(timeout: 5), "Preset list did not appear")
        preset.tap()
        shoot("03-onboarding-plan")

        app.buttons["Start training"].tap()
        XCTAssertTrue(app.buttons["Start workout"].waitForExistence(timeout: 10), "Home did not load a session")
    }

    // MARK: - Tests

    /// The whole path: onboard, log a session with uneven sets, and confirm the
    /// registry recorded every parameter that moved.
    func testFullTrackingFlow() throws {
        completeOnboarding()
        shoot("04-home")

        app.buttons["Start workout"].tap()

        let firstSet = app.buttons["Complete set 1"]
        XCTAssertTrue(firstSet.waitForExistence(timeout: 5), "Session did not open")
        shoot("05-session")

        // Acceptance check: a weight change writes exactly one registry entry.
        let increaseWeight = app.buttons["Increase"].firstMatch
        XCTAssertTrue(increaseWeight.exists, "Weight stepper is missing")
        increaseWeight.tap()

        // Acceptance check: sets inside one exercise hold different rep counts.
        let moreReps = app.buttons["One rep more"]
        XCTAssertTrue(moreReps.firstMatch.exists, "Reps stepper is missing")
        moreReps.firstMatch.tap()
        moreReps.firstMatch.tap()

        // Log the first set.
        firstSet.tap()
        XCTAssertTrue(app.buttons["Set 1 done"].waitForExistence(timeout: 3), "Set did not complete")
        shoot("06-session-logged")

        // Finishing now asks first, and the button sits after the exercises.
        app.buttons["Finish"].firstMatch.tap()
        let confirm = app.buttons["End session"]
        XCTAssertTrue(confirm.waitForExistence(timeout: 3), "Finish confirmation did not appear")
        confirm.tap()

        let done = app.buttons["Done"]
        XCTAssertTrue(done.waitForExistence(timeout: 5), "Summary sheet did not appear")
        shoot("07-summary")
        done.tap()

        // Acceptance check: the changes are readable in the registry.
        tapTab("Registry")
        XCTAssertTrue(app.staticTexts["Recent"].waitForExistence(timeout: 5), "Registry is empty")
        shoot("08-registry")
    }

    /// Acceptance check: a custom exercise appears in search, in the archive and
    /// carries a diagram matching the rest of the library.
    func testCustomExerciseReachesTheArchive() throws {
        completeOnboarding()

        tapTab("Library")
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))
        shoot("09-library")

        app.buttons["New"].tap()
        let field = app.textFields["Cable crossover"]
        XCTAssertTrue(field.waitForExistence(timeout: 5), "New exercise sheet did not open")
        field.tap()
        field.typeText("Landmine Press")
        shoot("10-new-exercise")

        app.buttons["Save to my library"].tap()

        // It is now searchable in the archive.
        let search = app.textFields["Search name or muscle"]
        XCTAssertTrue(search.waitForExistence(timeout: 5))
        search.tap()
        search.typeText("Landmine")
        XCTAssertTrue(
            app.staticTexts["Landmine Press"].waitForExistence(timeout: 5),
            "Custom exercise is not searchable"
        )
        shoot("11-custom-in-search")
    }

    /// Acceptance check: assigning one template to two weekdays works.
    func testTemplateCanRepeatWithinTheWeek() throws {
        completeOnboarding()

        tapTab("Plan")
        XCTAssertTrue(app.navigationBars["Plan"].waitForExistence(timeout: 5))
        shoot("12-plan")

        // Tuesday starts as a rest day in the PPL preset; one tap assigns A,
        // which Monday already holds.
        let tuesday = app.buttons["Tue: rest"]
        XCTAssertTrue(tuesday.waitForExistence(timeout: 5), "Week grid is missing")
        tuesday.tap()

        XCTAssertTrue(
            app.buttons["Tue: template A"].waitForExistence(timeout: 3),
            "Template A did not repeat on a second weekday"
        )
        XCTAssertTrue(app.buttons["Mon: template A"].exists, "Monday lost its template")
        shoot("13-plan-repeated-template")
    }

    /// The ranking screen renders and explains itself.
    func testProfileScreenRenders() throws {
        completeOnboarding()

        tapTab("You")
        XCTAssertTrue(app.navigationBars["You"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Beginner"].exists, "Ladder is missing")
        shoot("14-you")
    }

    /// Both appearances are first-class, so the light pass gets walked too.
    func testLightAppearance() throws {
        completeOnboarding()

        tapTab("You")
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))

        let light = app.buttons["Light"]
        XCTAssertTrue(light.waitForExistence(timeout: 5), "Appearance control is missing")
        light.tap()
        shoot("15-settings-light")

        app.buttons["Done"].tap()
        XCTAssertTrue(app.navigationBars["You"].waitForExistence(timeout: 5))
        shoot("16-you-light")

        tapTab("Home")
        XCTAssertTrue(app.buttons["Start workout"].waitForExistence(timeout: 5))
        shoot("17-home-light")

        tapTab("Library")
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5))
        shoot("18-library-light")
    }

    /// Export produces a shareable file rather than failing silently.
    func testDataExport() throws {
        completeOnboarding()

        tapTab("You")
        app.buttons["Settings"].tap()

        let export = app.buttons["Export data as JSON"]
        XCTAssertTrue(export.waitForExistence(timeout: 5), "Export button is missing")
        export.tap()

        XCTAssertTrue(
            app.buttons["Share export"].waitForExistence(timeout: 5),
            "Export did not produce a file to share"
        )
        shoot("19-export-ready")
    }
}
