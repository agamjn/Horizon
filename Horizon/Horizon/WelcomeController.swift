//
//  WelcomeController.swift
//  Horizon
//
//  Manages the first-launch welcome window. AppDelegate shows it once (gated by
//  BreakSettings.hasSeenWelcome) and again on demand from the panel's "About".
//  The window hosts the SwiftUI WelcomeView; "Open Horizon" closes it and asks
//  AppDelegate to pop open the menu-bar panel.
//

import AppKit
import SwiftUI

@MainActor
final class WelcomeController: NSObject, NSWindowDelegate {

    private var window: NSWindow?

    /// Set by AppDelegate — invoked when the user taps "Open Horizon".
    var onOpenHorizon: (() -> Void)?

    func show() {
        if window == nil {
            let view = WelcomeView(
                onOpenHorizon: { [weak self] in
                    self?.window?.close()
                    self?.onOpenHorizon?()
                },
                onDismiss: { [weak self] in self?.window?.close() }
            )

            let win = NSWindow(contentViewController: NSHostingController(rootView: view))
            win.styleMask = [.titled, .closable, .fullSizeContentView]
            win.titleVisibility = .hidden
            win.titlebarAppearsTransparent = true
            win.isMovableByWindowBackground = true
            win.backgroundColor = NSColor(white: 0.97, alpha: 1)
            win.isReleasedWhenClosed = false
            win.standardWindowButton(.miniaturizeButton)?.isHidden = true
            win.standardWindowButton(.zoomButton)?.isHidden = true
            win.delegate = self
            window = win
        }

        guard let window else { return }
        window.center()
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
}
