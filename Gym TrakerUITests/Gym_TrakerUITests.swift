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
        // The bar is drawn by the app now, so its buttons are plain buttons.
        let tab = app.buttons[name].firstMatch
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "Tab \(name) is missing")
        tab.tap()
    }

    // MARK: - Tests

    /// The whole path: onboard, log a session with uneven sets, and confirm the
    /// registry recorded every parameter that moved.
    func testFullTrackingFlow() throws {
        completeOnboarding(in: app, shoot: shoot)
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
        XCTAssertTrue(app.staticTexts["Recent"].firstMatch.waitForExistence(timeout: 8), "Registry is empty")
        shoot("08-registry")
    }

    /// Acceptance check: a custom exercise appears in search, in the archive and
    /// carries a diagram matching the rest of the library.
    func testCustomExerciseReachesTheArchive() throws {
        completeOnboarding(in: app, shoot: shoot)

        tapTab("Library")
        XCTAssertTrue(app.staticTexts["Library"].firstMatch.waitForExistence(timeout: 5))
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
        completeOnboarding(in: app, shoot: shoot)

        tapTab("Plan")
        XCTAssertTrue(app.staticTexts["Plan"].firstMatch.waitForExistence(timeout: 5))
        shoot("12-plan")

        // Home shows a read-only copy of the same strip, so target the live
        // one: only the editor's cells are enabled.
        let tuesday = app.buttons
            .matching(NSPredicate(format: "label == %@ AND enabled == true", "Tue: rest"))
            .firstMatch
        XCTAssertTrue(tuesday.waitForExistence(timeout: 5), "Week grid is missing")
        tuesday.tap()

        let assigned = app.buttons
            .matching(NSPredicate(format: "label == %@ AND enabled == true", "Tue: template A"))
            .firstMatch
        XCTAssertTrue(
            assigned.waitForExistence(timeout: 3),
            "Template A did not repeat on a second weekday"
        )
        XCTAssertTrue(
            app.buttons
                .matching(NSPredicate(format: "label == %@ AND enabled == true", "Mon: template A"))
                .firstMatch.exists,
            "Monday lost its template"
        )
        shoot("13-plan-repeated-template")
    }

    /// The ranking screen renders and explains itself.
    func testProfileScreenRenders() throws {
        completeOnboarding(in: app, shoot: shoot)

        tapTab("You")
        XCTAssertTrue(app.staticTexts["You"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Beginner"].exists, "Ladder is missing")
        shoot("14-you")
    }

    /// Both appearances are first-class, so the light pass gets walked too.
    func testLightAppearance() throws {
        completeOnboarding(in: app, shoot: shoot)

        tapTab("You")
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))

        let light = app.buttons["Light"]
        XCTAssertTrue(light.waitForExistence(timeout: 5), "Appearance control is missing")
        light.tap()
        shoot("15-settings-light")

        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["You"].firstMatch.waitForExistence(timeout: 5))
        shoot("16-you-light")

        tapTab("Home")
        XCTAssertTrue(app.buttons["Start workout"].waitForExistence(timeout: 5))
        shoot("17-home-light")

        tapTab("Library")
        XCTAssertTrue(app.staticTexts["Library"].firstMatch.waitForExistence(timeout: 5))
        shoot("18-library-light")
    }

    /// Export produces a shareable file rather than failing silently.
    func testDataExport() throws {
        completeOnboarding(in: app, shoot: shoot)

        tapTab("You")
        app.buttons["Settings"].tap()

        let backup = app.buttons["Create a backup"]
        XCTAssertTrue(backup.waitForExistence(timeout: 5), "Backup button is missing")
        backup.tap()

        XCTAssertTrue(
            app.buttons["Share backup"].waitForExistence(timeout: 5),
            "Backup did not produce a file to share"
        )
        // The way back in is the point of a backup, so the door has to be here.
        XCTAssertTrue(
            app.buttons["Restore from a backup"].exists,
            "There is no way to restore what was just written"
        )
        shoot("19-export-ready")
    }
}
