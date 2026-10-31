import Foundation

struct EventDraft {
    var title: String
    var start: Date
    var end: Date
    var location: String = ""
    var url: URL? = nil
    var notes: String
    var detectedDate: Bool
}

/// Local extraction with explicit defaults for immediate event creation.
enum EventParser {
    static func parse(_ text: String, now: Date = Date(), calendar: Calendar = .current, defaultDuration: TimeInterval = 3600, defaultHour: Int = 9) -> EventDraft {
        let folded = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "fr_FR"))
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        let matches = detector?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
        let first = matches.first
        var start = first?.date ?? calendar.date(bySettingHour: defaultHour, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: 1, to: now)!)!
        var detected = first != nil
        func containsAny(_ words: [String]) -> Bool {
            words.contains { word in
                if word.unicodeScalars.contains(where: { $0.value > 0x300 }) { return folded.contains(word) }
                return folded.range(of: "\\b" + NSRegularExpression.escapedPattern(for: word) + "\\b", options: .regularExpression) != nil
            }
        }
        let relative: Int? = containsAny(["apres-demain", "apres demain", "day after tomorrow", "ubermorgen", "dopodomani", "pasado manana", "depois de amanha", "后天", "परसों", "بعد غد"]) ? 2
            : containsAny(["demain", "tomorrow", "morgen", "domani", "manana", "amanha", "明天", "कल", "غدا"]) ? 1
            : containsAny(["aujourd'hui", "aujourd’hui", "today", "heute", "oggi", "hoy", "hoje", "今天", "आज", "اليوم"]) ? 0 : nil
        if let days = relative {
            start = calendar.date(bySettingHour: defaultHour, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: days, to: now)!)!
            detected = true
        } else if first == nil {
            let weekdays = [
                ["dimanche", "sunday", "sonntag", "domenica", "domingo", "星期日", "周日", "रविवार", "الاحد"],
                ["lundi", "monday", "montag", "lunedi", "lunes", "segunda-feira", "星期一", "周一", "सोमवार", "الاثنين"],
                ["mardi", "tuesday", "dienstag", "martedi", "martes", "terca-feira", "星期二", "周二", "मंगलवार", "الثلاثاء"],
                ["mercredi", "wednesday", "mittwoch", "mercoledi", "miercoles", "quarta-feira", "星期三", "周三", "बुधवार", "الاربعاء"],
                ["jeudi", "thursday", "donnerstag", "giovedi", "jueves", "quinta-feira", "星期四", "周四", "गुरुवार", "الخميس"],
                ["vendredi", "friday", "freitag", "venerdi", "viernes", "sexta-feira", "星期五", "周五", "शुक्रवार", "الجمعة"],
                ["samedi", "saturday", "samstag", "sabato", "sabado", "星期六", "周六", "शनिवार", "السبت"]
            ]
            if let index = weekdays.firstIndex(where: { containsAny($0) }) {
                var days = (index + 1 - calendar.component(.weekday, from: now) + 7) % 7
                if days == 0 { days = 7 }
                start = calendar.date(bySettingHour: defaultHour, minute: 0, second: 0, of: calendar.date(byAdding: .day, value: days, to: now)!)!
                detected = true
            }
        }
        let timePattern = #"\b([01]?\d|2[0-3])\s*(?:h|:)\s*([0-5]\d)?\b"#
        let regex = try? NSRegularExpression(pattern: timePattern)
        let times = regex?.matches(in: folded, range: NSRange(folded.startIndex..., in: folded)) ?? []
        func apply(_ match: NSTextCheckingResult, to day: Date) -> Date {
            let ns = folded as NSString
            let hour = Int(ns.substring(with: match.range(at: 1))) ?? 9
            let minute = match.range(at: 2).location == NSNotFound ? 0 : Int(ns.substring(with: match.range(at: 2))) ?? 0
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
        }
        if let time = times.first { start = apply(time, to: start) }
        var end = start.addingTimeInterval((first?.duration ?? 0) > 0 ? first!.duration : defaultDuration)
        if end <= start { end = start.addingTimeInterval(defaultDuration) }
        if times.count > 1 {
            end = apply(times[1], to: start)
            if end <= start { end = calendar.date(byAdding: .day, value: 1, to: end)! }
        }
        let title = text.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })?.trimmingCharacters(in: .whitespacesAndNewlines) ?? tr("New event")
        return EventDraft(title: String(title.prefix(160)), start: start, end: end, notes: text, detectedDate: detected)
    }
}
