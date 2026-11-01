import XCTest
import Translation
import AppKit
@testable import MyEvent

final class EventContentTests: XCTestCase {
    func testTranslatedContentPreservesOriginalDateAndDetails() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 31, hour: 14))!
        let draft = EventContentBuilder.build(source: "Réunion demain de 14h30 à 15h45\nLieu: Paris\nBudget à valider", translated: "Betreff: Projektbesprechung\nOrt: Paris\nBudget prüfen\nanna@example.com\nhttps://example.com/meeting", language: .german, now: now, calendar: calendar)
        XCTAssertEqual(draft.title, "Projektbesprechung")
        XCTAssertEqual(calendar.component(.day, from: draft.start), 1)
        XCTAssertEqual(calendar.component(.hour, from: draft.start), 14)
        XCTAssertEqual(draft.end.timeIntervalSince(draft.start), 4500)
        XCTAssertEqual(draft.location, "Paris")
        XCTAssertEqual(draft.url?.absoluteString, "https://example.com/meeting")
        XCTAssertTrue(draft.notes.contains("Teilnehmer:\nanna@example.com"))
        XCTAssertTrue(draft.notes.contains("Budget prüfen"))
        XCTAssertFalse(draft.notes.contains("Budget à valider"))
    }
    func testItalianDetailsAndNoInventedLocationOrAttendees() {
        let draft = EventContentBuilder.build(source: "Discussione budget", translated: "Discussione budget\nVerificare i costi e preparare il documento", language: .italian)
        XCTAssertTrue(draft.notes.contains("Dettagli:\nDiscussione budget"))
        XCTAssertTrue(draft.notes.contains("Inizio:"))
        XCTAssertTrue(draft.location.isEmpty)
        XCTAssertNil(draft.url)
        XCTAssertFalse(draft.notes.contains("Partecipanti:"))
    }
    func testAlreadyEnglishTextNeedsNoTranslationDownload() async throws {
        let text = "Project planning meeting with the sales team to review the budget and agree on the next steps."
        let translated = try await EventTextTranslator.translate(text, to: .english)
        XCTAssertEqual(translated, text)
    }
    func testInvalidTranslationNeverProducesFallbackContent() {
        let english = Locale.Language(identifier: "en")
        XCTAssertThrowsError(try EventTextTranslator.validatedText("  \n", language: english, target: english))
        XCTAssertThrowsError(try EventTextTranslator.validatedText("Bonjour", language: Locale.Language(identifier: "fr"), target: english))
        XCTAssertEqual(try EventTextTranslator.validatedText("Meeting", language: Locale.Language(identifier: "en-US"), target: english), "Meeting")
    }

    func testTranslationErrorsRetainActionableCauseAndCancellation() throws {
        guard #available(macOS 26.0, *) else { throw XCTSkip("Requires Translation errors on macOS 26") }
        let missing = EventTextTranslator.mappedError(TranslationError.notInstalled)
        guard case EventTextTranslator.Failure.notInstalled = missing else { return XCTFail("Missing models should explain installation") }
        let unsupported = EventTextTranslator.mappedError(TranslationError.unsupportedLanguagePairing)
        guard case EventTextTranslator.Failure.unsupported = unsupported else { return XCTFail("Unsupported pair should be identified") }
        XCTAssertTrue(EventTextTranslator.mappedError(TranslationError.alreadyCancelled) is CancellationError)
        XCTAssertTrue(EventTextTranslator.mappedError(CancellationError()) is CancellationError)
        let serviceError = NSError(domain: "TranslationFixture", code: 16, userInfo: [NSLocalizedDescriptionKey: "Permission required"])
        XCTAssertEqual(EventTextTranslator.mappedError(serviceError).localizedDescription, "Permission required")
    }

    @MainActor
    func testLiveViewBackedTranslationWithFixtureOnly() async throws {
        guard ProcessInfo.processInfo.environment["MYEVENT_LIVE_TRANSLATION_TEST"] == "1" else {
            throw XCTSkip("Opt-in local translation test; never accesses calendars")
        }
        guard #available(macOS 26.0, *) else { throw XCTSkip("Requires macOS 26") }
        _ = NSApplication.shared
        let translated = try await EventTextTranslator.translate(
            "Réunion de projet demain à 14h pour discuter du budget.", to: .english)
        XCTAssertFalse(translated.isEmpty)
        XCTAssertTrue(translated.lowercased().contains("budget"))
        XCTAssertFalse(translated.contains("Réunion"))
    }

    func testLanguageRemovedFromPreferencesFallsBackToEnglish() {
        XCTAssertNil(AppLanguage(rawValue: "bn"))
        XCTAssertNil(AppLanguage(rawValue: "id"))
        XCTAssertNil(AppLanguage(rawValue: "ur"))
        XCTAssertNotNil(AppLanguage(rawValue: "de"))
        XCTAssertNotNil(AppLanguage(rawValue: "it"))
    }
}
