import AppKit
import Foundation
let folder = URL(fileURLWithPath: CommandLine.arguments[1], isDirectory: true)
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
for (name, size) in [("icon_16x16.png",16),("icon_16x16@2x.png",32),("icon_32x32.png",32),("icon_32x32@2x.png",64),("icon_128x128.png",128),("icon_128x128@2x.png",256),("icon_256x256.png",256),("icon_256x256@2x.png",512),("icon_512x512.png",512),("icon_512x512@2x.png",1024)] {
    let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    let s = CGFloat(size)
    NSColor(calibratedRed: 0.075, green: 0.08, blue: 0.09, alpha: 1).setFill()
    NSBezierPath(roundedRect: NSRect(x: s*0.06, y: s*0.06, width: s*0.88, height: s*0.88), xRadius: s*0.20, yRadius: s*0.20).fill()
    NSColor(calibratedRed: 0.96, green: 0.77, blue: 0.39, alpha: 1).setFill()
    for i in 0..<24 {
        let angle = Double(i) / 24 * 2 * Double.pi
        let d = s * 0.035
        NSBezierPath(ovalIn: NSRect(x: s*0.5 + CGFloat(cos(angle))*s*0.28-d/2, y: s*0.5 + CGFloat(sin(angle))*s*0.28-d/2, width: d, height: d)).fill()
    }
    let glyph = ["11111","00100","00100","00100","00100","00100","00100"]
    for (row, line) in glyph.enumerated() { for (col, bit) in line.enumerated() where bit == "1" {
        let d = s*0.027
        NSBezierPath(ovalIn: NSRect(x: s*0.412 + CGFloat(col)*s*0.038, y: s*0.605-CGFloat(row)*s*0.038, width: d, height: d)).fill()
    } }
    NSGraphicsContext.restoreGraphicsState()
    try bitmap.representation(using: .png, properties: [:])!.write(to: folder.appendingPathComponent(name))
}
