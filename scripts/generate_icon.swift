#!/usr/bin/env swift
// Generates a 1024x1024 PNG app icon: a coffee cup on a warm gradient
// rounded-square background. Run with: swift scripts/generate_icon.swift <output.png>

import AppKit

let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "AppIcon-1024.png"
let size: CGFloat = 1024

func tinted(_ image: NSImage, color: NSColor) -> NSImage {
    let result = NSImage(size: image.size)
    result.lockFocus()
    let rect = NSRect(origin: .zero, size: image.size)
    image.draw(in: rect, from: .zero, operation: .sourceOver, fraction: 1.0)
    color.set()
    rect.fill(using: .sourceAtop)
    result.unlockFocus()
    return result
}

let canvas = NSImage(size: NSSize(width: size, height: size))
canvas.lockFocus()

let fullRect = NSRect(x: 0, y: 0, width: size, height: size)
let bgPath = NSBezierPath(roundedRect: fullRect, xRadius: size * 0.225, yRadius: size * 0.225)
let gradient = NSGradient(
    starting: NSColor(calibratedRed: 0.85, green: 0.60, blue: 0.28, alpha: 1.0),
    ending: NSColor(calibratedRed: 0.36, green: 0.20, blue: 0.10, alpha: 1.0)
)
gradient?.draw(in: bgPath, angle: -90)

let config = NSImage.SymbolConfiguration(pointSize: size * 0.5, weight: .medium)
if let symbol = NSImage(systemSymbolName: "cup.and.saucer.fill", accessibilityDescription: nil)?
    .withSymbolConfiguration(config) {
    let white = tinted(symbol, color: .white)
    let symSize = white.size
    let origin = NSPoint(x: (size - symSize.width) / 2, y: (size - symSize.height) / 2 - size * 0.015)
    white.draw(at: origin, from: .zero, operation: .sourceOver, fraction: 0.97)
}

canvas.unlockFocus()

guard let tiff = canvas.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("Failed to render icon\n".data(using: .utf8)!)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: outputPath))
print("Wrote \(outputPath)")
