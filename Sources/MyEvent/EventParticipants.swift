import Foundation

/// Participant references belong to notes only. This model never creates invitees.
enum EventParticipants {
    static func entries(from text: String) -> [String] {
        var seen = Set<String>()
        return text.components(separatedBy: CharacterSet(charactersIn: ",;\n\r"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
    }

    static func detected(in source: String) -> [String] {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let emails = detector?.matches(in: source, range: NSRange(source.startIndex..., in: source))
            .compactMap(\.url).filter { $0.scheme == "mailto" }
            .map { URLComponents(url: $0, resolvingAgainstBaseURL: false)?.path ?? "" } ?? []
        return entries(from: emails.joined(separator: "\n"))
    }

    static func notes(_ notes: String, participants: [String], language: AppLanguage) -> String {
        guard !participants.isEmpty else { return notes }
        let section = Translations.text("Participants", language: language) + ":\n" + participants.joined(separator: "\n")
        return notes.isEmpty ? section : section + "\n\n" + notes
    }
}
