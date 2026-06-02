//
//  BreakView.swift
//  Horizon
//
//  The contents of the break overlay: a plain black screen (the whole point of the
//  break is to look *away* from the display, so there is deliberately nothing to
//  look at), the reminder message, a live countdown, and a deliberately faint ×
//  button (shown only on the primary screen).
//

import SwiftUI
import Combine

struct BreakView: View {

    /// How long the break lasts, in seconds.
    let totalSeconds: Int
    /// Only the primary screen shows the close button.
    let showsCloseButton: Bool
    /// Called when the user clicks × or the countdown reaches zero.
    let onClose: () -> Void

    @State private var remaining: Int

    init(totalSeconds: Int, showsCloseButton: Bool, onClose: @escaping () -> Void) {
        self.totalSeconds = totalSeconds
        self.showsCloseButton = showsCloseButton
        self.onClose = onClose
        _remaining = State(initialValue: totalSeconds)
    }

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            // Plain black — look away from the screen, not at it.
            Color.black.ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: "eyes")
                    .font(.system(size: 60, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.9))

                Text("Look ~20 feet away")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Rest your eyes by focusing on something far away.")
                    .font(.system(size: 19))
                    .foregroundStyle(.white.opacity(0.75))

                Text(timeString(remaining))
                    .font(.system(size: 70, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.top, 6)
            }
            .padding()

            if showsCloseButton {
                VStack {
                    HStack {
                        Spacer()
                        Button(action: onClose) {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .opacity(0.12)            // "almost inexistent"
                        .padding(.top, 16)
                        .padding(.trailing, 18)
                    }
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onReceive(tick) { _ in
            guard remaining > 0 else { return }
            remaining -= 1
            if remaining == 0 { onClose() }
        }
    }

    private func timeString(_ seconds: Int) -> String {
        String(format: "0:%02d", max(0, seconds))
    }
}
