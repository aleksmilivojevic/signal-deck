import AppKit
import Foundation

struct Palette {
    static let backgroundTop = NSColor(calibratedRed: 0.95, green: 0.97, blue: 0.96, alpha: 1.0)
    static let backgroundBottom = NSColor(calibratedRed: 0.86, green: 0.90, blue: 0.88, alpha: 1.0)
    static let globeFill = NSColor(calibratedRed: 0.995, green: 0.989, blue: 0.972, alpha: 1.0)
    static let globeStroke = NSColor(calibratedRed: 0.07, green: 0.47, blue: 0.42, alpha: 0.92)
    static let gridStroke = NSColor(calibratedRed: 0.05, green: 0.52, blue: 0.47, alpha: 0.98)
    static let axisStroke = NSColor(calibratedRed: 0.17, green: 0.21, blue: 0.24, alpha: 0.18)
    static let glow = NSColor(calibratedRed: 0.32, green: 0.64, blue: 0.58, alpha: 0.12)
    static let shadow = NSColor(calibratedRed: 0.08, green: 0.15, blue: 0.13, alpha: 0.12)
}

func oval(center: CGPoint, rx: CGFloat, ry: CGFloat) -> NSBezierPath {
    NSBezierPath(ovalIn: NSRect(x: center.x - rx, y: center.y - ry, width: rx * 2, height: ry * 2))
}

func stroke(_ path: NSBezierPath, color: NSColor, width: CGFloat) {
    color.setStroke()
    path.lineWidth = width
    path.stroke()
}

func fill(_ path: NSBezierPath, color: NSColor) {
    color.setFill()
    path.fill()
}

func pngData(size: Int) -> Data? {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: size,
        pixelsHigh: size,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )

    guard let rep else { return nil }
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.saveGraphicsState()
    guard let context = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
    NSGraphicsContext.current = context
    context.imageInterpolation = .high

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let gradient = NSGradient(colors: [Palette.backgroundTop, Palette.backgroundBottom])
    gradient?.draw(in: rect, angle: -90)

    let glowCenter = CGPoint(x: CGFloat(size) * 0.5, y: CGFloat(size) * 0.53)
    let glowRadius = CGFloat(size) * 0.34
    let glow = oval(center: glowCenter, rx: glowRadius, ry: glowRadius)
    fill(glow, color: Palette.glow)

    let center = CGPoint(x: CGFloat(size) * 0.5, y: CGFloat(size) * 0.53)
    let radius = CGFloat(size) * 0.285

    let shadow = oval(center: CGPoint(x: center.x, y: center.y - CGFloat(size) * 0.012), rx: radius * 1.01, ry: radius * 1.01)
    fill(shadow, color: Palette.shadow)

    let ring = oval(center: center, rx: radius, ry: radius)
    fill(ring, color: Palette.globeFill)
    stroke(ring, color: Palette.globeStroke, width: max(2.0, CGFloat(size) * 0.011))

    let latitudes: [CGFloat] = [0.3333333333, 0.6363636364, 0.8484848485]
    for ratio in latitudes {
        let p = oval(center: center, rx: radius, ry: radius * ratio)
        stroke(p, color: Palette.gridStroke, width: max(1.6, CGFloat(size) * 0.0076))
    }

    let longitudes: [CGFloat] = [0.3333333333, 0.6363636364, 0.8484848485]
    for ratio in longitudes {
        let p = oval(center: center, rx: radius * ratio, ry: radius)
        stroke(p, color: Palette.gridStroke, width: max(1.6, CGFloat(size) * 0.0076))
    }

    let axisWidth = max(1.0, CGFloat(size) * 0.005)

    let equator = NSBezierPath()
    equator.move(to: CGPoint(x: center.x - radius, y: center.y))
    equator.line(to: CGPoint(x: center.x + radius, y: center.y))
    stroke(equator, color: Palette.axisStroke, width: axisWidth)

    let meridian = NSBezierPath()
    meridian.move(to: CGPoint(x: center.x, y: center.y - radius))
    meridian.line(to: CGPoint(x: center.x, y: center.y + radius))
    stroke(meridian, color: Palette.axisStroke, width: axisWidth)

    let lower = NSBezierPath()
    lower.move(to: CGPoint(x: center.x - radius * 0.7272727273, y: center.y - radius * 0.9696969697))
    lower.line(to: CGPoint(x: center.x + radius * 0.7272727273, y: center.y - radius * 0.9696969697))
    stroke(lower, color: Palette.axisStroke, width: axisWidth)

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])
}

let repositoryRoot = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
let root = repositoryRoot
    .appendingPathComponent("SignalDeck", isDirectory: true)
    .appendingPathComponent("Assets.xcassets", isDirectory: true)
    .appendingPathComponent("AppIcon.appiconset", isDirectory: true)
let outputs: [(String, Int)] = [
    ("Icon-20@2x.png", 40),
    ("Icon-20@3x.png", 60),
    ("Icon-29@2x.png", 58),
    ("Icon-29@3x.png", 87),
    ("Icon-40@2x.png", 80),
    ("Icon-40@3x.png", 120),
    ("Icon-60@2x.png", 120),
    ("Icon-60@3x.png", 180),
    ("Icon-1024.png", 1024),
]

for (name, size) in outputs {
    guard let data = pngData(size: size) else {
        fputs("Failed to render \(name)\n", stderr)
        exit(1)
    }
    try data.write(to: root.appendingPathComponent(name))
}

print("Generated \(outputs.count) icon files.")
