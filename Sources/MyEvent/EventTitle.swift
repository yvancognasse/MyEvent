import Foundation

/// Prefer an explicit subject, then a meaningful event sentence. Never invent
/// people, topics or a summary that is absent from the selected text.
enum EventTitle {
    private static let subject = #"(?i)^(?:subject|title|objet|titre|betreff|titel|oggetto|titolo|asunto|título|assunto|onderwerp|тема|заголовок|название|主题|标题|विषय|عنوان)\s*[:：]\s*"#
    private static let metadata = #"(?i)^(?:from|to|cc|bcc|sent|date|when|time|start|end|location|venue|place|participants|attendees|links?|de|à|envoyé|le|lieu|adresse|début|fin|von|an|gesendet|datum|ort|beginn|ende|da|a|inviato|data|luogo|inizio|fine|ubicación|fecha|para|enviado|local|endereço|van|aan|verzonden|locatie|plaats|adres|от|кому|дата|место|адрес|начало|окончание|地点|地址|日期|时间|स्थान|المكان|الموقع)\s*[:：]"#
    private static let greeting = #"(?i)^(?:hello|hi|dear|bonjour|bonsoir|salut|cher|chère|hallo|liebe|lieber|ciao|buongiorno|hola|olá|beste|добрый день|здравствуйте|привет|你好|您好|नमस्ते|مرحبا)(?:\s+[^.!?。！？,，:：]{0,45})?[,，:：.!?。！？]*$"#
    private static let eventWords = #"(?i)\b(?:meeting|workshop|review|demo|demonstration|call|appointment|interview|training|conference|réunion|atelier|entretien|formation|rendez-vous|présentation|besprechung|termin|schulung|riunione|incontro|reunión|taller|reunião|overleg|vergadering|afspraak|встреча|совещание|обсуждение)\b|会议|讨论|बैठक|اجتماع"#

    static func suggest(from text: String, language: AppLanguage) -> String {
        let lines = text.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        for line in lines where line.range(of: subject, options: .regularExpression) != nil {
            let value = line.replacingOccurrences(of: subject, with: "", options: .regularExpression)
                .replacingOccurrences(of: #"(?i)^(?:(?:re|fw|fwd|tr|aw|wg)\s*:\s*)+"#, with: "", options: .regularExpression)
            if !value.isEmpty { return compact(value) }
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
                let score = value.range(of: eventWords, options: .regularExpression) == nil ? 0 : 10
                candidates.append((value, score))
            }
        }
        // Stable ordering preserves the first relevant sentence when scores tie.
        guard let best = candidates.enumerated().max(by: {
            $0.element.score == $1.element.score ? $0.offset > $1.offset : $0.element.score < $1.element.score
        })?.element.text else { return Translations.text("New event", language: language) }
        return compact(best)
    }

    private static func compact(_ text: String) -> String {
        let clean = text.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        guard clean.count > 120 else { return clean }
        let prefix = String(clean.prefix(120))
        if let space = prefix.lastIndex(of: " "), prefix.distance(from: prefix.startIndex, to: space) >= 70 {
            return String(prefix[..<space]) + "…"
        }
        return prefix + "…"
    }
}
