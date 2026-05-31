//
//  AppDelegate.swift
//  Horizon
//
//  Owns the menu-bar status item. For this first milestone it only shows an icon
//  and a "Quit" command — the 20-minute timer and the break overlay arrive in
//  Phase 1.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    /// Held for the app's whole lifetime — if this is released, the menu-bar
    /// icon disappears.
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // A template image automatically adapts to light/dark menu bars.
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Horizon")
            image?.isTemplate = true
            button.image = image
        }

        // Minimal menu for now: just Quit. `terminate(_:)` has no explicit target,
        // so it travels up the responder chain to NSApplication, which handles it.
        let menu = NSMenu()
        menu.addItem(
            withTitle: "Quit Horizon",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        statusItem.menu = menu

        self.statusItem = statusItem
    }
}
