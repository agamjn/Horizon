//
//  BreakOverlayWindow.swift
//  Horizon
//
//  The window used for the full-screen break overlay. Two things make it special:
//
//  1. Borderless windows normally can't become the "key" window, so they can't
//     receive keyboard input. We override `canBecomeKey`/`canBecomeMain` to allow
//     it — that's what lets us *absorb* keystrokes instead of letting them fall
//     through to the app underneath.
//
//  2. We intentionally make the break hard to dismiss: the Escape key and every
//     other key do nothing. Esc on a borderless window is delivered via
//     `cancel(_:)` / `cancelOperation(_:)`, and ordinary keys via `keyDown`, so we
//     override all three to swallow them. The only ways out are the × button and
//     the automatic 20-second timeout (handled by OverlayController).
//

import AppKit

final class BreakOverlayWindow: NSWindow {

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    // Esc routes here on a borderless window — do nothing so it can't close.
    override func cancelOperation(_ sender: Any?) { /* intentionally ignored */ }
    @objc func cancel(_ sender: Any?) { /* intentionally ignored */ }

    // Swallow every key press: nothing falls through, and no key dismisses the
    // break. Not calling `super` also avoids the system "beep" for unhandled keys.
    override func keyDown(with event: NSEvent) { /* intentionally ignored */ }
}
