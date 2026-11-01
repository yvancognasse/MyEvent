import XCTest
@testable import MyEvent

final class EventParticipantsTests: XCTestCase {
    func testSeparatorsEmptyValuesAndCaseInsensitiveDuplicates() {
        XCTAssertEqual(EventParticipants.entries(from: " Anna Martin; anna@example.com\nANNA@example.com,\rSam Lee;; "),
                       ["Anna Martin", "anna@example.com", "Sam Lee"])
    }
    func testOnlySourceEmailReferencesPrefillTheField() {
        let draft = EventContentBuilder.build(source: "Meeting with Anna anna@example.com", translated: "Meeting invented@example.com", language: .english)
        XCTAssertEqual(draft.participants, ["anna@example.com"])
    }
    func testMailtoSubjectIsNotIncludedInParticipantAddress() {
        XCTAssertEqual(EventParticipants.detected(in: "mailto:anna@example.com?subject=Budget"), ["anna@example.com"])
    }
    func testNoParticipantsAreInventedFromNamesOrWebLinks() {
        XCTAssertEqual(EventParticipants.detected(in: "Meeting with Anna https://example.com"), [])
    }
    func testEmptyListDoesNotModifyNotes() {
        XCTAssertEqual(EventParticipants.notes("Keep these notes", participants: [], language: .french), "Keep these notes")
    }
}
