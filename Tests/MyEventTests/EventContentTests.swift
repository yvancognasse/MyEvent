import XCTest
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
    func testLanguageRemovedFromPreferencesFallsBackToEnglish() {
        XCTAssertNil(AppLanguage(rawValue: "bn"))
        XCTAssertNil(AppLanguage(rawValue: "id"))
        XCTAssertNil(AppLanguage(rawValue: "ur"))
        XCTAssertNotNil(AppLanguage(rawValue: "de"))
        XCTAssertNotNil(AppLanguage(rawValue: "it"))
    }
}
