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

    func applicationDidFinishLaunching(_ notification: Notification) {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            let image = NSImage(systemSymbolName: "eye", accessibilityDescription: "Horizon")
            image?.isTemplate = true
            button.image = image
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

    // MARK: - NSPopoverDelegate

    /// Tick the ring/countdown only while the panel is visible.
    func popoverDidShow(_ notification: Notification) {
        panelModel?.startTicking()
    }

    func popoverDidClose(_ notification: Notification) {
        panelModel?.stopTicking()
    }
}
