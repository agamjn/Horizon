//
//  AppDelegate.swift
//  Horizon
//
//  Owns the menu-bar status item. Clicking it toggles a custom popover panel
//  (MenuPanelView) instead of a plain NSMenu — that's what lets us fully style the
//  dropdown (the ring, buttons, steppers). The popover is backed by MenuPanelModel,
//  which drives the same BreakScheduler/BreakSettings/SMAppService engine.
//

import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {

    /// Held for the app's whole lifetime — if released, the menu-bar icon vanishes.
    private var statusItem: NSStatusItem?

    /// Shows and hides the full-screen break overlay.
    private let overlayController = OverlayController()

    /// Drives automatic breaks on the schedule.
    private var scheduler: BreakScheduler?

    /// The custom dropdown panel and its backing model.
    private var popover: NSPopover?
    private var panelModel: MenuPanelModel?

    /// First-launch welcome window (also re-openable from the panel's "About").
    private let welcomeController = WelcomeController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = MenuBarIcon.image()      // Horizon logo (template — adapts to light/dark)
            button.action = #selector(togglePopover(_:))
            button.target = self
        }
        self.statusItem = statusItem

        // Start the automatic break schedule (uses the saved interval).
        let scheduler = BreakScheduler(overlay: overlayController)
        scheduler.start()
        self.scheduler = scheduler

        // Build the custom panel (replaces the old NSMenu).
        let model = MenuPanelModel(scheduler: scheduler)
        self.panelModel = model

        let popover = NSPopover()
        popover.behavior = .transient                       // closes when you click away
        popover.appearance = NSAppearance(named: .aqua)     // keep the light design in dark mode
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: MenuPanelView(model: model))
        self.popover = popover

        model.onClose = { [weak popover] in popover?.performClose(nil) }
        model.onShowWelcome = { [weak self] in self?.showWelcome() }
        welcomeController.onOpenHorizon = { [weak self] in self?.openPanel() }

        // First launch: introduce the app and point the user to the menu-bar icon.
        if !BreakSettings.hasSeenWelcome {
            BreakSettings.hasSeenWelcome = true
            welcomeController.show()
        }
    }

    @objc private func togglePopover(_ sender: NSStatusBarButton) {
        guard let popover else { return }
        if popover.isShown {
            popover.performClose(sender)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }

    /// Open the panel programmatically (used by the welcome's "Open Horizon" button).
    /// Dispatched async so it runs after the welcome window has finished closing.
    func openPanel() {
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  let popover = self.popover,
                  let button = self.statusItem?.button,
                  !popover.isShown else { return }
            NSApp.activate(ignoringOtherApps: true)
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    /// (Re)show the welcome window (used by the panel's "About").
    func showWelcome() {
        welcomeController.show()
    }

    // MARK: - NSPopoverDelegate

    /// Tick the ring/countdown only while the panel is visible.
    func popoverDidShow(_ notification: Notification) {
        panelModel?.startTicking()
    }

    func popoverDidClose(_ notification: Notification) {
        panelModel?.stopTicking()
    }
}
