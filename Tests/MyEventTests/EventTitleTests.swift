import XCTest
@testable import MyEvent

final class EventTitleTests: XCTestCase {
    func testSubjectAnywhereBeatsGreetingAndMailHeaders() {
        let source = "Bonjour Paul,\nDe: anna@example.com\nDate: 10 November\nObjet: Re: Fwd: Atelier budget EFG\nLieu: Genève\nMerci"
        XCTAssertEqual(EventTitle.suggest(from: source, language: .french), "Atelier budget EFG")
    }
    func testRelevantEventSentenceBeatsIntroductionAndLocation() {
        let source = "Hello Anna,\nI hope you are well.\nLocation: Paris\nProject workshop to agree the migration plan.\nThanks"
        XCTAssertEqual(EventTitle.suggest(from: source, language: .english), "Project workshop to agree the migration plan.")
    }
    func testShortChineseTitleAndInlineGreeting() {
        XCTAssertEqual(EventTitle.suggest(from: "会议", language: .mandarin), "会议")
        XCTAssertEqual(EventTitle.suggest(from: "Bonjour, réunion de préparation du budget", language: .french), "réunion de préparation du budget")
    }
    func testMetadataOnlyUsesEditableLocalizedPlaceholder() {
        XCTAssertEqual(EventTitle.suggest(from: "From: anna@example.com\nLocation: Paris\nhttps://example.com", language: .french), "Nouvel événement")
    }
    func testTitleIsConciseWithoutChangingFullNotes() {
        let subject = "Subject: Project workshop " + String(repeating: "migration planning ", count: 20)
        let draft = EventContentBuilder.build(source: subject, translated: subject, language: .english)
        XCTAssertLessThanOrEqual(draft.title.count, 121)
        XCTAssertTrue(draft.title.hasSuffix("…"))
        XCTAssertTrue(draft.notes.contains(subject))
    }
}
