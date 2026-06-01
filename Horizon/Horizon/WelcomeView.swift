//
//  WelcomeView.swift
//  Horizon
//
//  First-launch welcome: confirms Horizon is installed, points the user to the
//  (subtle) menu-bar icon, and explains — concisely — why the 20-20-20 rule is
//  worth it. Styled to match the Ring Hero panel: light theme, calm green accent.
//

import SwiftUI
import AppKit

struct WelcomeView: View {

    /// Closes the welcome and opens the menu-bar panel (so the user sees where it lives).
    var onOpenHorizon: () -> Void
    /// Just closes the welcome.
    var onDismiss: () -> Void

    // Palette shared with MenuPanelView.
    private let ink = Color(red: 24 / 255, green: 24 / 255, blue: 26 / 255)        // #18181a
    private let accent = Color(red: 47 / 255, green: 122 / 255, blue: 90 / 255)    // #2f7a5a
    private let muted = Color(red: 91 / 255, green: 91 / 255, blue: 97 / 255)      // #5b5b61

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 6) {
                Text("Horizon is ready")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(ink)
                Text("It lives in your menu bar, at the top-right of your screen.")
                    .font(.system(size: 13))
                    .foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            menuBarHint

            VStack(alignment: .leading, spacing: 8) {
                Text("Why It Matters")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(accent)
                Text("Up to 90% of all-day screen users get eye strain. That means tired, dry eyes and headaches.")
                    .font(.system(size: 13))
                    .foregroundStyle(ink.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
                Text("So every 20 minutes, Horizon rests your eyes for 20 seconds. Look about 20 feet away. It's the 20-20-20 rule eye doctors recommend.")
                    .font(.system(size: 13))
                    .foregroundStyle(ink.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 8) {
                Button(action: onOpenHorizon) {
                    Text("Open Horizon")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(accent, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                }
                .buttonStyle(.plain)

                Button(action: onDismiss) {
                    Text("Got it")
                        .font(.system(size: 13))
                        .foregroundStyle(muted)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(28)
        .frame(width: 420)
        .background(Color(white: 0.97))
        .environment(\.colorScheme, .light)   // keep the light design even in dark mode
    }

    /// A small strip mimicking the right end of the menu bar, with the Horizon icon
    /// highlighted and an arrow pointing up toward where it really is. Kept right-aligned
    /// on purpose — that's where the real icon sits.
    private var menuBarHint: some View {
        HStack(spacing: 12) {
            Spacer()
            Image(systemName: "wifi")
            Image(systemName: "battery.100")
            Image(nsImage: MenuBarIcon.image(pointSize: 16))
                .foregroundStyle(ink)
                .padding(5)
                .background(accent.opacity(0.18), in: RoundedRectangle(cornerRadius: 6))
                .overlay(alignment: .top) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(accent)
                        .offset(y: -16)
                }
        }
        .font(.system(size: 12))
        .foregroundStyle(muted.opacity(0.6))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.05), in: RoundedRectangle(cornerRadius: 10))
    }
}
