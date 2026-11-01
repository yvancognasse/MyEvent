import XCTest
@testable import MyEvent

final class LocalizationTests: XCTestCase {
    func testAllTwelveLanguagesHaveEveryTranslation() {
        XCTAssertEqual(AppLanguage.allCases.count, 12)
        for (key, translations) in Translations.values {
            XCTAssertEqual(translations.count, 12, key)
            for language in AppLanguage.allCases {
                XCTAssertFalse(translations[language.rawValue, default: ""].isEmpty, "\(language): \(key)")
            }
        }
    }
    func testEnglishAndFrenchLabels() {
        XCTAssertEqual(Translations.text("General", language: .english), "General")
        XCTAssertEqual(Translations.text("Settings", language: .french), "Réglages")
        XCTAssertEqual(Translations.text("Language:", language: .mandarin), "语言：")
    }
    func testRequestedLanguagesHaveNativeNamesAndLocalizedActions() {
        XCTAssertEqual(AppLanguage(rawValue: "de"), .german)
        XCTAssertEqual(AppLanguage(rawValue: "it"), .italian)
        for (code, language, name, create, quit, hide) in [
            ("ru", AppLanguage.russian, "Русский · Russian", "Создать событие", "Выйти", "Скрыть"),
            ("nl", AppLanguage.dutch, "Nederlands · Dutch", "Afspraak maken", "Stoppen", "Verberg"),
            ("ro", AppLanguage.romanian, "Română · Romanian", "Creează evenimentul", "Ieșire", "Ascunde")
        ] {
            XCTAssertEqual(AppLanguage(rawValue: code), language)
            XCTAssertEqual(language.displayName, name)
            XCTAssertEqual(Translations.text("Create event", language: language), create)
            XCTAssertEqual(Translations.text("Quit", language: language), quit)
            XCTAssertEqual(Translations.text("Hide", language: language), hide)
        }
    }

    func testRightToLeftLanguages() {
        XCTAssertEqual(AppLanguage.allCases.filter(\.isRightToLeft), [.arabic])
    }
}
