import AppKit

// Original vector artwork: a calendar page with a clock and a quick-add spark.
let root = URL(fileURLWithPath: CommandLine.arguments[1])
let folder = root.appendingPathComponent("AppIcon.iconset")
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
func rounded(_ rect: NSRect, _ radius: CGFloat, _ color: NSColor) {
    color.setFill()
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
}
func stroke(_ points: [NSPoint], color: NSColor, width: CGFloat) {
    let path = NSBezierPath()
    path.move(to: points[0])
    for point in points.dropFirst() { path.line(to: point) }
    path.lineWidth = width; path.lineCapStyle = .round; path.lineJoinStyle = .round
    color.setStroke(); path.stroke()
}
func draw(size: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let context = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = context
    context.cgContext.scaleBy(x: CGFloat(size) / 1024, y: CGFloat(size) / 1024)
    let blue = NSColor(calibratedRed: 0.20, green: 0.36, blue: 0.95, alpha: 1)
    let purple = NSColor(calibratedRed: 0.43, green: 0.25, blue: 0.91, alpha: 1)
    let base = NSBezierPath(roundedRect: NSRect(x: 56, y: 56, width: 912, height: 912), xRadius: 206, yRadius: 206)
    NSGradient(starting: blue, ending: purple)!.draw(in: base, angle: -50)
    let shadow = NSShadow(); shadow.shadowColor = NSColor.black.withAlphaComponent(0.20); shadow.shadowBlurRadius = 30; shadow.shadowOffset = NSSize(width: 0, height: -12)
    NSGraphicsContext.saveGraphicsState(); shadow.set()
    rounded(NSRect(x: 218, y: 212, width: 588, height: 598), 85, .white)
    NSGraphicsContext.restoreGraphicsState()
    rounded(NSRect(x: 218, y: 636, width: 588, height: 100), 0, NSColor(calibratedWhite: 0.93, alpha: 1))
    for x: CGFloat in [355, 669] {
        stroke([NSPoint(x: x, y: 766), NSPoint(x: x, y: 832)], color: NSColor.white.withAlphaComponent(0.85), width: 38)
    }
    let clock = NSBezierPath(ovalIn: NSRect(x: 313, y: 292, width: 326, height: 326))
    blue.setStroke(); clock.lineWidth = 27; clock.stroke()
    stroke([NSPoint(x: 476, y: 554), NSPoint(x: 476, y: 455), NSPoint(x: 548, y: 411)], color: blue, width: 28)
    // Small lower-right quick-add badge, legible at Dock sizes.
    NSColor(calibratedRed: 0.20, green: 0.74, blue: 0.88, alpha: 1).setFill()
    NSBezierPath(ovalIn: NSRect(x: 586, y: 175, width: 258, height: 258)).fill()
    stroke([NSPoint(x: 715, y: 244), NSPoint(x: 715, y: 364)], color: .white, width: 25)
    stroke([NSPoint(x: 655, y: 304), NSPoint(x: 775, y: 304)], color: .white, width: 25)
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let name = "icon_\(points)x\(points)\(scale == 2 ? "@2x" : "").png"
        try draw(size: points * scale).write(to: folder.appendingPathComponent(name))
    }
}
try draw(size: 1024).write(to: root.appendingPathComponent("MyEvent.png"))
