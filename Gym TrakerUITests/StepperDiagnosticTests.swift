//
//  StepperDiagnosticTests.swift
//  Gym TrakerUITests
//
//  Evidence for the reported "minus button works badly". Drives the real
//  control and reads the value back rather than reasoning about the code.
//

import XCTest

final class StepperDiagnosticTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-resetStore"]
        app.launch()
    }

    func testMinusButtonOnCalibrationSteppers() throws {
        advanceToCalibration(in: app)

        // Age stepper is the first Decrease/Increase pair on the screen.
        let decreaseButtons = app.buttons.matching(identifier: "Decrease")
        let increaseButtons = app.buttons.matching(identifier: "Increase")
        XCTAssertEqual(decreaseButtons.count, 2, "Expected an age and a bodyweight stepper")

        let ageMinus = decreaseButtons.element(boundBy: 0)
        let agePlus = increaseButtons.element(boundBy: 0)

        XCTAssertTrue(app.staticTexts["27"].exists, "Age did not start at 27")

        ageMinus.tap()
        XCTAssertTrue(app.staticTexts["26"].waitForExistence(timeout: 2),
                      "One tap on minus did not take age from 27 to 26")

        ageMinus.tap()
        ageMinus.tap()
        XCTAssertTrue(app.staticTexts["24"].waitForExistence(timeout: 2),
                      "Three taps on minus did not reach 24")

        agePlus.tap()
        XCTAssertTrue(app.staticTexts["25"].waitForExistence(timeout: 2),
                      "Plus did not take age back to 25")

        // Bodyweight stepper, second pair.
        let weightMinus = decreaseButtons.element(boundBy: 1)
        XCTAssertTrue(app.staticTexts["75"].exists, "Bodyweight did not start at 75")
        weightMinus.tap()
        XCTAssertTrue(app.staticTexts["74.5"].waitForExistence(timeout: 2),
                      "Bodyweight minus did not step down by 0.5")

        // Rapid taps: the reported symptom is that repeated presses get dropped.
        for _ in 0..<6 { weightMinus.tap() }
        XCTAssertTrue(app.staticTexts["71.5"].waitForExistence(timeout: 3),
                      "Six rapid taps did not land: value is not 71.5")
    }

    /// Prints the real hit rectangles. A synthesized tap always lands dead
    /// centre, so geometry — not logic — is what a finger actually fights.
    func testStepperHitGeometry() throws {
        advanceToCalibration(in: app)

        let screen = app.frame
        print("SCREEN \(screen)")

        for (index, label) in ["Decrease", "Increase"].enumerated() {
            let buttons = app.buttons.matching(identifier: label)
            for i in 0..<buttons.count {
                let frame = buttons.element(boundBy: i).frame
                print("GEOM \(label)[\(i)] x=\(frame.minX) w=\(frame.width) h=\(frame.height) rightGap=\(screen.maxX - frame.maxX)")
            }
            _ = index
        }
    }
}
