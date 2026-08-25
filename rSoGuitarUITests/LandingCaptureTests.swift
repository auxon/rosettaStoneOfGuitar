//
//  LandingCaptureTests.swift
//  rSoGuitarUITests
//
//  Captures simulator screenshots into landing/media for the marketing page.
//  Video is recorded by the host via `simctl io recordVideo` around testPlayWalkthrough.
//

import XCTest

final class LandingCaptureTests: XCTestCase {

    private var mediaURL: URL {
        URL(fileURLWithPath: "/Users/rah/rosettaStoneOfGuitar/landing/media")
    }

    override func setUpWithError() throws {
        continueAfterFailure = true
        try FileManager.default.createDirectory(at: mediaURL, withIntermediateDirectories: true)
    }

    @MainActor
    func testCaptureLandingScreens() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
        sleep(2)

        save(app, name: "01-lessons")

        if app.staticTexts["Spiral Mapping"].waitForExistence(timeout: 8) {
            app.staticTexts["Spiral Mapping"].tap()
            sleep(2)
            app.swipeUp()
            sleep(1)
            save(app, name: "02-spiral-lesson")
            if app.navigationBars.buttons.element(boundBy: 0).exists {
                app.navigationBars.buttons.element(boundBy: 0).tap()
                sleep(1)
            }
        }

        tapTab(app, "Fretboard")
        sleep(2)
        save(app, name: "03-fretboard")

        tapTab(app, "Concepts")
        sleep(1)
        save(app, name: "04-concepts")

        tapTab(app, "Rhythm")
        sleep(1)
        save(app, name: "05-rhythm")
    }

    @MainActor
    func testPlayWalkthrough() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 20))
        sleep(1)
        tapTab(app, "Fretboard")
        sleep(2)
        let play = app.buttons["Play pattern"]
        if play.waitForExistence(timeout: 6) {
            play.tap()
        }
        sleep(12)
        if app.buttons["Pause pattern"].exists {
            app.buttons["Pause pattern"].tap()
        }
        sleep(1)
    }

    @MainActor
    private func tapTab(_ app: XCUIApplication, _ name: String) {
        let tab = app.tabBars.buttons[name]
        if tab.waitForExistence(timeout: 5) {
            tab.tap()
            return
        }
        app.tabBars.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", name)).firstMatch.tap()
    }

    @MainActor
    private func save(_ app: XCUIApplication, name: String) {
        let shot = app.screenshot()
        let url = mediaURL.appendingPathComponent("\(name).png")
        do {
            try shot.pngRepresentation.write(to: url)
            print("LANDING_CAPTURE wrote \(url.path)")
        } catch {
            XCTFail("Failed to write \(name): \(error)")
        }
    }
}
