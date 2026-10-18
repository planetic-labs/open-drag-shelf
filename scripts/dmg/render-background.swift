import AppKit

// Finder uses points for its window and icon positions. Include 1x and 2x reps.
let width: CGFloat = 720
let height: CGFloat = 460
let image = NSImage(size: NSSize(width: width, height: height))
for scale in [1, 2] {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(width) * scale,
                              pixelsHigh: Int(height) * scale, bitsPerSample: 8,
                              samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                              colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = image.size
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSGradient(colors: [NSColor(srgbRed: 0.99, green: 0.98, blue: 1, alpha: 1),
                        NSColor(srgbRed: 0.93, green: 0.91, blue: 0.99, alpha: 1)])!
        .draw(in: NSRect(x: 0, y: 0, width: width, height: height), angle: -90)

    func centered(_ text: String, top: CGFloat, size: CGFloat, weight: NSFont.Weight, color: NSColor) {
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        (text as NSString).draw(in: NSRect(x: 25, y: height - top - size * 1.5, width: width - 50, height: size * 1.6),
            withAttributes: [.font: NSFont.systemFont(ofSize: size, weight: weight),
                             .foregroundColor: color, .paragraphStyle: style])
    }
    let ink = NSColor(srgbRed: 0.23, green: 0.18, blue: 0.36, alpha: 1)
    let muted = NSColor(srgbRed: 0.47, green: 0.42, blue: 0.58, alpha: 1)
    centered("Plupo", top: 35, size: 34, weight: .semibold, color: ink)
    centered("Drag. Drop. Keep moving.", top: 83, size: 15, weight: .regular, color: muted)

    // Soft landing areas behind the real, draggable Finder icons.
    for x: CGFloat in [180, 540] {
        let rect = NSRect(x: x - 88, y: height - 224 - 88, width: 176, height: 176)
        NSColor.white.withAlphaComponent(0.45).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 36, yRadius: 36).fill()
    }
    let arrow = NSBezierPath()
    arrow.lineWidth = 3.5
    arrow.lineCapStyle = .round
    arrow.lineJoinStyle = .round
    let y = height - 224
    arrow.move(to: NSPoint(x: 322, y: y))
    arrow.line(to: NSPoint(x: 398, y: y))
    arrow.move(to: NSPoint(x: 385, y: y + 13))
    arrow.line(to: NSPoint(x: 398, y: y))
    arrow.line(to: NSPoint(x: 385, y: y - 13))
    NSColor(srgbRed: 0.57, green: 0.43, blue: 0.81, alpha: 1).setStroke()
    arrow.stroke()
    centered("Drag Plupo into Applications", top: 341, size: 17, weight: .medium, color: ink)
    centered("macOS 15.7+  ·  Apple Silicon", top: 379, size: 12, weight: .regular, color: muted)
    centered("First launch blocked? See the instructions in the release notes.",
             top: 414, size: 11, weight: .regular, color: muted)
    NSGraphicsContext.restoreGraphicsState()
    image.addRepresentation(rep)
}
let output = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "scripts/dmg/background.tiff"
let data = NSBitmapImageRep.tiffRepresentation(of: image.representations as! [NSBitmapImageRep], using: .lzw, factor: 1)!
try data.write(to: URL(fileURLWithPath: output))
