import XCTest
import AppKit
@testable import MyEvent

@MainActor
final class ReceiptPanelTests: XCTestCase {
    private final class Editor: NSTextView {
        var commands: [String] = []
        override func copy(_ sender: Any?) { commands.append("copy") }
        override func cut(_ sender: Any?) { commands.append("cut") }
        override func paste(_ sender: Any?) { commands.append("paste") }
        override func selectAll(_ sender: Any?) { commands.append("selectAll") }
    }

    func testNonactivatingPanelRoutesEditingToItsOwnFocusedEditor() {
        _ = NSApplication.shared
        let panel = ReceiptPanel(contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                                 styleMask: [.titled, .nonactivatingPanel], backing: .buffered, defer: false)
        let editor = Editor(frame: panel.contentView!.bounds)
        panel.contentView!.addSubview(editor)
        XCTAssertTrue(panel.makeFirstResponder(editor))
        for key in ["c", "x", "v", "a"] {
            let event = NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: .command,
                                        timestamp: 0, windowNumber: panel.windowNumber, context: nil,
                                        characters: key, charactersIgnoringModifiers: key,
                                        isARepeat: false, keyCode: 0)!
            XCTAssertTrue(panel.performKeyEquivalent(with: event))
        }
        XCTAssertEqual(editor.commands, ["copy", "cut", "paste", "selectAll"])
        // The spy never accesses the user's clipboard, activates a source app,
        // or writes a calendar event.
    }
}
