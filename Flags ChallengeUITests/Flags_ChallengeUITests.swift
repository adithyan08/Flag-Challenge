//
//  Flags_ChallengeUITests.swift
//  Flags ChallengeUITests
//
//  Created by adithyan na on 5/8/25.
//

import XCTest

final class Flags_ChallengeUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    func testScheduleScreenBasicFlow() throws {
       
        let title = app.staticTexts["FLAGS CHALLENGE"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))

       
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.exists)
        XCTAssertTrue(saveButton.isEnabled)

       
        let textFields = app.textFields.allElementsBoundByIndex
        XCTAssertTrue(textFields.count >= 3)

        
        let secondsField = textFields[2]
        secondsField.tap()
        
        
        if let existing = secondsField.value as? String {
            for _ in existing {
                secondsField.typeText(XCUIKeyboardKey.delete.rawValue)
            }
        }
        
        secondsField.typeText("3")

       
        saveButton.tap()

        
        let countdownPredicate = NSPredicate(format: "label CONTAINS '00:0'")
        let countdownLabel = app.staticTexts.element(matching: countdownPredicate)
        XCTAssertTrue(countdownLabel.waitForExistence(timeout: 2))
    }
}
