import XCTest
@testable import MyEvent

final class LocalizationTests: XCTestCase {
    func testAllNineLanguagesHaveEveryTranslation() {
        XCTAssertEqual(AppLanguage.allCases.count, 9)
        for (key, translations) in Translations.values {
            XCTAssertEqual(translations.count, 9, key)
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
    func testRightToLeftLanguages() {
        XCTAssertEqual(AppLanguage.allCases.filter(\.isRightToLeft), [.arabic])
    }
}
