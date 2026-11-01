import Foundation

/// Extract a short event name and topic rather than copying a descriptive sentence.
/// Every word comes from the selection; the complete source remains in the notes.
enum EventTitle {
    private static let subject = #"(?i)^(?:subject|title|objet|titre|betreff|titel|oggetto|titolo|asunto|título|assunto|onderwerp|тема|заголовок|название|主题|标题|विषय|عنوان)\s*[:：]\s*"#
    private static let metadata = #"(?i)^(?:from|to|cc|bcc|sent|date|when|time|start|end|location|venue|place|participants|attendees|links?|de|à|envoyé|le|lieu|adresse|début|fin|von|an|gesendet|datum|ort|beginn|ende|da|a|inviato|data|luogo|inizio|fine|ubicación|fecha|para|enviado|local|endereço|van|aan|verzonden|locatie|plaats|adres|от|кому|дата|место|адрес|начало|окончание|地点|地址|日期|时间|स्थान|المكان|الموقع)\s*[:：]"#
    private static let greeting = #"(?i)^(?:hello|hi|dear|bonjour|bonsoir|salut|cher|chère|hallo|liebe|lieber|ciao|buongiorno|hola|olá|beste|добрый день|здравствуйте|привет|你好|您好|नमस्ते|مرحبا)(?:\s+[^.!?。！？,，:：]{0,45})?[,，:：.!?。！？]*$"#
    private static let eventWords = #"(?i)\b(?:hackath?on|webinar|webinaire|seminar|séminaire|seminario|seminário|congresso|congreso|congrès|конференция|семинар|хакатон|meeting|workshop|review|demo|demonstration|call|appointment|interview|training|conference|réunion|atelier|entretien|formation|rendez-vous|présentation|besprechung|termin|schulung|riunione|incontro|reunión|taller|reunião|overleg|vergadering|afspraak|встреча|совещание|обсуждение)\b|会议|讨论|बैठक|اجتماع"#

    static func suggest(from text: String, language: AppLanguage) -> String {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        for line in lines where line.range(of: subject, options: .regularExpression) != nil {
            let value = line.replacingOccurrences(of: subject, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"(?i)^(?:(?:re|fw|fwd|tr|aw|wg)\s*:\s*)+"#, with: "", options: .regularExpression)
            let cleaned = clean(value)
            if !cleaned.isEmpty {
                let phrases = eventNames(in: cleaned)
                return concise(phrases.max(by: { $0.score < $1.score })?.text ?? cleaned)
            }
        }
        var candidates: [(text: String, score: Int)] = []
        for originalLine in lines {
            let line = originalLine.replacingOccurrences(of: #"(?i)^(?:hello|hi|bonjour|bonsoir|salut|hallo|ciao|hola|olá|beste|привет|здравствуйте|你好|您好|नमस्ते|مرحبا)(?:\s+[^,，:：.!?]{1,30})?\s*[,，:：]\s*"#, with: "", options: .regularExpression)
            guard line.range(of: metadata, options: .regularExpression) == nil,
                  line.range(of: greeting, options: .regularExpression) == nil,
                  line.range(of: #"(?i)^(?:thanks|thank you|regards|best regards|merci|cordialement|mit freundlichen|saluti|gracias|obrigad[oa]|groeten|спасибо)\b"#, options: .regularExpression) == nil else { continue }
            line.enumerateSubstrings(in: line.startIndex..., options: .bySentences) { sentence, _, _, _ in
                let value = (sentence ?? line).trimmingCharacters(in: .whitespacesAndNewlines)
                guard value.unicodeScalars.filter({ CharacterSet.letters.contains($0) }).count >= 2,
                      value.range(of: #"^(?:https?://|[^\s]+@[^\s]+$)"#, options: .regularExpression) == nil else { return }
                candidates.append(contentsOf: eventNames(in: value))
                candidates.append((value, 0))
            }
        }
        // Stable ordering preserves the first relevant sentence when scores tie.
        guard let best = candidates.enumerated().max(by: {
            $0.element.score == $1.element.score ? $0.offset > $1.offset : $0.element.score < $1.element.score
        })?.element.text else { return Translations.text("New event", language: language) }
        return concise(best)
    }

    private static func eventNames(in sentence: String) -> [(text: String, score: Int)] {
        guard let regex = try? NSRegularExpression(pattern: eventWords) else { return [] }
        return regex.matches(in: sentence, range: NSRange(sentence.startIndex..., in: sentence)).compactMap { match in
            guard let range = Range(match.range, in: sentence) else { return nil }
            let keyword = String(sentence[range])
            let prefix = String(sentence[..<range.lowerBound]).trimmingCharacters(in: .whitespaces)
            let first = prefix.components(separatedBy: .whitespaces).first?.lowercased() ?? ""
            let boilerplate = ["le", "la", "les", "un", "une", "nous", "vous", "cette", "ce", "the", "a", "an", "we", "i", "you", "wir", "sie", "der", "die", "das", "il", "lo", "gli", "el", "los", "o", "os", "de", "het", "een", "мы", "вы", "это"]
            let keepPrefix = !prefix.isEmpty && !boilerplate.contains(first)
                && prefix.range(of: #"^[\p{L}\p{N}&+'’/-]+(?:\s+[\p{L}\p{N}&+'’/-]+){0,2}$"#, options: .regularExpression) != nil
            var name = (keepPrefix ? prefix + " " : "") + String(sentence[range.lowerBound...])
            // Separate the event name from its quoted slogan, logistics or audience.
            let boundary = #"[«“\"]|[,;.!?。！？]|\s+(?i:dans le cadre|qui|afin de|durant|during|which|that|as part of|where|mit dem Ziel|im Rahmen|die dabei|nell'ambito|che riunirà|en el marco|que reunirá|no âmbito|que reunirá|in het kader|waar|который|которая|которое|в рамках)\b"#
            if let cut = name.range(of: boundary, options: .regularExpression) {
                let shorter = String(name[..<cut.lowerBound])
                // If only the event type precedes a quote, retain the actual name.
                if shorter.trimmingCharacters(in: .whitespaces).lowercased() == keyword.lowercased(),
                   let quoted = name.range(of: #"[«“\"]([^»”\"]+)[»”\"]"#, options: .regularExpression) {
                    name = shorter + " " + name[quoted].trimmingCharacters(in: CharacterSet(charactersIn: "«»“”\""))
                } else { name = shorter }
            }
            name = name.replacingOccurrences(of: #"(?i)\s+(?:to (?:agree(?: on)?|discuss|review|prepare)(?: the)?|pour (?:faire le point sur|discuter|échanger sur)(?: de| du| des| le| la| les)?)\s+"#, with: ": ", options: .regularExpression)
            let specific = keyword.range(of: #"(?i)^(?:hackath?on|webinar|webinaire|seminar|séminaire|seminario|seminário|congresso|congreso|congrès|конференция|семинар|хакатон)$"#, options: .regularExpression) != nil
            return (clean(name), specific ? 40 : 10)
        }
    }

    private static func clean(_ text: String) -> String {
        text.replacingOccurrences(of: #"(?i)^(?:(?:re|fw|fwd|tr|aw|wg)\s*:\s*|\[(?:external|externe|extern)\]\s*:?\s*)+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines.union(CharacterSet(charactersIn: ".,:;—–-…")))
    }

    /// Applies to automatically proposed titles only, including after translation.
    /// Manual edits are never truncated. Avoid ellipses that conceal the subject.
    static func concise(_ text: String) -> String {
        let cleaned = clean(text)
        let words = cleaned.split(whereSeparator: \.isWhitespace)
        var result = ""
        for word in words.prefix(8) {
            let candidate = result.isEmpty ? String(word) : result + " " + word
            guard candidate.count <= 60 else { break }
            result = candidate
        }
        if result.isEmpty { result = String(cleaned.prefix(60)) }
        // Unspaced scripts need a character limit rather than a word limit.
        if words.count == 1, result.unicodeScalars.contains(where: { (0x3400...0x9FFF).contains($0.value) }) {
            result = String(result.prefix(24))
        }
        result = clean(result)
        guard let first = result.first else { return result }
        return String(first).uppercased() + result.dropFirst()
    }
}
