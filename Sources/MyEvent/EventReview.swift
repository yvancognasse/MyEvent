import Foundation
import Combine

/// Opening or closing a draft never invokes the writer. Only a valid explicit
/// confirmation writes, once; a failed write keeps the edits available for retry.
@MainActor
final class EventReviewModel: ObservableObject {
    @Published var draft: EventDraft
    @Published var link: String
    @Published var participants: String
    @Published private(set) var confirmed = false
    @Published private(set) var error = ""
    let language: AppLanguage
    @Published private(set) var eventLanguage: AppLanguage?
    @Published private(set) var translating = false
    typealias TranslateText = (String, AppLanguage, Locale.Language?) async throws -> String
    private let translateText: TranslateText
    private var translationTask: Task<EventDraft, Error>?
    private var suggestedTitle: String
    let destinations: [String]
    private let save: (EventDraft) throws -> Void

    init(receipt: EventReceipt,
         translateText: @escaping TranslateText = { text, target, source in
             try await EventTextTranslator.translate(text, to: target, source: source)
         }, save: @escaping (EventDraft) throws -> Void) {
        var editable = receipt.draft
        editable.notes = receipt.displayedNotes
        draft = editable
        suggestedTitle = editable.title
        link = editable.url?.absoluteString ?? ""
        participants = editable.participants.joined(separator: ", ")
        language = receipt.language
        eventLanguage = receipt.contentLanguage ?? EventTextTranslator.detectedAppLanguage(in: editable.notes + "\n" + editable.title)
        self.translateText = translateText
        destinations = receipt.destinations
        self.save = save
    }
    /// Translate the current edited values as one transaction. No partial result
    /// becomes saveable if a field fails, the request is cancelled, or the panel closes.
    func translateEvent(to target: AppLanguage) async {
        guard !confirmed, !translating, target != eventLanguage else { return }
        translating = true
        error = ""
        let snapshot = draft
        let shortenTranslatedTitle = snapshot.title == suggestedTitle
        let source = eventLanguage.map { Locale.Language(identifier: $0.rawValue) }
            ?? EventTextTranslator.detectedLanguage(in: snapshot.notes + "\n" + snapshot.title)
        let translate = translateText
        let task = Task { () throws -> EventDraft in
            func field(_ text: String) async throws -> String {
                try Task.checkCancellation()
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return text }
                let translated = try await translate(text, target, source)
                guard !translated.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    throw EventTextTranslator.Failure.failed
                }
                // Links and email references are identifiers, not words to rewrite.
                let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
                let references = detector.matches(in: text, range: NSRange(text.startIndex..., in: text))
                guard references.allSatisfy({ translated.contains((text as NSString).substring(with: $0.range)) }) else {
                    throw EventTextTranslator.Failure.failed
                }
                return translated
            }
            var result = snapshot
            let translatedTitle = try await field(snapshot.title)
            result.title = shortenTranslatedTitle ? EventTitle.concise(translatedTitle) : translatedTitle
            result.location = try await field(snapshot.location)
            result.notes = try await field(snapshot.notes)
            try Task.checkCancellation()
            return result
        }
        translationTask = task
        defer { translationTask = nil; translating = false }
        do {
            let translated = try await task.value
            guard !task.isCancelled else { return }
            draft = translated
            if shortenTranslatedTitle { suggestedTitle = translated.title }
            eventLanguage = target
        } catch is CancellationError {
            // Keep all edited values and the previous content language.
        } catch {
            self.error = error.localizedDescription
        }
    }

    func cancelTranslation() { translationTask?.cancel() }

    private var validationKey: String? {
        if draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return "Enter an event title." }
        if draft.end <= draft.start { return "The end must be after the start." }
        let value = link.trimmingCharacters(in: .whitespacesAndNewlines)
        if !value.isEmpty {
            guard let url = URL(string: value), ["http", "https"].contains(url.scheme?.lowercased() ?? ""),
                  let host = url.host, !host.isEmpty else { return "Enter a valid http or https link." }
        }
        return nil
    }
    var validationMessage: String? { validationKey.map { Translations.text($0, language: language) } }
    func confirm() {
        guard !confirmed, !translating else { return }
        error = ""
        if let validationMessage { error = validationMessage; return }
        var reviewed = draft
        reviewed.title = reviewed.title.trimmingCharacters(in: .whitespacesAndNewlines)
        reviewed.participants = EventParticipants.entries(from: participants)
        reviewed.notes = EventParticipants.notes(reviewed.notes, participants: reviewed.participants,
                                                 language: eventLanguage ?? language)
        let value = link.trimmingCharacters(in: .whitespacesAndNewlines)
        reviewed.url = value.isEmpty ? nil : URL(string: value)
        do {
            try save(reviewed)
            draft = reviewed
            confirmed = true
        } catch { self.error = error.localizedDescription }
    }
}
