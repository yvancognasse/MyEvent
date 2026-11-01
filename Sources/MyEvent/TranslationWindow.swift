import AppKit
import SwiftUI
import Translation

/// A view-backed session lets macOS request translation consent or missing models.
/// Keep the view alive until the request completes; a headless session cannot do this.
@available(macOS 26.0, *)
@MainActor
final class TranslationWindow: NSObject, NSWindowDelegate {
    private static var active: TranslationWindow?
    private var continuation: CheckedContinuation<String, Error>?
    private var panel: NSPanel?

    static func translate(_ text: String, source: Locale.Language, target: Locale.Language) async throws -> String {
        let controller = TranslationWindow()
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            return try await withCheckedThrowingContinuation { continuation in
                controller.continuation = continuation
                active = controller
                let panel = NSPanel(contentRect: NSRect(x: 0, y: 0, width: 420, height: 150),
                                    styleMask: [.titled, .closable], backing: .buffered, defer: false)
                panel.title = "MyEvent"
                panel.isReleasedWhenClosed = false
                panel.delegate = controller
                panel.contentView = NSHostingView(rootView: TranslationProgress(
                    text: text, source: source, target: target,
                    finish: { controller.finish($0) }))
                controller.panel = panel
                panel.center()
                panel.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        } onCancel: {
            Task { @MainActor in controller.finish(.failure(CancellationError())) }
        }
    }

    private func finish(_ result: Result<String, Error>, closePanel: Bool = true) {
        guard let continuation else { return }
        self.continuation = nil
        if closePanel { panel?.close() }
        panel = nil
        if Self.active === self { Self.active = nil }
        continuation.resume(with: result)
    }

    func windowWillClose(_ notification: Notification) {
        finish(.failure(CancellationError()), closePanel: false)
    }
}

@available(macOS 26.0, *)
private struct TranslationProgress: View {
    let text: String
    let source: Locale.Language
    let target: Locale.Language
    let finish: (Result<String, Error>) -> Void

    var body: some View {
        VStack(spacing: 16) {
            ProgressView(tr("Translating event text…"))
            Button(tr("Cancel")) { finish(.failure(CancellationError())) }
        }
        .environment(\.locale, Locale(identifier: AppLanguage.saved.rawValue))
        .environment(\.layoutDirection, AppLanguage.saved.isRightToLeft ? .rightToLeft : .leftToRight)
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .translationTask(source: source, target: target) { session in
            do {
                let translated = try await EventTextTranslator.translatedText(text, using: session, target: target)
                finish(.success(translated))
            } catch {
                finish(.failure(EventTextTranslator.mappedError(error)))
            }
        }
    }
}
