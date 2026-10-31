import AppKit

/// A visible receipt indicator, independent of event success and of system Dock
/// bounce preferences. Never activates MyEvent or changes the selected source app.
@MainActor
enum DockFeedback {
    private static var timer: Timer?
    private static var view: ActivityIconView?
    private static var startedAt = Date.distantPast
    private static var generation = UUID()
    static func begin() {
        timer?.invalidate()
        generation = UUID()
        startedAt = Date()
        let tile = NSApp.dockTile
        let icon = ActivityIconView(frame: NSRect(origin: .zero, size: tile.size))
        view = icon
        tile.contentView = icon
        tile.display()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 24, repeats: true) { _ in
            Task { @MainActor in
                view?.phase = Date().timeIntervalSince(startedAt)
                view?.needsDisplay = true
                NSApp.dockTile.display()
            }
        }
    }
    static func finish() {
        let current = generation
        let delay = max(0, 1.2 - Date().timeIntervalSince(startedAt))
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            guard generation == current else { return }
            timer?.invalidate()
            timer = nil
            view = nil
            NSApp.dockTile.contentView = nil
            NSApp.dockTile.display()
        }
    }
}

@MainActor
private final class ActivityIconView: NSView {
    var phase: TimeInterval = 0
    private let icon = Bundle.main.url(forResource: "AppIcon", withExtension: "icns").flatMap(NSImage.init(contentsOf:))
    override func draw(_ dirtyRect: NSRect) {
        NSGraphicsContext.current?.cgContext.clear(bounds)
        let side = min(bounds.width, bounds.height)
        let pulse = CGFloat((sin(phase * 2 * .pi * 1.5) + 1) / 2)
        let size = side * (0.79 + 0.10 * pulse)
        icon?.draw(in: NSRect(x: bounds.midX - size/2, y: bounds.midY - size/2, width: size, height: size))
        let ring = NSBezierPath(ovalIn: bounds.insetBy(dx: side * 0.035, dy: side * 0.035))
        ring.lineWidth = side * 0.035
        NSColor.systemBlue.withAlphaComponent(0.45 + 0.5 * pulse).setStroke()
        ring.stroke()
    }
}
