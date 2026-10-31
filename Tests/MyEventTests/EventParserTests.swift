import XCTest
@testable import MyEvent

final class EventParserTests: XCTestCase {
    var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "Europe/Paris")!
        c.locale = Locale(identifier: "fr_FR")
        return c
    }
    var now: Date { calendar.date(from: DateComponents(year: 2026, month: 10, day: 31, hour: 14))! }
    func testGermanAndItalianRelativeDates() {
        for text in ["Besprechung morgen 14:30", "Riunione domani 14:30"] {
            let draft = EventParser.parse(text, now: now, calendar: calendar)
            XCTAssertEqual(calendar.component(.month, from: draft.start), 11)
            XCTAssertEqual(calendar.component(.day, from: draft.start), 1)
            XCTAssertEqual(calendar.component(.hour, from: draft.start), 14)
        }
    }
    func testTomorrowAndTimeRange() {
        let draft = EventParser.parse("Réunion demain de 14h30 à 15h45", now: now, calendar: calendar)
        XCTAssertEqual(calendar.component(.day, from: draft.start), 1)
        XCTAssertEqual(calendar.component(.month, from: draft.start), 11)
        XCTAssertEqual(calendar.component(.hour, from: draft.start), 14)
        XCTAssertEqual(calendar.component(.minute, from: draft.start), 30)
        XCTAssertEqual(draft.end.timeIntervalSince(draft.start), 75 * 60)
        XCTAssertTrue(draft.detectedDate)
    }
    func testDayAfterTomorrow() {
        let draft = EventParser.parse("RDV après-demain à 9h", now: now, calendar: calendar)
        XCTAssertEqual(calendar.component(.day, from: draft.start), 2)
        XCTAssertEqual(calendar.component(.hour, from: draft.start), 9)
    }
    func testMissingDateIsExplicit() {
        let draft = EventParser.parse("Discussion budget", now: now, calendar: calendar)
        XCTAssertFalse(draft.detectedDate)
        XCTAssertEqual(draft.title, "Discussion budget")
        XCTAssertEqual(draft.notes, "Discussion budget")
        XCTAssertEqual(calendar.component(.hour, from: draft.start), 9)
        XCTAssertEqual(draft.end.timeIntervalSince(draft.start), 3600)
    }
    func testOvernightRange() {
        let draft = EventParser.parse("Maintenance demain 23h00 à 01h00", now: now, calendar: calendar)
        XCTAssertEqual(draft.end.timeIntervalSince(draft.start), 7200)
    }
    func testWeekday() {
        let draft = EventParser.parse("Atelier lundi à 10h", now: now, calendar: calendar)
        XCTAssertEqual(calendar.component(.weekday, from: draft.start), 2)
        XCTAssertEqual(calendar.component(.hour, from: draft.start), 10)
    }
    func testConfiguredDefaultsForImmediateCreation() {
        let draft = EventParser.parse("Discussion budget", now: now, calendar: calendar, defaultDuration: 1800, defaultHour: 11)
        XCTAssertFalse(draft.detectedDate)
        XCTAssertEqual(calendar.component(.day, from: draft.start), 1)
        XCTAssertEqual(calendar.component(.hour, from: draft.start), 11)
        XCTAssertEqual(draft.end.timeIntervalSince(draft.start), 1800)
    }
    func testExplicitRangeOverridesDefaultDuration() {
        let draft = EventParser.parse("Point demain de 10h à 12h", now: now, calendar: calendar, defaultDuration: 1800, defaultHour: 8)
        XCTAssertEqual(calendar.component(.hour, from: draft.start), 10)
        XCTAssertEqual(draft.end.timeIntervalSince(draft.start), 7200)
    }
    func testTodayAndColonTime() {
        let draft = EventParser.parse("Point aujourd'hui à 16:15", now: now, calendar: calendar)
        XCTAssertEqual(calendar.component(.day, from: draft.start), 31)
        XCTAssertEqual(calendar.component(.hour, from: draft.start), 16)
        XCTAssertEqual(calendar.component(.minute, from: draft.start), 15)
    }
}
