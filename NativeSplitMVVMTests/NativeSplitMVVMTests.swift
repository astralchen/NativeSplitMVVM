import XCTest
@testable import NativeSplitMVVM

final class NativeSplitMVVMTests: XCTestCase {
    @MainActor
    func testEachTabRetainsItsOwnRoute() {
        var state = NavigationState()
        state.select("guozi", in: .messages)
        state.setInfoVisible(true, in: .messages)
        state.selectedTab = .workspace
        state.select("schedule", in: .workspace)
        XCTAssertEqual(state.routes[.messages], DetailRoute(itemID: "guozi", showsInfo: true))
        XCTAssertEqual(state.routes[.workspace], DetailRoute(itemID: "schedule"))
        state.returnToList(in: .workspace)
        XCTAssertNotNil(state.routes[.messages])
        XCTAssertNil(state.routes[.workspace])
    }

    @MainActor
    func testSelectingNewConversationClearsOldInfoPath() {
        var state = NavigationState()
        state.select("guozi", in: .messages)
        state.setInfoVisible(true, in: .messages)
        state.select("team", in: .messages)
        XCTAssertEqual(state.routes[.messages], DetailRoute(itemID: "team"))
        state.returnToList(in: .messages)
        state.setInfoVisible(true, in: .messages)
        XCTAssertNil(state.routes[.messages])
    }

    @MainActor
    func testCompactAndExpandedScreensShareConversationState() throws {
        let app = AppViewModel()
        let item = try XCTUnwrap(app.item("guozi", in: .messages))
        let compact = app.chat(for: item)
        compact.draft = "A retained draft"
        compact.isMuted = true
        let expanded = app.chat(for: item)
        XCTAssertTrue(compact === expanded)
        XCTAssertEqual(expanded.draft, "A retained draft")
        XCTAssertTrue(expanded.isMuted)
        XCTAssertFalse(app.chat(for: try XCTUnwrap(app.item("team", in: .messages))) === expanded)
    }

    @MainActor
    func testSendRejectsWhitespaceAndClearsSuccessfulDraft() throws {
        let app = AppViewModel()
        let chat = app.chat(for: try XCTUnwrap(app.item("guozi", in: .messages)))
        let initialCount = chat.messages.count
        chat.draft = "   \n "
        XCTAssertFalse(chat.send())
        XCTAssertEqual(chat.messages.count, initialCount)
        chat.draft = " Hello "
        XCTAssertTrue(chat.send())
        XCTAssertEqual(chat.messages.last?.text, "Hello")
        XCTAssertEqual(chat.messages.count, initialCount + 1)
        XCTAssertEqual(chat.draft, "")
    }
}
