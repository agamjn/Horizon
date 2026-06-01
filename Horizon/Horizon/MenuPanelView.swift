//
//  MenuPanelView.swift
//  Horizon
//
//  The custom menu-bar dropdown panel (shown in an NSPopover), matching the
//  "Ring Hero" design: a green progress ring counting toward the next break, a
//  prominent "Take a Break Now" button, pause, the interval/length steppers, a
//  launch-at-login toggle, and a quit footer. Light theme, calm green accent.
//

import SwiftUI

struct MenuPanelView: View {

    @ObservedObject var model: MenuPanelModel

    // Palette from the design.
    private let ink = Color(red: 24 / 255, green: 24 / 255, blue: 26 / 255)        // #18181a
    private let accent = Color(red: 47 / 255, green: 122 / 255, blue: 90 / 255)    // #2f7a5a
    private let muted = Color(red: 91 / 255, green: 91 / 255, blue: 97 / 255)      // #5b5b61

    var body: some View {
        VStack(spacing: 14) {
            ring
            Text("until you rest your eyes")
                .font(.system(size: 13))
                .foregroundStyle(muted)

            VStack(spacing: 8) {
                takeBreakButton
                pauseButton
            }

            settingsCard

            quitFooter
        }
        .padding(16)
        .frame(width: 300)
        .background(Color(white: 0.97))
        .environment(\.colorScheme, .light)   // keep the light design even in dark mode
    }

    // MARK: - Ring

    private var ring: some View {
        ZStack {
            Circle().stroke(Color.black.opacity(0.10), lineWidth: 7)
            Circle()
                .trim(from: 0, to: model.progress)
                .stroke(accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.4), value: model.progress)
            VStack(spacing: 2) {
                Text(timeString(model.remaining))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(ink)
                Text("MIN : SEC")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(muted.opacity(0.7))
            }
        }
        .frame(width: 128, height: 128)
        .padding(.top, 4)
    }

    // MARK: - Buttons

    private var takeBreakButton: some View {
        Button(action: model.takeBreakNow) {
            HStack(spacing: 6) {
                Image(systemName: "eye")
                Text("Take a Break Now").fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(ink, in: RoundedRectangle(cornerRadius: 10))
            .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }

    private var pauseButton: some View {
        Button(action: model.togglePause) {
            Text(model.isPaused ? "Resume" : "Pause for 1 Hour")
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(ink)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Settings

    private var settingsCard: some View {
        VStack(spacing: 0) {
            stepperRow(title: "Break every", value: "\(model.intervalMinutes) min",
                       onLess: { model.stepInterval(-1) }, onMore: { model.stepInterval(1) })
            Divider()
            stepperRow(title: "Break length", value: "\(model.durationSeconds) sec",
                       onLess: { model.stepDuration(-1) }, onMore: { model.stepDuration(1) })
            Divider()
            HStack {
                Text("Launch at login").foregroundStyle(ink)
                Spacer()
                Toggle("", isOn: Binding(get: { model.launchAtLogin },
                                         set: { model.setLaunchAtLogin($0) }))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(accent)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
        }
        .font(.system(size: 13))
        .background(Color.black.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }

    private func stepperRow(title: String, value: String,
                            onLess: @escaping () -> Void, onMore: @escaping () -> Void) -> some View {
        HStack(spacing: 8) {
            Text(title).foregroundStyle(ink)
            Spacer()
            Button(action: onLess) { Image(systemName: "chevron.left") }
                .buttonStyle(.plain).foregroundStyle(muted)
            Text(value).foregroundStyle(ink).frame(minWidth: 54)
            Button(action: onMore) { Image(systemName: "chevron.right") }
                .buttonStyle(.plain).foregroundStyle(muted)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    private var quitFooter: some View {
        HStack {
            Button(action: model.showAbout) {
                Text("About")
                    .font(.system(size: 12))
                    .foregroundStyle(muted)
            }
            .buttonStyle(.plain)

            Spacer()

            Button(action: model.quit) {
                Text("Quit Horizon  ⌘Q")
                    .font(.system(size: 12))
                    .foregroundStyle(muted)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 2)
    }

    private func timeString(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
