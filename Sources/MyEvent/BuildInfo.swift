import Foundation

enum BuildInfo {
    static var version: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "Development" }
    static var number: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—" }
    static var date: String {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "MyEventBuildDate") as? String,
              let date = ISO8601DateFormatter().date(from: value) else { return "—" }
        return date.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits).hour().minute().locale(Locale(identifier: AppLanguage.saved.rawValue)))
    }
    static var label: String { "v\(version) · \(tr("Build")) \(number) · \(date)" }
}
