// Renders the app icon to a 1024x1024 PNG: swift scripts/make-icon.swift out.png
import AppKit

let size: CGFloat = 1024
let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon.png"

let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(size), pixelsHigh: Int(size),
                           bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                           colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
let ctx = NSGraphicsContext.current!.cgContext
// Work in top-left coordinates.
ctx.translateBy(x: 0, y: size)
ctx.scaleBy(x: 1, y: -1)

let srgb = CGColorSpace(name: CGColorSpace.sRGB)!
func rgb(_ hex: UInt32, _ a: CGFloat = 1) -> CGColor {
    CGColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255, alpha: a)
}
func gradient(_ colors: [UInt32], _ stops: [CGFloat]) -> CGGradient {
    CGGradient(colorsSpace: srgb, colors: colors.map { rgb($0) } as CFArray, locations: stops)!
}
func rounded(_ r: CGRect, _ radius: CGFloat) -> CGPath {
    CGPath(roundedRect: r, cornerWidth: radius, cornerHeight: radius, transform: nil)
}
func polygon(_ pts: [(CGFloat, CGFloat)]) -> CGPath {
    let p = CGMutablePath()
    p.addLines(between: pts.map { CGPoint(x: $0.0, y: $0.1) })
    p.closeSubpath()
    return p
}
// Fill a shape with rounded corners by stroking it in the same paint.
func softFill(_ path: CGPath, _ color: CGColor, round: CGFloat) {
    ctx.addPath(path)
    ctx.setFillColor(color)
    ctx.fillPath()
    ctx.addPath(path)
    ctx.setStrokeColor(color)
    ctx.setLineWidth(round)
    ctx.setLineJoin(.round)
    ctx.strokePath()
}

// Apple's icon grid puts an 824px tile inside the 1024px canvas.
let tile = CGRect(x: 100, y: 100, width: 824, height: 824)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 18), blur: 36, color: rgb(0x000000, 0.35))
ctx.addPath(rounded(tile, 185))
ctx.setFillColor(rgb(0x000000))
ctx.fillPath()
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(rounded(tile, 185))
ctx.clip()
ctx.drawLinearGradient(gradient([0xFF9F2E, 0xE8356D, 0x8E2BC9, 0x4B1A9E, 0x1D0B44], [0, 0.28, 0.55, 0.78, 1]),
                       start: CGPoint(x: 150, y: 110), end: CGPoint(x: 900, y: 930), options: [])
ctx.drawRadialGradient(CGGradient(colorsSpace: srgb, colors: [rgb(0xFFFFFF, 0.22), rgb(0xFFFFFF, 0)] as CFArray,
                                  locations: [0, 1])!,
                       startCenter: CGPoint(x: 280, y: 240), startRadius: 0,
                       endCenter: CGPoint(x: 280, y: 240), endRadius: 480, options: [])
ctx.restoreGState()

// Fox head: ears on top, cheeks tapering to a chin.
let head = polygon([(170, 590), (228, 392), (268, 190), (430, 340), (594, 340),
                    (756, 190), (796, 392), (854, 590), (512, 842)])
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 16), blur: 34, color: rgb(0x1A0638, 0.55))
softFill(head, rgb(0xFF7A2E), round: 48)
ctx.restoreGState()

ctx.saveGState()
ctx.addPath(head.union(head.copy(strokingWithWidth: 48, lineCap: .round, lineJoin: .round, miterLimit: 10)))
ctx.clip()
ctx.drawLinearGradient(gradient([0xFFC53A, 0xFF7A2E, 0xF0404F], [0, 0.5, 1]),
                       start: CGPoint(x: 512, y: 170), end: CGPoint(x: 512, y: 860), options: [])
ctx.restoreGState()

// Inner ears.
softFill(polygon([(274, 252), (258, 372), (384, 336)]), rgb(0x3B0E62), round: 18)
softFill(polygon([(750, 252), (766, 372), (640, 336)]), rgb(0x3B0E62), round: 18)

// White cheeks and a dark nose.
softFill(polygon([(176, 596), (512, 836), (372, 662)]), rgb(0xFFF4EA), round: 36)
softFill(polygon([(848, 596), (512, 836), (652, 662)]), rgb(0xFFF4EA), round: 36)
ctx.addEllipse(in: CGRect(x: 478, y: 752, width: 68, height: 46))
ctx.setFillColor(rgb(0x230A40))
ctx.fillPath()

// The video player sits where the fox's eyes would be.
let player = CGRect(x: 292, y: 410, width: 440, height: 290)
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: 10), blur: 24, color: rgb(0x1A0638, 0.5))
ctx.addPath(rounded(player, 46))
ctx.setFillColor(rgb(0x1C0A3A))
ctx.fillPath()
ctx.restoreGState()
ctx.addPath(rounded(player.insetBy(dx: 6, dy: 6), 40))
ctx.setStrokeColor(rgb(0xFFFFFF, 0.9))
ctx.setLineWidth(12)
ctx.strokePath()

// Progress bar along the bottom of the player.
let barY: CGFloat = 660
ctx.setLineCap(.round)
ctx.setLineWidth(12)
ctx.setStrokeColor(rgb(0xFFFFFF, 0.3))
ctx.move(to: CGPoint(x: 340, y: barY)); ctx.addLine(to: CGPoint(x: 684, y: barY)); ctx.strokePath()
ctx.setStrokeColor(rgb(0xFF8A30))
ctx.move(to: CGPoint(x: 340, y: barY)); ctx.addLine(to: CGPoint(x: 470, y: barY)); ctx.strokePath()
ctx.addEllipse(in: CGRect(x: 458, y: barY - 12, width: 24, height: 24))
ctx.setFillColor(rgb(0xFFFFFF))
ctx.fillPath()

// Padlock in the middle of the player: the arc on top, then the body.
let lockX: CGFloat = 512, bodyTop: CGFloat = 540
ctx.setLineCap(.butt)
ctx.setLineWidth(24)
ctx.setStrokeColor(rgb(0xFFFFFF))
ctx.addArc(center: CGPoint(x: lockX, y: bodyTop), radius: 42, startAngle: .pi, endAngle: 0, clockwise: false)
ctx.strokePath()
ctx.addPath(rounded(CGRect(x: lockX - 66, y: bodyTop - 4, width: 132, height: 96), 20))
ctx.setFillColor(rgb(0xFFFFFF))
ctx.fillPath()
ctx.addEllipse(in: CGRect(x: lockX - 12, y: bodyTop + 22, width: 24, height: 24))
ctx.addRect(CGRect(x: lockX - 5, y: bodyTop + 36, width: 10, height: 28))
ctx.setFillColor(rgb(0x1C0A3A))
ctx.fillPath()

NSGraphicsContext.current = nil
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
