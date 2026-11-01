import XCTest
@testable import MyEvent

final class EventTitleTests: XCTestCase {
    func testSubjectAnywhereBeatsGreetingAndMailHeaders() {
        let source = "Bonjour Paul,\nDe: anna@example.com\nDate: 10 November\nObjet: Re: Fwd: Atelier budget EFG\nLieu: Genève\nMerci"
        XCTAssertEqual(EventTitle.suggest(from: source, language: .french), "Atelier budget EFG")
    }
    func testRelevantEventSentenceBeatsIntroductionAndLocation() {
        let source = "Hello Anna,\nI hope you are well.\nLocation: Paris\nProject workshop to agree the migration plan.\nThanks"
        XCTAssertEqual(EventTitle.suggest(from: source, language: .english), "Project workshop: migration plan")
    }
    func testShortChineseTitleAndInlineGreeting() {
        XCTAssertEqual(EventTitle.suggest(from: "会议", language: .mandarin), "会议")
        XCTAssertEqual(EventTitle.suggest(from: "Bonjour, réunion de préparation du budget", language: .french), "Réunion de préparation du budget")
    }
    func testMetadataOnlyUsesEditableLocalizedPlaceholder() {
        XCTAssertEqual(EventTitle.suggest(from: "From: anna@example.com\nLocation: Paris\nhttps://example.com", language: .french), "Nouvel événement")
    }
    func testHackathonNameBeatsLongAudienceDescription() {
        let source = """
        Bonjour Monsieur,
        Votre expertise serait pertinente pour une journée organisée avec le DIP/SESAC.
        Le vendredi 20 novembre 2026, nous organisons au SESAC, à Genève, le hackathon jeunesse & IA « Le futur, c'est au présent », dans le cadre de la Semaine de l'entrepreneuriat.
        Cette journée réunira des apprenti·e·s, des jeunes en formation préqualifiante et des élèves d'Acces II autour d'une réflexion très concrète.
        """
        XCTAssertEqual(EventTitle.suggest(from: source, language: .french), "Hackathon jeunesse & IA")
    }
    func testQuotedNameIsKeptWhenEventTypeAloneHasNoTopic() {
        XCTAssertEqual(EventTitle.suggest(from: "Nous organisons un atelier « Architecture Fusion » pour notre équipe.", language: .french), "Atelier Architecture Fusion")
    }
    func testExternalMailPrefixesAreNotPartOfTitle() {
        XCTAssertEqual(EventTitle.suggest(from: "Subject: Re: [External]: Hackathon IA DIP", language: .english), "Hackathon IA DIP")
    }
    func testLogisticsAndPurposeDoNotBecomeLongCalendarTitles() {
        XCTAssertEqual(EventTitle.suggest(from: "We invite you to a webinar on cloud security, which brings together our technical teams.", language: .english), "Webinar on cloud security")
        XCTAssertEqual(EventTitle.suggest(from: "Réunion pour discuter du budget", language: .french), "Réunion: budget")
    }
    func testTitleIsConciseWithoutChangingFullNotes() {
        let subject = "Subject: Project workshop " + String(repeating: "migration planning ", count: 20)
        let draft = EventContentBuilder.build(source: subject, translated: subject, language: .english)
        XCTAssertLessThanOrEqual(draft.title.count, 60)
        XCTAssertLessThanOrEqual(draft.title.split(separator: " ").count, 8)
        XCTAssertFalse(draft.title.contains("…"))
        XCTAssertTrue(draft.notes.contains(subject))
    }
}
