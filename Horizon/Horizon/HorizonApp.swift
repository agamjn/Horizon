//
//  HorizonApp.swift
//  Horizon
//
//  The app's entry point. Horizon is a menu-bar–only utility: no Dock icon and
//  no window (that's set by LSUIElement = YES in the build settings). All of the
//  real setup happens in AppDelegate.
//
//  SwiftUI's `App` requires at least one Scene, so we declare an empty `Settings`
//  scene. It never shows a window on its own — it only satisfies that requirement
//  and gives us a place to add a preferences window later if we ever want one.
//

import SwiftUI

@main
struct HorizonApp: App {
    // Bridges SwiftUI's lifecycle to a classic AppKit delegate, where we create
    // and own the menu-bar item.
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
