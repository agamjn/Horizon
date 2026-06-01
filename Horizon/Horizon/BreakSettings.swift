//
//  BreakSettings.swift
//  Horizon
//
//  User-adjustable break settings, persisted in UserDefaults. Defaults to the
//  classic 20-20 rule: a break every 20 minutes, lasting 20 seconds. (The third
//  "20" — looking 20 feet away — is the real-world instruction, not an app setting.)
//

import Foundation

enum BreakSettings {

    private static let intervalKey = "breakIntervalSeconds"
    private static let durationKey = "breakDurationSeconds"
    private static let hasSeenWelcomeKey = "hasSeenWelcome"

    static let defaultIntervalSeconds: TimeInterval = 20 * 60   // 20 minutes
    static let defaultDurationSeconds = 20                      // 20 seconds

    /// Seconds between breaks. Falls back to the default when unset.
    static var intervalSeconds: TimeInterval {
        get {
            let stored = UserDefaults.standard.double(forKey: intervalKey)
            return stored > 0 ? stored : defaultIntervalSeconds
        }
        set { UserDefaults.standard.set(newValue, forKey: intervalKey) }
    }

    /// How long each break lasts, in seconds. Falls back to the default when unset.
    static var durationSeconds: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: durationKey)
            return stored > 0 ? stored : defaultDurationSeconds
        }
        set { UserDefaults.standard.set(newValue, forKey: durationKey) }
    }

    /// Whether the first-launch welcome has been shown yet. Drives the one-time
    /// welcome window (it can still be reopened manually from the panel's "About").
    static var hasSeenWelcome: Bool {
        get { UserDefaults.standard.bool(forKey: hasSeenWelcomeKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasSeenWelcomeKey) }
    }
}
