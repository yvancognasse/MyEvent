import AppKit
import Carbon

struct Shortcut: Codable, Equatable {
    var keyCode: UInt32 = 46
    var modifiers: UInt32 = UInt32(cmdKey | shiftKey)
    var keyLabel: String = "M"
    var label: String {
        (modifiers & UInt32(controlKey) != 0 ? "⌃" : "") +
        (modifiers & UInt32(optionKey) != 0 ? "⌥" : "") +
        (modifiers & UInt32(shiftKey) != 0 ? "⇧" : "") +
        (modifiers & UInt32(cmdKey) != 0 ? "⌘" : "") + keyLabel
    }
    static func from(_ event: NSEvent) -> Shortcut? {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        guard flags.contains(.command) || flags.contains(.control) || flags.contains(.option),
              ![48, 53, 36, 76, 51, 117].contains(Int(event.keyCode)),
              let chars = event.charactersIgnoringModifiers, !chars.isEmpty else { return nil }
        var mods: UInt32 = 0
        if flags.contains(.command) { mods |= UInt32(cmdKey) }
        if flags.contains(.control) { mods |= UInt32(controlKey) }
        if flags.contains(.option) { mods |= UInt32(optionKey) }
        if flags.contains(.shift) { mods |= UInt32(shiftKey) }
        return Shortcut(keyCode: UInt32(event.keyCode), modifiers: mods, keyLabel: chars.uppercased())
    }
}

final class HotKey {
    private var reference: EventHotKeyRef?
    private var handler: EventHandlerRef?
    var action: (() -> Void)?
    init() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return OSStatus(eventNotHandledErr) }
            Unmanaged<HotKey>.fromOpaque(context).takeUnretainedValue().action?()
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }
    func register(_ shortcut: Shortcut) -> Bool {
        // Register the replacement first so a conflict leaves the old shortcut intact.
        var candidate: EventHotKeyRef?
        let status = RegisterEventHotKey(shortcut.keyCode, shortcut.modifiers, EventHotKeyID(signature: 0x4D59544D, id: 1), GetApplicationEventTarget(), 0, &candidate)
        guard status == noErr else { return false }
        if let reference { UnregisterEventHotKey(reference) }
        reference = candidate
        return true
    }
    func suspend() { if let reference { UnregisterEventHotKey(reference) }; reference = nil }
    deinit { suspend(); if let handler { RemoveEventHandler(handler) } }
}

@MainActor
enum SelectionReader {
    static func read(shortcut: Shortcut) async throws -> String {
        guard AXIsProcessTrusted() else { throw SelectionError.permission }
        guard let sourceApp = NSWorkspace.shared.frontmostApplication else { throw SelectionError.empty }
        let pid = sourceApp.processIdentifier
        let application = AXUIElementCreateApplication(pid)
        AXUIElementSetMessagingTimeout(application, 0.25)
        var originalWindow: AXUIElement?

        func sourceIsCurrent() -> Bool {
            NSWorkspace.shared.frontmostApplication?.processIdentifier == pid
        }
        func sameWindow() -> Bool {
            guard sourceIsCurrent() else { return false }
            var focused: CFTypeRef?
            let status = AXUIElementCopyAttributeValue(application, kAXFocusedWindowAttribute as CFString, &focused)
            guard status == .success, let focused, CFGetTypeID(focused) == AXUIElementGetTypeID() else {
                // A cold provider may not expose a window on its first request.
                return originalWindow == nil
            }
            let window = unsafeBitCast(focused, to: AXUIElement.self)
            if let originalWindow { return CFEqual(originalWindow, window) }
            originalWindow = window
            return true
        }
        _ = sameWindow()
        let capture = SelectionCapture(sourceIsCurrent: sourceIsCurrent, keysAreReleased: {
            let modifiers: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift]
            return CGEventSource.flagsState(.combinedSessionState).intersection(modifiers).isEmpty
                && !CGEventSource.keyState(.combinedSessionState, key: CGKeyCode(truncatingIfNeeded: shortcut.keyCode))
        }, accessibilityText: {
            guard sameWindow() else { return nil }
            var focused: CFTypeRef?
            guard AXUIElementCopyAttributeValue(application, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
                  let focused, CFGetTypeID(focused) == AXUIElementGetTypeID() else { return nil }
            let element = unsafeBitCast(focused, to: AXUIElement.self)
            var elementPID: pid_t = 0
            guard AXUIElementGetPid(element, &elementPID) == .success, elementPID == pid else { return nil }
            AXUIElementSetMessagingTimeout(element, 0.25)
            var selected: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selected) == .success else { return nil }
            return selected as? String
        }, copiedText: {
            guard sameWindow() else { throw SelectionError.empty }
            let board = NSPasteboard.general
            let baseline = board.changeCount
            // Snapshot every available format, not just plain text.
            let saved = board.pasteboardItems?.map { item -> NSPasteboardItem in
                let copy = NSPasteboardItem()
                for type in item.types {
                    if let data = item.data(forType: type) { copy.setData(data, forType: type) }
                }
                return copy
            } ?? []
            return try await SelectionCopy.read(baseline: baseline, changeCount: { board.changeCount },
                text: { board.string(forType: .string) }, sendCopy: {
                    let source = CGEventSource(stateID: .combinedSessionState)
                    for down in [true, false] {
                        let event = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: down)
                        event?.flags = .maskCommand
                        event?.post(tap: .cghidEventTap)
                    }
                }, restore: {
                    board.clearContents()
                    if !saved.isEmpty { board.writeObjects(saved) }
                }, sourceIsCurrent: sourceIsCurrent)
        })
        let text = try await capture.read()
        guard sameWindow() else { throw SelectionError.empty }
        return text
    }
    enum SelectionError: LocalizedError {
        case permission, empty
        var errorDescription: String? {
            switch self {
            case .permission: return tr("Allow MyEvent in System Settings > Privacy & Security > Accessibility, then try the shortcut again.")
            case .empty: return tr("No selected text is accessible. Select text in the source app, release the shortcut keys and try again.")
            }
        }
    }
}
