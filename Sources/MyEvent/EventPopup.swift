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

/// Separate panels never reopen Settings. Clicking a field makes the review panel
/// key without activating the app's Settings window. No timer dismisses a draft.
@MainActor
enum EventPopup {
    private static var panels: [UUID: ReceiptPanel] = [:]
    static func review(_ receipt: EventReceipt, save: @escaping (EventDraft) throws -> Void) {
        let model = EventReviewModel(receipt: receipt, save: save)
        present { dismiss in EventReviewView(model: model, dismiss: dismiss) }
    }
    static func failed(_ message: String) {
        present { dismiss in FailureView(message: message, language: .saved, dismiss: dismiss) }
    }
    private static func present<Content: View>(@ViewBuilder content: (@escaping () -> Void) -> Content) {
        let identifier = UUID()
        let mouse = NSEvent.mouseLocation
        let screen = NSScreen.screens.first { $0.frame.contains(mouse) } ?? NSScreen.main
        let width = min(520, (screen?.visibleFrame.width ?? 800) - 48)
        let height = min(590, (screen?.visibleFrame.height ?? 800) - 48)
        let popup = ReceiptPanel(contentRect: NSRect(x: 0, y: 0, width: width, height: height), styleMask: [.titled, .closable, .nonactivatingPanel, .utilityWindow], backing: .buffered, defer: false)
        popup.title = "MyEvent"
        popup.level = .floating
        popup.isReleasedWhenClosed = false
        popup.hidesOnDeactivate = false
        popup.canHide = false
        popup.becomesKeyOnlyIfNeeded = false
        popup.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        popup.contentView = NSHostingView(rootView: content { [weak popup] in popup?.close() }
            .frame(width: width, height: height))
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
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
    override func close() {
        super.close()
        onClose?()
        onClose = nil
    }
}

private struct EventReviewView: View {
    @ObservedObject var model: EventReviewModel
    let dismiss: () -> Void
    private func text(_ key: String) -> String { Translations.text(key, language: model.language) }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(text(model.confirmed ? "Event created" : "Review event"),
                  systemImage: model.confirmed ? "checkmark.circle.fill" : "calendar.badge.plus")
                .font(.headline).foregroundStyle(model.confirmed ? Color.green : Color.primary)
            if !model.confirmed {
                Text(text("Review the details, then confirm to create the event."))
                    .font(.callout).foregroundStyle(.secondary)
            }
            ScrollView {
                if model.confirmed {
                    let receipt = EventReceipt(draft: model.draft, destinations: model.destinations, language: model.language)
                    VStack(alignment: .leading, spacing: 10) {
                        Text(model.draft.title).font(.title3.weight(.semibold))
                        Text(text("Start") + ": " + receipt.start)
                        Text(text("End") + ": " + receipt.end)
                        if !model.draft.location.isEmpty { Text(text("Location") + ": " + model.draft.location) }
                        if let url = model.draft.url { Text(text("Link") + ": " + url.absoluteString) }
                        if !model.draft.notes.isEmpty {
                            Divider()
                            Text(model.draft.notes).font(.callout)
                        }
                    }.frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        LabeledContent(text("Title")) { TextField(text("Title"), text: $model.draft.title).labelsHidden() }
                        DatePicker(text("Start"), selection: $model.draft.start, displayedComponents: [.date, .hourAndMinute])
                        DatePicker(text("End"), selection: $model.draft.end, displayedComponents: [.date, .hourAndMinute])
                        LabeledContent(text("Location")) { TextField(text("Location"), text: $model.draft.location).labelsHidden() }
                        LabeledContent(text("Link")) { TextField(text("Link"), text: $model.link).labelsHidden() }
                        Divider()
                        Text(text("Notes")).font(.callout)
                        TextEditor(text: $model.draft.notes)
                            .font(.body).frame(minHeight: 140)
                            .border(Color.secondary.opacity(0.25))
                            .accessibilityLabel(text("Notes"))
                    }.textFieldStyle(.roundedBorder)
                }
                Text(text("Calendars") + ": " + model.destinations.joined(separator: ", "))
                    .font(.caption).frame(maxWidth: .infinity, alignment: .leading).padding(.top, 10)
                    .textSelection(.enabled)
            }
            if let message = model.validationMessage, !model.confirmed {
                Text(message).font(.caption).foregroundStyle(.orange)
            }
            if !model.error.isEmpty { Text(model.error).font(.callout).foregroundStyle(.red).textSelection(.enabled) }
            HStack {
                Spacer()
                Button(text(model.confirmed ? "Close" : "Cancel"), action: dismiss).keyboardShortcut(.cancelAction)
                if !model.confirmed {
                    Button(text("Create event")) { model.confirm() }
                        .keyboardShortcut(.defaultAction)
                        .disabled(model.validationMessage != nil)
                }
            }
        }.padding(20)
            .environment(\.locale, Locale(identifier: model.language.rawValue))
            .environment(\.layoutDirection, model.language.isRightToLeft ? .rightToLeft : .leftToRight)
    }
}

private struct FailureView: View {
    let message: String
    let language: AppLanguage
    let dismiss: () -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(Translations.text("Event creation failed", language: language), systemImage: "exclamationmark.triangle.fill")
                .font(.headline).foregroundStyle(.orange)
            ScrollView { Text(message).frame(maxWidth: .infinity, alignment: .leading).textSelection(.enabled) }
            HStack { Spacer(); Button(Translations.text("Close", language: language), action: dismiss) }
        }.padding(20)
            .environment(\.locale, Locale(identifier: language.rawValue))
            .environment(\.layoutDirection, language.isRightToLeft ? .rightToLeft : .leftToRight)
    }
}
