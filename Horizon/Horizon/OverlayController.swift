//
//  OverlayController.swift
//  Horizon
//
//  Shows and hides the full-screen break overlay. It puts one window on every
//  connected display, brings the app forward so the windows can capture input,
//  locks down system navigation for the break, plays optional ambient audio, and
//  removes everything after the break duration. A separate safety timer guarantees
//  the overlay always closes even if something goes wrong with the on-screen
//  countdown — so the user can never get trapped behind it. If the display
//  arrangement changes mid-break, the window set is rebuilt to keep every screen
//  covered.
//

import AppKit
import SwiftUI

@MainActor
final class OverlayController: NSObject {

    private let breakDuration = 20  // seconds

    private var windows: [BreakOverlayWindow] = []
    private var safetyTimer: Timer?
    private var isShowing = false
    private var breakStartedAt: Date?
    private var currentClip: URL?
    private var videoMuted = false
    private let ambientPlayer = AmbientAudioPlayer()

    /// Called when a break finishes (via × or the timeout). The scheduler uses
    /// this to start counting toward the next break.
    var onBreakEnded: (() -> Void)?

    override init() {
        super.init()
        // Rebuild the overlay if a display is connected/disconnected mid-break.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    /// Show the break overlay on all displays.
    func startBreak() {
        guard !isShowing else { return }
        isShowing = true
        breakStartedAt = Date()

        // One random clip per break, played only on the primary screen.
        currentClip = BreakVideoLibrary.randomClip()

        // Optional ambient audio. When a track plays, the video is muted so the
        // soothing audio is consistent regardless of which clip is showing.
        if let track = BreakAudioLibrary.randomTrack() {
            ambientPlayer.start(url: track)
        }
        videoMuted = ambientPlayer.isPlaying

        // Bring Horizon forward so the borderless windows can become key and
        // absorb keyboard input.
        NSApp.activate(ignoringOtherApps: true)

        // Lock down system navigation for the duration of the break. This disables
        // Cmd-Tab and Mission Control — including the trackpad 3-/4-finger Spaces
        // swipe that window-level event blocking can't reach. `hideDock` is required
        // by the API alongside `disableProcessSwitching`. We deliberately leave Force
        // Quit (⌘⌥Esc) enabled as a safety hatch.
        NSApp.presentationOptions = [.hideDock, .disableProcessSwitching]

        buildWindows(remaining: breakDuration)

        // Independent backstop in case the on-screen countdown ever fails.
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
        breakStartedAt = nil

        ambientPlayer.stop()

        // Release the system lock immediately, so full control returns to the user
        // the instant the break ends (via the × button or the timeout).
        NSApp.presentationOptions = []

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
        onBreakEnded?()
    }

    /// (Re)build one overlay window per current display, covering them all. Used at
    /// the start of a break and again if the display arrangement changes mid-break.
    private func buildWindows(remaining: Int) {
        for window in windows { window.orderOut(nil) }
        windows.removeAll()

        // The screen the user is currently on gets the close button + the video.
        let primaryScreen = NSScreen.main ?? NSScreen.screens.first
        for screen in NSScreen.screens {
            let isPrimary = (screen == primaryScreen)
            let window = makeWindow(for: screen, isPrimary: isPrimary,
                                    videoURL: isPrimary ? currentClip : nil, seconds: remaining)
            window.alphaValue = 0
            windows.append(window)
            window.makeKeyAndOrderFront(nil)
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            for window in windows { window.animator().alphaValue = 1 }
        }
    }

    @objc private func screensChanged() {
        guard isShowing, let breakStartedAt else { return }
        // Keep the countdown honest across the rebuild; the safety timer (which is
        // not reset here) still ends the break at the original time.
        let elapsed = Int(Date().timeIntervalSince(breakStartedAt))
        let remaining = max(1, breakDuration - elapsed)
        buildWindows(remaining: remaining)
    }

    @objc private func safetyTimerFired() {
        endBreak()
    }

    private func makeWindow(for screen: NSScreen, isPrimary: Bool, videoURL: URL?, seconds: Int) -> BreakOverlayWindow {
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

        let view = BreakView(totalSeconds: seconds, showsCloseButton: isPrimary,
                             videoURL: videoURL, videoMuted: videoMuted) { [weak self] in
            self?.endBreak()
        }
        window.contentView = NSHostingView(rootView: view)
        return window
    }
}
