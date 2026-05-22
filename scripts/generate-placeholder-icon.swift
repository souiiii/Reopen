import AppKit
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: generate-placeholder-icon.swift <output.png> <size>\n", stderr)
    exit(64)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])

guard let size = Double(CommandLine.arguments[2]), size > 0 else {
    fputs("Icon size must be a positive number.\n", stderr)
    exit(64)
}

let imageSize = NSSize(width: size, height: size)
let image = NSImage(size: imageSize)

image.lockFocus()

let bounds = NSRect(origin: .zero, size: imageSize)
let cornerRadius = size * 0.22
let backgroundPath = NSBezierPath(roundedRect: bounds, xRadius: cornerRadius, yRadius: cornerRadius)

NSColor(calibratedRed: 0.08, green: 0.10, blue: 0.13, alpha: 1.0).setFill()
backgroundPath.fill()

let inset = size * 0.12
let innerRect = bounds.insetBy(dx: inset, dy: inset)
let ringPath = NSBezierPath(roundedRect: innerRect, xRadius: cornerRadius * 0.72, yRadius: cornerRadius * 0.72)
NSColor(calibratedRed: 0.25, green: 0.58, blue: 0.96, alpha: 1.0).setStroke()
ringPath.lineWidth = max(2, size * 0.045)
ringPath.stroke()

let attributes: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: size * 0.54, weight: .semibold),
    .foregroundColor: NSColor.white
]

let letter = "R" as NSString
let letterSize = letter.size(withAttributes: attributes)
let letterOrigin = NSPoint(
    x: (size - letterSize.width) / 2,
    y: (size - letterSize.height) / 2 + size * 0.015
)
letter.draw(at: letterOrigin, withAttributes: attributes)

image.unlockFocus()

guard
    let tiffData = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiffData),
    let pngData = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Failed to render icon PNG.\n", stderr)
    exit(1)
}

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try pngData.write(to: outputURL)
