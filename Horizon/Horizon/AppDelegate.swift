//
//  AppDelegate.swift
//  Horizon
//
//  Owns the menu-bar status item and its menu. For now the menu can trigger a
//  break on demand ("Take a Break Now") and quit. The automatic 20-minute timer
//  arrives in the next step.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    /// Held for the app's whole lifetime — if released, the menu-bar icon vanishes.
    private var statusItem: NSStatusItem?

    /// Shows and hides the full-screen break overlay.
    private let overlayController = OverlayController()

    /// Drives automatic breaks on the 20-minute schedule.
    private var scheduler: BreakScheduler?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // A template image automatically adapts to light/dark menu bars.
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Horizon")
            image?.isTemplate = true
            button.image = image
        }

        statusItem.menu = makeMenu()
        self.statusItem = statusItem

        // Start the automatic break schedule (a break every 20 minutes).
        let scheduler = BreakScheduler(overlay: overlayController)
        scheduler.start()
        self.scheduler = scheduler
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        let breakItem = NSMenuItem(
            title: "Take a Break Now",
            action: #selector(takeBreakNow),
            keyEquivalent: ""
        )
        breakItem.target = self
        menu.addItem(breakItem)

        menu.addItem(.separator())

        // `terminate(_:)` has no explicit target, so it travels up the responder
        // chain to NSApplication, which handles quitting.
        menu.addItem(
            withTitle: "Quit Horizon",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        return menu
    }

    @objc private func takeBreakNow() {
        scheduler?.triggerBreakNow()
    }
}
