import XCTest
import Translation
import AppKit
@testable import MyEvent

final class EventContentTests: XCTestCase {
    func testTranslatedContentPreservesOriginalDateAndDetails() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Paris")!
        let now = calendar.date(from: DateComponents(year: 2026, month: 10, day: 31, hour: 14))!
        let draft = EventContentBuilder.build(source: "Réunion demain de 14h30 à 15h45\nLieu: Paris\nBudget à valider\nanna@example.com\nhttps://example.com/meeting", translated: "Betreff: Projektbesprechung\nOrt: Paris\nBudget prüfen\nanna@example.com\nhttps://example.com/meeting", language: .german, now: now, calendar: calendar)
        XCTAssertEqual(draft.title, "Projektbesprechung")
        XCTAssertEqual(calendar.component(.day, from: draft.start), 1)
        XCTAssertEqual(calendar.component(.hour, from: draft.start), 14)
        XCTAssertEqual(draft.end.timeIntervalSince(draft.start), 4500)
        XCTAssertEqual(draft.location, "Paris")
        XCTAssertEqual(draft.url?.absoluteString, "https://example.com/meeting")
        XCTAssertEqual(draft.participants, ["anna@example.com"])
        XCTAssertFalse(draft.notes.contains("Teilnehmer:\nanna@example.com"))
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
    func testNewLanguageDraftsUseTranslatedTitlesLocationsAndDetails() {
        let source = "Réunion demain de 14h30 à 15h45\nLieu: Paris\nBudget à valider"
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let original = EventParser.parse(source, now: now)
        for (language, translated, title, location, detailsLabel, detail) in [
            (AppLanguage.russian, "Тема: Обсуждение бюджета\nМесто: Париж\nПроверить бюджет", "Обсуждение бюджета", "Париж", "Подробности", "Проверить бюджет"),
            (AppLanguage.dutch, "Onderwerp: Budgetoverleg\nLocatie: Parijs\nBudget controleren", "Budgetoverleg", "Parijs", "Details", "Budget controleren"),
        ] {
            let draft = EventContentBuilder.build(source: source, translated: translated, language: language, now: now)
            XCTAssertEqual(draft.title, title)
            XCTAssertEqual(draft.location, location)
            XCTAssertEqual(draft.start, original.start)
            XCTAssertEqual(draft.end, original.end)
            XCTAssertTrue(draft.notes.contains(detailsLabel + ":\n"))
            XCTAssertTrue(draft.notes.contains(detail))
            XCTAssertFalse(draft.notes.contains("Budget à valider"))
        }
    }

    func testTextAlreadyInNewLanguagesNeedsNoTranslationModels() async throws {
        for (language, text) in [
            (AppLanguage.russian, "Встреча команды для обсуждения бюджета проекта и подготовки плана работы на следующую неделю."),
            (AppLanguage.dutch, "Vergadering met het verkoopteam om de begroting te bespreken en de volgende stappen voor het project af te spreken."),
        ] {
            let translated = try await EventTextTranslator.translate(text, to: language)
            XCTAssertEqual(translated, text)
        }
    }

    func testAlreadyEnglishTextNeedsNoTranslationDownload() async throws {
        let text = "Project planning meeting with the sales team to review the budget and agree on the next steps."
        let translated = try await EventTextTranslator.translate(text, to: .english)
        XCTAssertEqual(translated, text)
    }
    func testSuccessfulDirectTranslationDoesNotOpenIntermediateWindow() async throws {
        let result = try await EventTextTranslator.translateWithFallback(direct: { "Meeting" }, interactive: {
            XCTFail("A successful background translation must not open a window")
            return "Unexpected"
        })
        XCTAssertEqual(result, "Meeting")
    }

    func testConsentFailureUsesInteractiveTranslation() async throws {
        let result = try await EventTextTranslator.translateWithFallback(direct: {
            throw NSError(domain: "TranslationFixture", code: 16)
        }, interactive: { "Translated after consent" })
        XCTAssertEqual(result, "Translated after consent")
    }

    func testCancelledDirectTranslationNeverOpensWindow() async {
        do {
            _ = try await EventTextTranslator.translateWithFallback(direct: {
                throw CancellationError()
            }, interactive: {
                XCTFail("Cancellation must not open a window")
                return "Unexpected"
            })
            XCTFail("Expected cancellation")
        } catch { XCTAssertTrue(error is CancellationError) }
    }

    func testInteractiveFailureDoesNotSaveUntranslatedFallback() async {
        do {
            _ = try await EventTextTranslator.translateWithFallback(direct: {
                throw EventTextTranslator.Failure.notInstalled
            }, interactive: { throw EventTextTranslator.Failure.failed })
            XCTFail("Translation failure must propagate")
        } catch {
            guard case EventTextTranslator.Failure.failed = error else { return XCTFail("Unexpected error") }
        }
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
    func testLiveTranslationWithFixtureOnly() async throws {
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

    func testReferenceProtectionPreservesRepeatedIdentifiersAndWhitespace() async throws {
        var inputs: [String] = []
        let result = try await EventTextTranslator.translateAroundReferences(
            "Join https://example.com/meeting\n\nEmail anna@example.com\nhttps://example.com/meeting\n"
        ) { prose in
            inputs.append(prose)
            return prose == "Join" ? "Rejoindre" : "Écrire à"
        }
        XCTAssertEqual(inputs, ["Join", "Email"])
        XCTAssertEqual(result, "Rejoindre https://example.com/meeting\n\nÉcrire à anna@example.com\nhttps://example.com/meeting\n")
    }

    func testLanguageRemovedFromPreferencesFallsBackToEnglish() {
        XCTAssertNil(AppLanguage(rawValue: "ro"))
        XCTAssertNil(AppLanguage(rawValue: "bn"))
        XCTAssertNil(AppLanguage(rawValue: "id"))
        XCTAssertNil(AppLanguage(rawValue: "ur"))
        XCTAssertNotNil(AppLanguage(rawValue: "de"))
        XCTAssertNotNil(AppLanguage(rawValue: "it"))
    }
}
