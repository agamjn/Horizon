//
//  BreakSchedule.swift
//  Horizon
//
//  Pure scheduling logic for breaks: no timers and no system calls, so it can be
//  unit-tested deterministically by passing in the current date. `BreakScheduler`
//  (added next) drives this with a real timer and connects it to the overlay.
//

import Foundation

struct BreakSchedule {

    /// Seconds between breaks (20 minutes by default — the "20" in 20-20-20).
    private(set) var interval: TimeInterval

    /// When the next break is due.
    private(set) var nextFireDate: Date

    /// If set and still in the future, breaks are paused until this date.
    private(set) var pausedUntil: Date?

    init(interval: TimeInterval = 20 * 60, now: Date) {
        self.interval = interval
        self.nextFireDate = now.addingTimeInterval(interval)
        self.pausedUntil = nil
    }

    /// Whether a pause is currently in effect.
    func isPaused(now: Date) -> Bool {
        guard let pausedUntil else { return false }
        return now < pausedUntil
    }

    /// Whether a break should start now: the interval has elapsed and we're not paused.
    func shouldFire(now: Date) -> Bool {
        !isPaused(now: now) && now >= nextFireDate
    }

    /// Seconds until the next break (0 if it's due now or overdue).
    func timeUntilNextBreak(now: Date) -> TimeInterval {
        max(0, nextFireDate.timeIntervalSince(now))
    }

    /// Start counting a fresh interval from `now`. Call after a break finishes or
    /// is skipped.
    mutating func scheduleNext(from now: Date) {
        nextFireDate = now.addingTimeInterval(interval)
    }

    /// Change the interval between breaks and restart the countdown from `now`.
    mutating func setInterval(_ seconds: TimeInterval, now: Date) {
        interval = seconds
        nextFireDate = now.addingTimeInterval(seconds)
    }

    /// Pause breaks for a number of seconds (e.g. 3600 for "1 hour"). The next
    /// break is set to one full interval *after* the pause ends, so the pause
    /// doesn't finish with an immediate break.
    mutating func pause(forSeconds seconds: TimeInterval, now: Date) {
        let until = now.addingTimeInterval(seconds)
        pausedUntil = until
        nextFireDate = until.addingTimeInterval(interval)
    }

    /// Clear any pause and start a fresh interval from `now`.
    mutating func resume(now: Date) {
        pausedUntil = nil
        nextFireDate = now.addingTimeInterval(interval)
    }

    /// Handle waking from sleep: don't ambush the user with a break that came due
    /// while the Mac was asleep — restart the interval (unless a pause is active).
    mutating func handleWake(now: Date) {
        if !isPaused(now: now) {
            nextFireDate = now.addingTimeInterval(interval)
        }
    }
}
