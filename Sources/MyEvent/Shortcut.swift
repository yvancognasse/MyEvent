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
    static func read() async throws -> String {
        guard AXIsProcessTrusted() else { throw SelectionError.permission }
        let system = AXUIElementCreateSystemWide()
        var focused: CFTypeRef?
        if AXUIElementCopyAttributeValue(system, kAXFocusedUIElementAttribute as CFString, &focused) == .success, let focused,
           CFGetTypeID(focused) == AXUIElementGetTypeID() {
            var selected: CFTypeRef?
            let element = unsafeBitCast(focused, to: AXUIElement.self)
            if AXUIElementCopyAttributeValue(element, kAXSelectedTextAttribute as CFString, &selected) == .success,
               let text = selected as? String, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return text }
        }
        // Some apps expose Copy but not AXSelectedText. Preserve all pasteboard formats.
        // Let the triggering shortcut's modifiers go before synthesizing Command-C.
        let modifiers: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift]
        for _ in 0..<30 {
            if CGEventSource.flagsState(.combinedSessionState).intersection(modifiers).isEmpty { break }
            try await Task.sleep(for: .milliseconds(50))
        }
        guard CGEventSource.flagsState(.combinedSessionState).intersection(modifiers).isEmpty else { throw SelectionError.empty }
        let board = NSPasteboard.general
        let saved = board.pasteboardItems?.map { item -> NSPasteboardItem in
            let copy = NSPasteboardItem()
            for type in item.types { if let data = item.data(forType: type) { copy.setData(data, forType: type) } }
            return copy
        } ?? []
        let previousChange = board.changeCount
        let source = CGEventSource(stateID: .combinedSessionState)
        for down in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: down)
            event?.flags = .maskCommand
            event?.post(tap: .cghidEventTap)
        }
        var copyChange: Int?
        for _ in 0..<12 {
            try await Task.sleep(for: .milliseconds(50))
            if board.changeCount != previousChange { copyChange = board.changeCount; break }
        }
        guard let copyChange else { throw SelectionError.empty }
        let value = board.string(forType: .string)
        if board.changeCount == copyChange {
            board.clearContents()
            board.writeObjects(saved)
        }
        guard let value, !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw SelectionError.empty }
        return value
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
