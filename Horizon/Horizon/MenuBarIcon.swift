//
//  MenuBarIcon.swift
//  Horizon
//
//  Horizon's menu-bar icon — the app logo (a sun rising over the horizon), drawn in
//  code as a *template* image so it stays crisp at every scale and automatically adapts
//  to light / dark menu bars and click/selection states, exactly like the system
//  symbols do.
//
//  The cream rounded square from the website favicon is intentionally dropped: a
//  menu-bar icon is a silhouette, not a sticker. We keep just the sun + horizon marks
//  and let macOS handle the colour. The geometry mirrors favicon.svg (a 24×24 artboard).
//

import AppKit

enum MenuBarIcon {

    /// A template `NSImage` of the Horizon logo, sized for the menu bar.
    static func image(pointSize: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: pointSize, height: pointSize),
                            flipped: true) { rect in
            // Artwork is authored in the favicon's 24×24 space where y grows downward —
            // hence the flipped context, so these coordinates map straight across.
            // These are the bounds of the visible marks (stroke caps included) so the
            // glyph sits centred with a little breathing room.
            let minX: CGFloat = 3.2, maxX: CGFloat = 20.8
            let minY: CGFloat = 10.0, maxY: CGFloat = 19.8
            let pad: CGFloat = 1.5

            let scale = min((rect.width  - 2 * pad) / (maxX - minX),
                            (rect.height - 2 * pad) / (maxY - minY))
            let ox = (rect.width  - (maxX - minX) * scale) / 2
            let oy = (rect.height - (maxY - minY) * scale) / 2

            // favicon (24×24, y-down) → image point.
            func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
                NSPoint(x: ox + (x - minX) * scale, y: oy + (y - minY) * scale)
            }

            let ink = NSColor.black            // template: hue is ignored, alpha is kept
            let lineWidth = 1.6 * scale

            // Sun — the upper half of a circle centred on the horizon line (y = 16).
            // We draw the whole circle but clip to the sky above the line, so the dome's
            // flat edge lands exactly on the horizon (and we avoid arc-direction guesswork).
            NSGraphicsContext.saveGraphicsState()
            let horizonY = p(12, 16).y
            NSBezierPath(rect: NSRect(x: 0, y: 0, width: rect.width, height: horizonY)).addClip()
            let centre = p(12, 16)
            let radius = 6 * scale
            ink.setFill()
            NSBezierPath(ovalIn: NSRect(x: centre.x - radius, y: centre.y - radius,
                                        width: 2 * radius, height: 2 * radius)).fill()
            NSGraphicsContext.restoreGraphicsState()

            // Horizon line.
            let horizon = NSBezierPath()
            horizon.move(to: p(4, 16))
            horizon.line(to: p(20, 16))
            horizon.lineWidth = lineWidth
            horizon.lineCapStyle = .round
            ink.setStroke()
            horizon.stroke()

            // Fainter "ground" line just below it (matches the favicon's 32% line).
            let ground = NSBezierPath()
            ground.move(to: p(7.5, 19))
            ground.line(to: p(16.5, 19))
            ground.lineWidth = lineWidth
            ground.lineCapStyle = .round
            ink.withAlphaComponent(0.32).setStroke()
            ground.stroke()

            return true
        }
        image.isTemplate = true                // macOS tints for light/dark + click states
        image.accessibilityDescription = "Horizon"
        return image
    }
}
