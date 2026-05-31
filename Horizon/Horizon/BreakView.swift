//
//  BreakView.swift
//  Horizon
//
//  The contents of the break overlay: a calm background, the reminder message,
//  a live countdown, and a deliberately faint × button (shown only on the primary
//  screen). The nature video will replace the gradient background in a later step.
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
            // Calm background (a nature video will replace this later).
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.15, blue: 0.20),
                         Color(red: 0.02, green: 0.05, blue: 0.09)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {
                Image(systemName: "eyes")
                    .font(.system(size: 60, weight: .ultraLight))
                    .foregroundStyle(.white.opacity(0.85))

                Text("Look ~20 feet away")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Rest your eyes — focus on something in the distance.")
                    .font(.system(size: 19))
                    .foregroundStyle(.white.opacity(0.7))

                Text(timeString(remaining))
                    .font(.system(size: 70, weight: .thin, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white.opacity(0.9))
                    .padding(.top, 6)
            }
            .padding()

            // Faint close button, top-trailing, primary screen only.
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
