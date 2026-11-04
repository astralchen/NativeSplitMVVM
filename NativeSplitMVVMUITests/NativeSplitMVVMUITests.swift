import XCTest

final class NativeSplitMVVMUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testChatInfoBackRetainsDraftAndSettings() {
        let app = XCUIApplication()
        app.launch()
        let conversation = app.cells["item.guozi"]
        XCTAssertTrue(conversation.waitForExistence(timeout: 10))
        conversation.tap()
        let draft = app.textFields["chat.draft"]
        XCTAssertTrue(draft.waitForExistence(timeout: 5))
        draft.tap()
        draft.typeText("Retained draft")
        app.buttons["chat.info"].tap()
        let muted = app.switches["info.muted"]
        XCTAssertTrue(muted.waitForExistence(timeout: 5))
        muted.tap()
        app.navigationBars.buttons["聊天"].tap()
        XCTAssertTrue(draft.waitForExistence(timeout: 5))
        XCTAssertEqual(draft.value as? String, "Retained draft")
        app.buttons["chat.info"].tap()
        XCTAssertEqual(app.switches["info.muted"].value as? String, "1")
    }

    @MainActor
    func testSendMessageAndReturnToList() {
        let app = XCUIApplication()
        app.launch()
        app.cells["item.guozi"].tap()
        let draft = app.textFields["chat.draft"]
        draft.tap()
        draft.typeText("Hello MVVM")
        app.buttons["chat.send"].tap()
        XCTAssertTrue(app.staticTexts["Hello MVVM"].waitForExistence(timeout: 5))
        if app.navigationBars.buttons["返回"].exists {
            app.navigationBars.buttons["返回"].tap()
        }
        XCTAssertTrue(app.cells["item.team"].waitForExistence(timeout: 5))
        app.cells["item.team"].tap()
        XCTAssertFalse(app.staticTexts["Hello MVVM"].exists)
    }

    @MainActor
    func testRotationRetainsInfoAndPoppedRoute() {
        let app = XCUIApplication()
        app.launch()
        app.cells["item.guozi"].tap()
        app.buttons["chat.info"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.switches["info.muted"].waitForExistence(timeout: 5))
        XCUIDevice.shared.orientation = .portrait
        XCTAssertTrue(app.switches["info.muted"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["聊天"].tap()
        XCUIDevice.shared.orientation = .landscapeLeft
        XCTAssertTrue(app.textFields["chat.draft"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.switches["info.muted"].exists)
        XCUIDevice.shared.orientation = .portrait
    }

    @MainActor
    func testExpandedTabAndDetailAreIndependent() throws {
        let app = XCUIApplication()
        app.launch()
        app.cells["item.guozi"].tap()
        guard app.cells["item.team"].isHittable else {
            throw XCTSkip("Requires an expanded split view.")
        }
        app.buttons["chat.info"].tap()
        let workspace = app.buttons["tab.1"]
        XCTAssertTrue(workspace.isHittable)
        workspace.tap()
        app.cells["item.schedule"].tap()
        app.buttons["tab.0"].tap()
        XCTAssertTrue(app.switches["info.muted"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.cells["item.team"].isHittable)
        app.cells["item.team"].tap()
        XCTAssertTrue(app.buttons["chat.info"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.switches["info.muted"].exists)
    }
}
