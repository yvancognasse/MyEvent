import Foundation
import Combine

/// Opening or closing a draft never invokes the writer. Only a valid explicit
/// confirmation writes, once; a failed write keeps the edits available for retry.
@MainActor
final class EventReviewModel: ObservableObject {
    @Published var draft: EventDraft
    @Published var link: String
    @Published private(set) var confirmed = false
    @Published private(set) var error = ""
    let language: AppLanguage
    let destinations: [String]
    private let save: (EventDraft) throws -> Void

    init(receipt: EventReceipt, save: @escaping (EventDraft) throws -> Void) {
        var editable = receipt.draft
        editable.notes = receipt.displayedNotes
        draft = editable
        link = editable.url?.absoluteString ?? ""
        language = receipt.language
        destinations = receipt.destinations
        self.save = save
    }
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
        guard !confirmed else { return }
        error = ""
        if let validationMessage { error = validationMessage; return }
        var reviewed = draft
        reviewed.title = reviewed.title.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = link.trimmingCharacters(in: .whitespacesAndNewlines)
        reviewed.url = value.isEmpty ? nil : URL(string: value)
        do {
            try save(reviewed)
            draft = reviewed
            confirmed = true
        } catch { self.error = error.localizedDescription }
    }
}
