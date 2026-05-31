//
//  OverlayController.swift
//  Horizon
//
//  Shows and hides the full-screen break overlay. It puts one window on every
//  connected display, brings the app forward so the windows can capture input,
//  and removes everything after the break duration. A separate safety timer
//  guarantees the overlay always closes even if something goes wrong with the
//  on-screen countdown — so the user can never get trapped behind it.
//

import AppKit
import SwiftUI

@MainActor
final class OverlayController: NSObject {

    private let breakDuration = 20  // seconds

    private var windows: [BreakOverlayWindow] = []
    private var safetyTimer: Timer?
    private var isShowing = false

    /// Show the break overlay on all displays.
    func startBreak() {
        guard !isShowing else { return }
        isShowing = true

        // The screen the user is currently on gets the close button.
        let primaryScreen = NSScreen.main ?? NSScreen.screens.first

        for screen in NSScreen.screens {
            let window = makeWindow(for: screen, isPrimary: screen == primaryScreen)
            window.alphaValue = 0
            windows.append(window)
        }

        // Bring Horizon forward so the borderless windows can become key and
        // absorb keyboard input.
        NSApp.activate(ignoringOtherApps: true)
        for window in windows {
            window.makeKeyAndOrderFront(nil)
        }

        // Fade in.
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            for window in windows { window.animator().alphaValue = 1 }
        }

        // Independent backstop in case the on-screen countdown ever fails.
        // Target/selector (rather than a closure) keeps this main-actor-clean.
        safetyTimer = Timer.scheduledTimer(
            timeInterval: Double(breakDuration) + 0.5,
            target: self,
            selector: #selector(safetyTimerFired),
            userInfo: nil,
            repeats: false
        )
    }

    /// Dismiss the overlay and return focus to whatever the user was doing.
    func endBreak() {
        guard isShowing else { return }
        isShowing = false

        safetyTimer?.invalidate()
        safetyTimer = nil

        let closing = windows
        windows.removeAll()

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.3
            for window in closing { window.animator().alphaValue = 0 }
        }, completionHandler: {
            for window in closing { window.orderOut(nil) }
        })

        NSApp.deactivate()
    }

    @objc private func safetyTimerFired() {
        endBreak()
    }

    private func makeWindow(for screen: NSScreen, isPrimary: Bool) -> BreakOverlayWindow {
        let window = BreakOverlayWindow(
            contentRect: screen.frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.setFrame(screen.frame, display: true)
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.isReleasedWhenClosed = false

        let view = BreakView(totalSeconds: breakDuration, showsCloseButton: isPrimary) { [weak self] in
            self?.endBreak()
        }
        window.contentView = NSHostingView(rootView: view)
        return window
    }
}
