//
//  AppDelegate.swift
//  Horizon
//
//  Owns the menu-bar status item and its menu: shows time until the next break,
//  triggers a break on demand, pauses for an hour, lets you adjust how often
//  breaks fire and how long they last, toggles launch-at-login, and quits. The
//  automatic schedule runs via BreakScheduler.
//

import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {

    /// Held for the app's whole lifetime — if released, the menu-bar icon vanishes.
    private var statusItem: NSStatusItem?

    /// Shows and hides the full-screen break overlay.
    private let overlayController = OverlayController()

    /// Drives automatic breaks on the schedule.
    private var scheduler: BreakScheduler?

    // Preset choices offered in the submenus.
    private let intervalPresetsMinutes = [15, 20, 25, 30, 45, 60]
    private let durationPresetsSeconds = [20, 30, 45, 60]

    // Dynamic menu items, refreshed in `menuWillOpen`.
    private var nextBreakItem: NSMenuItem?
    private var pauseItem: NSMenuItem?
    private var intervalItem: NSMenuItem?
    private var durationItem: NSMenuItem?
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

        // Start the automatic break schedule (uses the saved interval).
        let scheduler = BreakScheduler(overlay: overlayController)
        scheduler.start()
        self.scheduler = scheduler
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()

        // Status line (no action → automatically shown disabled/greyed).
        let nextBreak = NSMenuItem(title: "Next break in —", action: nil, keyEquivalent: "")
        menu.addItem(nextBreak)
        self.nextBreakItem = nextBreak

        menu.addItem(.separator())

        let breakItem = NSMenuItem(title: "Take a Break Now",
                                   action: #selector(takeBreakNow), keyEquivalent: "")
        breakItem.target = self
        menu.addItem(breakItem)

        let pause = NSMenuItem(title: "Pause for 1 Hour",
                               action: #selector(togglePause), keyEquivalent: "")
        pause.target = self
        menu.addItem(pause)
        self.pauseItem = pause

        menu.addItem(.separator())

        // "Break Every" submenu — how often a break fires.
        let interval = NSMenuItem(title: "Break Every", action: nil, keyEquivalent: "")
        interval.submenu = makeIntervalSubmenu()
        menu.addItem(interval)
        self.intervalItem = interval

        // "Break Length" submenu — how long each break lasts.
        let duration = NSMenuItem(title: "Break Length", action: nil, keyEquivalent: "")
        duration.submenu = makeDurationSubmenu()
        menu.addItem(duration)
        self.durationItem = duration

        menu.addItem(.separator())

        let launchItem = NSMenuItem(title: "Launch at Login",
                                    action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchItem.target = self
        menu.addItem(launchItem)
        self.launchAtLoginItem = launchItem

        menu.addItem(.separator())

        // `terminate(_:)` has no explicit target, so it travels up the responder
        // chain to NSApplication, which handles quitting.
        menu.addItem(withTitle: "Quit Horizon",
                     action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        return menu
    }

    private func makeIntervalSubmenu() -> NSMenu {
        let submenu = NSMenu()
        for minutes in intervalPresetsMinutes {
            let item = NSMenuItem(title: "\(minutes) min",
                                  action: #selector(selectInterval(_:)), keyEquivalent: "")
            item.target = self
            item.tag = minutes
            submenu.addItem(item)
        }
        return submenu
    }

    private func makeDurationSubmenu() -> NSMenu {
        let submenu = NSMenu()
        for seconds in durationPresetsSeconds {
            let item = NSMenuItem(title: "\(seconds) sec",
                                  action: #selector(selectDuration(_:)), keyEquivalent: "")
            item.target = self
            item.tag = seconds
            submenu.addItem(item)
        }
        return submenu
    }

    // MARK: - NSMenuDelegate

    /// Refresh dynamic menu items just before the menu appears.
    func menuWillOpen(_ menu: NSMenu) {
        launchAtLoginItem?.state = (SMAppService.mainApp.status == .enabled) ? .on : .off

        // Current settings → titles + checkmarks.
        let currentMinutes = Int((BreakSettings.intervalSeconds / 60).rounded())
        intervalItem?.title = "Break Every: \(currentMinutes) min"
        intervalItem?.submenu?.items.forEach { $0.state = ($0.tag == currentMinutes) ? .on : .off }

        let currentDuration = BreakSettings.durationSeconds
        durationItem?.title = "Break Length: \(currentDuration) sec"
        durationItem?.submenu?.items.forEach { $0.state = ($0.tag == currentDuration) ? .on : .off }

        guard let scheduler else { return }
        if scheduler.isPaused {
            nextBreakItem?.title = "Paused"
            pauseItem?.title = "Resume"
        } else {
            nextBreakItem?.title = "Next break in \(formatted(scheduler.timeUntilNextBreak))"
            pauseItem?.title = "Pause for 1 Hour"
        }
    }

    // MARK: - Actions

    @objc private func takeBreakNow() {
        scheduler?.triggerBreakNow()
    }

    @objc private func togglePause() {
        guard let scheduler else { return }
        if scheduler.isPaused {
            scheduler.resume()
        } else {
            scheduler.pauseForOneHour()
        }
    }

    @objc private func selectInterval(_ sender: NSMenuItem) {
        let seconds = TimeInterval(sender.tag * 60)
        BreakSettings.intervalSeconds = seconds
        scheduler?.setInterval(seconds)
    }

    @objc private func selectDuration(_ sender: NSMenuItem) {
        BreakSettings.durationSeconds = sender.tag   // applied on the next break
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

    // MARK: - Helpers

    /// Formats seconds as "M:SS" for the countdown line.
    private func formatted(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
