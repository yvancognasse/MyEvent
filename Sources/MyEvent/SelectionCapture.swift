import Foundation

/// Bounded recovery for cold accessibility/Copy providers. Dependencies allow
/// regression tests without real keyboard events, clipboard access or calendars.
@MainActor
struct SelectionCapture {
    var sourceIsCurrent: () -> Bool
    var keysAreReleased: () -> Bool
    var accessibilityText: () -> String?
    var copiedText: () async throws -> String?
    var pause: (Duration) async throws -> Void = { try await Task.sleep(for: $0) }

    func read() async throws -> String {
        try await waitForRelease()
        try await pause(.milliseconds(80))
        for attempt in 0..<3 {
            try checkSource()
            if let text = usable(accessibilityText()) { return text }
            if attempt < 2 { try await pause(.milliseconds(100)) }
        }
        for attempt in 0..<2 {
            try await waitForRelease()
            if let text = usable(try await copiedText()) {
                try checkSource()
                return text
            }
            try checkSource()
            // The first request can initialize an app's accessibility provider.
            if let text = usable(accessibilityText()) { return text }
            if attempt == 0 { try await pause(.milliseconds(150)) }
        }
        throw SelectionReader.SelectionError.empty
    }

    private func waitForRelease() async throws {
        for _ in 0..<60 {
            try checkSource()
            if keysAreReleased() { return }
            try await pause(.milliseconds(50))
        }
        try checkSource()
        guard keysAreReleased() else { throw SelectionReader.SelectionError.empty }
    }

    private func checkSource() throws {
        try Task.checkCancellation()
        guard sourceIsCurrent() else { throw SelectionReader.SelectionError.empty }
    }

    private func usable(_ text: String?) -> String? {
        guard let text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return text
    }
}

@MainActor
enum SelectionCopy {
    static func read(baseline: Int, changeCount: () -> Int, text: () -> String?,
                     sendCopy: () -> Void, restore: () -> Void, sourceIsCurrent: () -> Bool,
                     pause: (Duration) async throws -> Void = { try await Task.sleep(for: $0) }) async throws -> String? {
        try Task.checkCancellation()
        guard sourceIsCurrent(), changeCount() == baseline else { throw SelectionReader.SelectionError.empty }
        sendCopy()
        var observedChange: Int?
        defer {
            // Never replace a newer clipboard change made while reading the data.
            if let observedChange, changeCount() == observedChange { restore() }
        }
        for _ in 0..<40 {
            try await pause(.milliseconds(50))
            try Task.checkCancellation()
            guard sourceIsCurrent() else { throw SelectionReader.SelectionError.empty }
            let current = changeCount()
            guard current != baseline else { continue }
            observedChange = current
            let value = text()
            guard changeCount() == current, sourceIsCurrent() else {
                throw SelectionReader.SelectionError.empty
            }
            return value
        }
        return nil
    }
}
