import XCTest
@testable import MyEvent

@MainActor
final class EventReviewTests: XCTestCase {
    private func receipt() -> EventReceipt {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let draft = EventDraft(title: "Original", start: start, end: start.addingTimeInterval(3600),
            location: "Paris", url: URL(string: "https://example.com/original"),
            notes: "Start: old start\n\nEnd: old end\n\nDetails:\nBudget to review", detectedDate: true)
        return EventReceipt(draft: draft, destinations: ["Account / Calendar"], language: .english)
    }
    func testOpeningAndDiscardingDraftDoesNotWrite() {
        var writes = 0
        var model: EventReviewModel? = EventReviewModel(receipt: receipt()) { _ in writes += 1 }
        XCTAssertFalse(model!.confirmed)
        XCTAssertEqual(model!.draft.notes, "Budget to review")
        model?.draft.title = "Unsaved changes"
        model = nil
        XCTAssertEqual(writes, 0)
    }
    func testConfirmationSavesAllEditedValuesExactlyOnce() {
        var saved: [EventDraft] = []
        let model = EventReviewModel(receipt: receipt()) { saved.append($0) }
        model.draft.title = "  Reviewed title  "
        model.draft.start = Date(timeIntervalSince1970: 1_900_000_000)
        model.draft.end = model.draft.start.addingTimeInterval(1800)
        model.draft.location = "Geneva"
        model.draft.notes = "Edited notes\nKeep these details."
        model.link = "https://example.com/reviewed"
        XCTAssertEqual(saved.count, 0)
        model.confirm()
        model.confirm()
        XCTAssertTrue(model.confirmed)
        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved[0].title, "Reviewed title")
        XCTAssertEqual(saved[0].start, model.draft.start)
        XCTAssertEqual(saved[0].end, model.draft.end)
        XCTAssertEqual(saved[0].location, "Geneva")
        XCTAssertEqual(saved[0].notes, "Edited notes\nKeep these details.")
        XCTAssertEqual(saved[0].url?.absoluteString, "https://example.com/reviewed")
        XCTAssertFalse(saved[0].notes.contains("old start"))
    }
    func testInvalidTitleDatesAndLinkNeverWrite() {
        var writes = 0
        let model = EventReviewModel(receipt: receipt()) { _ in writes += 1 }
        model.draft.title = " \n "
        model.confirm()
        XCTAssertNotNil(model.validationMessage)
        model.draft.title = "Valid title"
        model.draft.end = model.draft.start
        model.confirm()
        model.draft.end = model.draft.start.addingTimeInterval(-1)
        model.confirm()
        model.draft.end = model.draft.start.addingTimeInterval(3600)
        for badURL in ["not a link", "javascript:alert(1)", "https://"] {
            model.link = badURL
            model.confirm()
            XCTAssertNotNil(model.validationMessage)
        }
        XCTAssertEqual(writes, 0)
        XCTAssertFalse(model.confirmed)
    }
    func testFailedConfirmationRetainsEditsAndCanRetry() {
        var writes = 0
        let model = EventReviewModel(receipt: receipt()) { _ in
            writes += 1
            if writes == 1 { throw NSError(domain: "Fixture", code: 1, userInfo: [NSLocalizedDescriptionKey: "Calendar unavailable"]) }
        }
        model.draft.notes = "Preserve these edits"
        model.confirm()
        XCTAssertFalse(model.confirmed)
        XCTAssertEqual(model.error, "Calendar unavailable")
        XCTAssertEqual(model.draft.notes, "Preserve these edits")
        model.confirm()
        XCTAssertTrue(model.confirmed)
        XCTAssertTrue(model.error.isEmpty)
        XCTAssertEqual(writes, 2)
    }
    func testLinkCanBeRemoved() {
        var saved: EventDraft?
        let model = EventReviewModel(receipt: receipt()) { saved = $0 }
        model.link = "   "
        model.confirm()
        XCTAssertTrue(model.confirmed)
        XCTAssertNil(saved?.url)
    }
    func testGeneratedPreambleRemovedInAllLanguagesButSourceDatesKept() {
        for language in AppLanguage.allCases {
            var original = receipt()
            let label: (String) -> String = { Translations.text($0, language: language) }
            var draft = original.draft
            draft.notes = "\(label("Start")): generated\n\n\(label("End")): generated\n\n\(label("Details")):\nFlight on 12 December 2026"
            original = EventReceipt(draft: draft, destinations: original.destinations, language: language)
            let model = EventReviewModel(receipt: original) { _ in }
            XCTAssertEqual(model.draft.notes, "Flight on 12 December 2026")
        }
    }
}
