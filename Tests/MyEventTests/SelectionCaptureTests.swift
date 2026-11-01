import XCTest
@testable import MyEvent

@MainActor
final class SelectionCaptureTests: XCTestCase {
    func testColdAccessibilityProviderRecoversWithoutCopyOrSecondShortcut() async throws {
        var reads = 0
        let capture = SelectionCapture(sourceIsCurrent: { true }, keysAreReleased: { true }, accessibilityText: {
            reads += 1
            return reads == 3 ? "Original selection" : nil
        }, copiedText: { XCTFail("Accessibility recovered; Copy is unnecessary"); return nil }, pause: { _ in })
        let text = try await capture.read()
        XCTAssertEqual(text, "Original selection")
        XCTAssertEqual(reads, 3)
    }

    func testFirstIgnoredCopyIsRetriedWithinOneCapture() async throws {
        var copies = 0
        let capture = SelectionCapture(sourceIsCurrent: { true }, keysAreReleased: { true }, accessibilityText: { nil }, copiedText: {
            copies += 1
            return copies == 2 ? "Selected email" : nil
        }, pause: { _ in })
        let text = try await capture.read()
        XCTAssertEqual(text, "Selected email")
        XCTAssertEqual(copies, 2)
    }

    func testHeldTriggerKeyPreventsReadingOrCopyUntilRelease() async throws {
        var released = false
        var polls = 0
        let capture = SelectionCapture(sourceIsCurrent: { true }, keysAreReleased: { released }, accessibilityText: {
            XCTAssertTrue(released)
            return "Selected text"
        }, copiedText: { XCTFail("No Copy needed"); return nil }, pause: { _ in
            polls += 1
            if polls == 4 { released = true }
        })
        _ = try await capture.read()
        XCTAssertTrue(released)
        XCTAssertGreaterThanOrEqual(polls, 4)
    }

    func testUnreleasedKeysFailWithoutSynthesizingCopy() async {
        var polls = 0
        let capture = SelectionCapture(sourceIsCurrent: { true }, keysAreReleased: { false }, accessibilityText: {
            XCTFail("Keys are still held"); return nil
        }, copiedText: { XCTFail("Must not send Copy with shortcut held"); return nil }, pause: { _ in polls += 1 })
        do { _ = try await capture.read(); XCTFail("Expected release timeout") } catch {}
        XCTAssertEqual(polls, 60)
    }

    func testFocusChangeStopsRecoveryBeforeCopy() async {
        var sameSource = true
        let capture = SelectionCapture(sourceIsCurrent: { sameSource }, keysAreReleased: { true }, accessibilityText: { nil }, copiedText: {
            XCTFail("Do not copy from another application"); return nil
        }, pause: { _ in sameSource = false })
        do { _ = try await capture.read(); XCTFail("Expected changed-source failure") } catch {}
    }

    func testMissingSelectionHasBoundedRetriesAndNoStaleFallback() async {
        var copies = 0
        let capture = SelectionCapture(sourceIsCurrent: { true }, keysAreReleased: { true }, accessibilityText: { " \n " }, copiedText: {
            copies += 1
            return nil
        }, pause: { _ in })
        do { _ = try await capture.read(); XCTFail("No selection should fail") } catch {}
        XCTAssertEqual(copies, 2)
    }

    func testSlowCopyBeyondOldSixHundredMillisecondLimitSucceedsAndRestores() async throws {
        var changes = 10
        var polls = 0
        var sends = 0
        var restores = 0
        let result = try await SelectionCopy.read(baseline: 10, changeCount: { changes }, text: { "Fresh selection" }, sendCopy: {
            sends += 1
        }, restore: { restores += 1 }, sourceIsCurrent: { true }, pause: { _ in
            polls += 1
            if polls == 22 { changes = 11 }
        })
        XCTAssertEqual(result, "Fresh selection")
        XCTAssertEqual(sends, 1)
        XCTAssertEqual(restores, 1)
        XCTAssertEqual(polls, 22)
    }

    func testClipboardWithoutFreshChangeIsNeverRead() async throws {
        var polls = 0
        let result = try await SelectionCopy.read(baseline: 10, changeCount: { 10 }, text: {
            XCTFail("Old clipboard text must never be used"); return "Unrelated clipboard"
        }, sendCopy: {}, restore: { XCTFail("An unchanged clipboard must not be rewritten") }, sourceIsCurrent: { true }, pause: { _ in polls += 1 })
        XCTAssertNil(result)
        XCTAssertEqual(polls, 40)
    }

    func testConcurrentClipboardChangeIsNotOverwrittenOrReturned() async {
        var changes = 10
        var restores = 0
        do {
            _ = try await SelectionCopy.read(baseline: 10, changeCount: { changes }, text: {
                changes = 12
                return "Superseded selection"
            }, sendCopy: {}, restore: { restores += 1 }, sourceIsCurrent: { true }, pause: { _ in changes = 11 })
            XCTFail("Concurrent change must abort")
        } catch {}
        XCTAssertEqual(restores, 0)
        XCTAssertEqual(changes, 12)
    }

    func testChangedClipboardSnapshotAbortsBeforeSendingCopy() async {
        do {
            _ = try await SelectionCopy.read(baseline: 10, changeCount: { 11 }, text: { nil }, sendCopy: {
                XCTFail("Clipboard changed while snapshotting; do not send Copy")
            }, restore: { XCTFail("Do not overwrite the newer clipboard") }, sourceIsCurrent: { true }, pause: { _ in })
            XCTFail("Expected changed snapshot failure")
        } catch {}
    }

    func testCancellationStopsBeforeAnyCopy() async {
        let capture = SelectionCapture(sourceIsCurrent: { true }, keysAreReleased: { false }, accessibilityText: { nil }, copiedText: {
            XCTFail("Cancellation must stop Copy"); return nil
        }, pause: { _ in throw CancellationError() })
        do { _ = try await capture.read(); XCTFail("Expected cancellation") }
        catch { XCTAssertTrue(error is CancellationError) }
    }
}
