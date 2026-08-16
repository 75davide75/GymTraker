//
//  RankLadderCrashTests.swift
//  Gym TrakerUITests
//
//  Reproduction for the reported freeze: tapping the Rank tile on Home locks
//  the app up. Drives the real tap and waits for the destination to appear.
//

import XCTest

final class RankLadderCrashTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-resetStore"]
        app.launch()
    }

    private func shoot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func completeOnboarding() {
        let name = app.textFields["Optional"]
        XCTAssertTrue(name.waitForExistence(timeout: 15), "Onboarding did not appear")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["Calibration"].waitForExistence(timeout: 5))
        app.buttons["Continue"].tap()

        let preset = app.buttons.containing(.staticText, identifier: "Push / Pull / Legs").firstMatch
        XCTAssertTrue(preset.waitForExistence(timeout: 5))
        preset.tap()
        app.buttons["Start training"].tap()
        XCTAssertTrue(app.buttons["Start workout"].waitForExistence(timeout: 15), "Home did not load")
    }

    func testTappingRankTileOpensTheLadder() throws {
        completeOnboarding()

        let rankTile = app.buttons.containing(.staticText, identifier: "RANK").firstMatch
        XCTAssertTrue(rankTile.waitForExistence(timeout: 5), "Rank tile is missing")

        let started = Date.now
        rankTile.tap()

        // The freeze showed up as the destination never arriving: the title
        // rendered, the content never did, and no UI query could be answered.
        let ladder = app.navigationBars["Ranks"]
        let appeared = ladder.waitForExistence(timeout: 20)
        let elapsed = Date.now.timeIntervalSince(started)

        XCTAssertTrue(appeared, "Ranks screen never appeared — the app is wedged")
        XCTAssertLessThan(elapsed, 5.0, "Ranks took \(String(format: "%.1f", elapsed))s to open")

        // And the screen must stay responsive afterwards.
        let squatChip = app.buttons["Back squat"]
        XCTAssertTrue(squatChip.waitForExistence(timeout: 5), "Ladder content did not render")
        squatChip.tap()
        XCTAssertTrue(app.staticTexts["Beginner"].waitForExistence(timeout: 5), "Ladder stopped responding")
    }
}
