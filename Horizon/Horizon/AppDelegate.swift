//
//  AppDelegate.swift
//  Horizon
//
//  Owns the menu-bar status item and its menu: trigger a break on demand, toggle
//  launch-at-login, and quit. The automatic 20-minute schedule runs via BreakScheduler.
//

import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    /// Held for the app's whole lifetime — if released, the menu-bar icon vanishes.
    private var statusItem: NSStatusItem?

    /// Shows and hides the full-screen break overlay.
    private let overlayController = OverlayController()

    /// Drives automatic breaks on the 20-minute schedule.
    private var scheduler: BreakScheduler?

    /// Kept so its checkmark can be refreshed when the menu opens.
    private var launchAtLoginItem: NSMenuItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        // A template image automatically adapts to light/dark menu bars.
        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Horizon")
            image?.isTemplate = true
            button.image = image
        }

        let menu = makeMenu()
        menu.delegate = self          // so menuWillOpen can refresh dynamic items
        statusItem.menu = menu
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

        let launchItem = NSMenuItem(
            title: "Launch at Login",
            action: #selector(toggleLaunchAtLogin),
            keyEquivalent: ""
        )
        launchItem.target = self
        menu.addItem(launchItem)
        self.launchAtLoginItem = launchItem

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

    // MARK: - NSMenuDelegate

    /// Refresh dynamic menu items just before the menu appears. The user can
    /// change the login item in System Settings, so we read the real status here
    /// rather than trusting a cached value.
    func menuWillOpen(_ menu: NSMenu) {
        launchAtLoginItem?.state = (SMAppService.mainApp.status == .enabled) ? .on : .off
    }

    // MARK: - Actions

    @objc private func takeBreakNow() {
        scheduler?.triggerBreakNow()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            NSLog("Horizon: failed to toggle launch-at-login: \(error.localizedDescription)")
        }
    }
}
