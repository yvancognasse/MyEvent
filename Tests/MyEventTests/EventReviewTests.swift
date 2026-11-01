import XCTest
import AppKit
@testable import MyEvent

@MainActor
final class EventReviewTests: XCTestCase {
    private func receipt() -> EventReceipt {
        let start = Date(timeIntervalSince1970: 1_800_000_000)
        let draft = EventDraft(title: "Original", start: start, end: start.addingTimeInterval(3600),
            location: "Paris", url: URL(string: "https://example.com/original"),
            notes: "Start: old start\n\nEnd: old end\n\nDetails:\nBudget to review", detectedDate: true)
        return EventReceipt(draft: draft, destinations: ["Account / Calendar"], language: .english, contentLanguage: .english)
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
    func testInterfaceLanguageIsIndependentOfOriginalEventText() {
        let original = receipt()
        let differentUI = EventReceipt(draft: original.draft, destinations: original.destinations,
            language: .french, contentLanguage: .english)
        let model = EventReviewModel(receipt: differentUI) { _ in XCTFail("Opening is read-only") }
        XCTAssertEqual(model.language, .french)
        XCTAssertEqual(model.eventLanguage, .english)
        XCTAssertEqual(model.draft.title, "Original")
        XCTAssertEqual(model.draft.notes, "Budget to review")
    }

    func testTranslationUpdatesAllEditedTextAtomicallyAndPreservesOtherFields() async {
        var calls: [String] = []
        var writes = 0
        let model = EventReviewModel(receipt: receipt(), translateText: { text, target, source in
            XCTAssertEqual(target, .german)
            XCTAssertEqual(source?.languageCode, Locale.LanguageCode("en"))
            calls.append(text)
            return "DE: " + text
        }) { _ in writes += 1 }
        model.draft.title = "Edited project meeting"
        model.draft.location = "Edited conference room"
        model.draft.notes = "Edited details https://example.com/meeting anna@example.com"
        model.link = "https://example.com/edited"
        let before = model.draft
        await model.translateEvent(to: .german)
        XCTAssertEqual(calls, [before.title, before.location, before.notes])
        XCTAssertEqual(model.draft.title, "DE: " + before.title)
        XCTAssertEqual(model.draft.location, "DE: " + before.location)
        XCTAssertEqual(model.draft.notes, "DE: " + before.notes)
        XCTAssertEqual(model.draft.start, before.start)
        XCTAssertEqual(model.draft.end, before.end)
        XCTAssertEqual(model.link, "https://example.com/edited")
        XCTAssertEqual(model.destinations, ["Account / Calendar"])
        XCTAssertEqual(model.eventLanguage, .german)
        XCTAssertEqual(model.language, .english)
        XCTAssertEqual(writes, 0)
    }

    func testTranslationFailureRetainsEditsAndPreviousLanguage() async {
        var calls = 0
        let model = EventReviewModel(receipt: receipt(), translateText: { text, _, _ in
            calls += 1
            if calls == 3 { throw EventTextTranslator.Failure.unsupported }
            return "Translated " + text
        }) { _ in XCTFail("Translation must not save") }
        model.draft.title = "Edited title"
        model.draft.notes = "Edited notes"
        let before = model.draft
        await model.translateEvent(to: .french)
        XCTAssertEqual(model.draft.title, before.title)
        XCTAssertEqual(model.draft.location, before.location)
        XCTAssertEqual(model.draft.notes, before.notes)
        XCTAssertEqual(model.eventLanguage, .english)
        XCTAssertFalse(model.error.isEmpty)
        XCTAssertFalse(model.translating)
    }

    func testMissingLinkInTranslationRejectsEntireResult() async {
        let model = EventReviewModel(receipt: receipt(), translateText: { _, _, _ in "Text without references" }) { _ in }
        model.draft.notes = "Join https://example.com/meeting or email anna@example.com"
        let before = model.draft
        await model.translateEvent(to: .german)
        XCTAssertEqual(model.draft.title, before.title)
        XCTAssertEqual(model.draft.notes, before.notes)
        XCTAssertEqual(model.eventLanguage, .english)
        XCTAssertFalse(model.error.isEmpty)
    }

    func testPendingTranslationBlocksSaveAndCancellationDiscardsLateResults() async {
        var release: CheckedContinuation<String, Error>?
        var writes = 0
        let model = EventReviewModel(receipt: receipt(), translateText: { _, _, _ in
            try await withCheckedThrowingContinuation { release = $0 }
        }) { _ in writes += 1 }
        let before = model.draft
        let task = Task { await model.translateEvent(to: .french) }
        while release == nil { await Task.yield() }
        XCTAssertTrue(model.translating)
        model.confirm()
        XCTAssertEqual(writes, 0)
        model.cancelTranslation()
        release?.resume(returning: "Late translation")
        await task.value
        XCTAssertEqual(model.draft.title, before.title)
        XCTAssertEqual(model.eventLanguage, .english)
        XCTAssertFalse(model.translating)
        XCTAssertTrue(model.error.isEmpty)
    }

    func testLiveMultiFieldTranslationWithFixtureOnly() async throws {
        guard ProcessInfo.processInfo.environment["MYEVENT_LIVE_REVIEW_TEST"] == "1" else {
            throw XCTSkip("Opt-in Apple translation integration test; no calendar access")
        }
        guard #available(macOS 26.0, *) else { throw XCTSkip("Requires macOS 26") }
        _ = NSApplication.shared
        let model = EventReviewModel(receipt: receipt()) { _ in XCTFail("No calendar writes in fixtures") }
        model.draft.title = "Budget review for the migration project"
        model.draft.location = "Meeting room"
        model.draft.notes = "Location: Meeting room\n\nParticipants:\nanna@example.com\n\nLinks:\nhttps://example.com/meeting\n\nHello Anna,\nSubject: Budget review for the migration project\nDate: 12 November 2026 14:30\nLocation: Meeting room\nDiscuss project costs and next steps.\nhttps://example.com/meeting\nanna@example.com"
        let before = model.draft
        await model.translateEvent(to: .french)
        XCTAssertTrue(model.error.isEmpty, model.error)
        XCTAssertEqual(model.eventLanguage, .french)
        XCTAssertNotEqual(model.draft.title, before.title)
        XCTAssertNotEqual(model.draft.location, before.location)
        XCTAssertNotEqual(model.draft.notes, before.notes)
        XCTAssertEqual(model.draft.start, before.start)
        XCTAssertEqual(model.draft.end, before.end)
        XCTAssertTrue(model.draft.notes.contains("https://example.com/meeting"))
        XCTAssertTrue(model.draft.notes.contains("anna@example.com"))
    }

    func testConfirmedDraftCannotBeTranslated() async {
        let model = EventReviewModel(receipt: receipt(), translateText: { _, _, _ in
            XCTFail("Confirmed events cannot be changed")
            return "Unexpected"
        }) { _ in }
        model.confirm()
        await model.translateEvent(to: .french)
        XCTAssertEqual(model.eventLanguage, .english)
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
