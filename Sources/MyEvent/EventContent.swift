import Foundation
import NaturalLanguage
import Translation

/// Translate before saving. Missing assets or unsupported language pairs must never
/// silently save event content in a language other than the selected one.
enum EventTextTranslator {
    enum Failure: LocalizedError {
        case unidentified, unsupported, notInstalled, requiresNewerSystem, failed
        var errorDescription: String? {
            switch self {
            case .unidentified: return tr("The source language could not be identified. Select a longer text and try again.")
            case .unsupported: return tr("Translation is unavailable for this language pair on this Mac. No event was created.")
            case .notInstalled: return tr("Install translation languages in System Settings > General > Language & Region > Translation Languages, then try again. No event was created.")
            case .requiresNewerSystem: return tr("Automatic translation requires macOS 26 or later. No event was created.")
            case .failed: return tr("Translation failed. No event was created.")
            }
        }
    }
    static func translate(_ text: String, to target: AppLanguage) async throws -> String {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let detected = recognizer.dominantLanguage else { throw Failure.unidentified }
        let source = Locale.Language(identifier: detected.rawValue)
        let destination = Locale.Language(identifier: target.rawValue)
        if source.languageCode == destination.languageCode { return text }
        guard #available(macOS 26.0, *) else { throw Failure.requiresNewerSystem }
        let status = await LanguageAvailability().status(from: source, to: destination)
        guard status != .unsupported else { throw Failure.unsupported }
        return try await translateWithFallback(direct: {
            // Installed models normally translate without a window. A view-backed
            // session is still needed if macOS requests consent or a download.
            guard status == .installed else { throw Failure.notInstalled }
            do {
                let session = TranslationSession(installedSource: source, target: destination)
                let response = try await session.translate(text)
                return try validatedText(response.targetText, language: response.targetLanguage, target: destination)
            } catch {
                throw mappedError(error)
            }
        }, interactive: {
            try await TranslationWindow.translate(text, source: source, target: destination)
        })
    }

    static func translateWithFallback(direct: () async throws -> String,
                                      interactive: () async throws -> String) async throws -> String {
        do {
            try Task.checkCancellation()
            return try await direct()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            return try await interactive()
        }
    }

    static func validatedText(_ text: String, language: Locale.Language, target: Locale.Language) throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              language.languageCode == target.languageCode else { throw Failure.failed }
        return text
    }

    @available(macOS 26.0, *)
    static func mappedError(_ error: Error) -> Error {
        switch error {
        case is CancellationError, TranslationError.alreadyCancelled: return CancellationError()
        case TranslationError.notInstalled: return Failure.notInstalled
        case TranslationError.unsupportedSourceLanguage, TranslationError.unsupportedTargetLanguage,
             TranslationError.unsupportedLanguagePairing: return Failure.unsupported
        case TranslationError.unableToIdentifyLanguage: return Failure.unidentified
        case let failure as Failure: return failure
        default: return error
        }
    }
}

/// Keep dates from the original selection, while building the text exclusively
/// from the target-language selection. Never append the untranslated original.
enum EventContentBuilder {
    static func build(source: String, translated: String, language: AppLanguage,
                      now: Date = Date(), calendar: Calendar = .current,
                      defaultDuration: TimeInterval = 3600, defaultHour: Int = 9) -> EventDraft {
        var draft = EventParser.parse(source, now: now, calendar: calendar, defaultDuration: defaultDuration, defaultHour: defaultHour)
        let lines = translated.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        let title = lines.first ?? Translations.text("New event", language: language)
        let prefix = #"(?i)^(?:subject|title|objet|titre|betreff|titel|oggetto|titolo|asunto|título|assunto|主题|标题|विषय|عنوان)\s*[:：]\s*"#
        draft.title = String(title.replacingOccurrences(of: prefix, with: "", options: .regularExpression).prefix(160))
        let locationPattern = #"(?im)^\s*(?:location|venue|place|lieu|adresse|ort|adresse|luogo|sede|lugar|ubicación|local|endereço|地点|地址|स्थान|المكان|الموقع)\s*[:：]\s*(.+)$"#
        if let regex = try? NSRegularExpression(pattern: locationPattern),
           let match = regex.firstMatch(in: translated, range: NSRange(translated.startIndex..., in: translated)),
           let range = Range(match.range(at: 1), in: translated) {
            draft.location = String(translated[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let links = detector?.matches(in: translated, range: NSRange(translated.startIndex..., in: translated)).compactMap(\.url) ?? []
        func unique(_ values: [String]) -> [String] { var seen = Set<String>(); return values.filter { seen.insert($0).inserted } }
        let emails = unique(links.filter { $0.scheme == "mailto" }.map { String($0.absoluteString.dropFirst(7)).removingPercentEncoding ?? "" })
        let webLinks = unique(links.filter { ["https", "http"].contains($0.scheme?.lowercased() ?? "") }.map(\.absoluteString))
        draft.url = webLinks.first.flatMap(URL.init(string:))
        func label(_ key: String) -> String { Translations.text(key, language: language) }
        let dateFormat = Date.FormatStyle(date: .complete, time: .shortened, locale: Locale(identifier: language.rawValue), calendar: calendar, timeZone: calendar.timeZone)
        var sections = ["\(label("Start")): \(draft.start.formatted(dateFormat))", "\(label("End")): \(draft.end.formatted(dateFormat))"]
        if !draft.location.isEmpty { sections.append("\(label("Location")): \(draft.location)") }
        if !emails.isEmpty { sections.append("\(label("Participants")):\n" + emails.joined(separator: "\n")) }
        if !webLinks.isEmpty { sections.append("\(label("Links")):\n" + webLinks.joined(separator: "\n")) }
        sections.append("\(label("Details")):\n\(translated)")
        draft.notes = sections.joined(separator: "\n\n")
        return draft
    }
}
