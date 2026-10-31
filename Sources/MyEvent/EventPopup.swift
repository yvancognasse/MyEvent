import AppKit
import SwiftUI

struct EventReceipt {
    let draft: EventDraft
    let destinations: [String]
    let language: AppLanguage
    var displayedNotes: String {
        var sections = draft.notes.components(separatedBy: "\n\n")
        let startLabel = Translations.text("Start", language: language) + ": "
        let endLabel = Translations.text("End", language: language) + ": "
        // Only remove MyEvent's generated preamble, not dates in the source text.
        if sections.count >= 2, sections[0].hasPrefix(startLabel), sections[1].hasPrefix(endLabel) {
            sections.removeFirst(2)
        }
        let detailsLabel = Translations.text("Details", language: language) + ":\n"
        return sections.map { section in
            section.hasPrefix(detailsLabel) ? String(section.dropFirst(detailsLabel.count)) : section
        }.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    var start: String { draft.start.formatted(.dateTime.weekday(.wide).day().month(.wide).year().hour().minute().locale(Locale(identifier: language.rawValue))) }
    var end: String { draft.end.formatted(.dateTime.weekday(.wide).day().month(.wide).year().hour().minute().locale(Locale(identifier: language.rawValue))) }
}

/// A non-activating receipt panel. Never orders the Settings window forward or
/// activates MyEvent; the source application keeps focus after the shortcut.
@MainActor
enum EventPopup {
    private static var panels: [UUID: ReceiptPanel] = [:]
    static func created(_ receipt: EventReceipt) { present(receipt: receipt, error: nil) }
    static func failed(_ message: String) { present(receipt: nil, error: message) }
    private static func present(receipt: EventReceipt?, error: String?) {
        let identifier = UUID()
        let popup = ReceiptPanel(contentRect: NSRect(x: 0, y: 0, width: 440, height: 240), styleMask: [.titled, .closable, .nonactivatingPanel, .utilityWindow], backing: .buffered, defer: false)
        popup.title = "MyEvent"
        popup.level = .floating
        popup.isReleasedWhenClosed = false
        popup.hidesOnDeactivate = false
        popup.canHide = false
        popup.becomesKeyOnlyIfNeeded = true
        popup.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        let content = NSHostingView(rootView: ReceiptView(receipt: receipt, error: error) { [weak popup] in popup?.close() }.frame(width: 440))
        popup.contentView = content
        popup.setContentSize(NSSize(width: 440, height: max(170, min(570, content.fittingSize.height))))
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        if let area = screen?.visibleFrame {
            popup.setFrameTopLeftPoint(NSPoint(x: area.maxX - popup.frame.width - 24, y: area.maxY - 24))
        }
        panels[identifier] = popup
        popup.onClose = { panels.removeValue(forKey: identifier) }
        popup.orderFrontRegardless()

    }
}

@MainActor
private final class ReceiptPanel: NSPanel {
    var onClose: (() -> Void)?
    override func close() {
        super.close()
        onClose?()
        onClose = nil
    }
}

private struct ReceiptView: View {
    let receipt: EventReceipt?
    let error: String?
    let dismiss: () -> Void
    private var language: AppLanguage { receipt?.language ?? .saved }
    private func text(_ key: String) -> String { Translations.text(key, language: language) }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: receipt == nil ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 25)).foregroundStyle(receipt == nil ? Color.orange : Color.green)
                Text(text(receipt == nil ? "Event creation failed" : "Event created")).font(.headline)
            }
            if let receipt {
                Text(receipt.draft.title).font(.title3.weight(.semibold)).lineLimit(3).textSelection(.enabled)
                VStack(alignment: .leading, spacing: 5) {
                    Text(text("Start") + ": " + receipt.start)
                    Text(text("End") + ": " + receipt.end)
                    if !receipt.draft.location.isEmpty { Text(text("Location") + ": " + receipt.draft.location) }
                    Text(text("Calendars") + ": " + receipt.destinations.joined(separator: ", "))
                }.font(.callout).textSelection(.enabled)
                if !receipt.displayedNotes.isEmpty {
                    Divider()
                    ScrollView { Text(receipt.displayedNotes).font(.caption).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled) }
                        .frame(height: 100)
                }
            } else if let error {
                Text(error).font(.callout).fixedSize(horizontal: false, vertical: true).textSelection(.enabled)
            }
            HStack { Spacer(); Button(text("Close"), action: dismiss) }
        }
        .padding(20)
        .environment(\.locale, Locale(identifier: language.rawValue))
        .environment(\.layoutDirection, language.isRightToLeft ? .rightToLeft : .leftToRight)
    }
}
