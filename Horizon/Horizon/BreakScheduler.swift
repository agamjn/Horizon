//
//  BreakScheduler.swift
//  Horizon
//
//  Drives the (unit-tested) BreakSchedule with a real 1-second timer: when a
//  break is due it shows the overlay, and it starts counting the next interval
//  once the break ends. It also keeps the timer honest by holding an activity
//  assertion against App Nap, and avoids ambushing the user with a break that
//  came due while the Mac was asleep.
//

import AppKit

@MainActor
final class BreakScheduler: NSObject {

    private var schedule: BreakSchedule
    private let overlay: OverlayController
    private var tickTimer: Timer?
    private var activityToken: NSObjectProtocol?
    private var isBreaking = false

    init(overlay: OverlayController, interval: TimeInterval = 20 * 60) {
        self.overlay = overlay
        self.schedule = BreakSchedule(interval: interval, now: Date())
        super.init()

        // When a break ends (manual or automatic), start counting the next one.
        overlay.onBreakEnded = { [weak self] in
            guard let self else { return }
            self.isBreaking = false
            self.schedule.scheduleNext(from: Date())
        }
    }

    /// Begin scheduling: start the check timer, guard against App Nap, and watch
    /// for wake-from-sleep.
    func start() {
        // Keep our timer from being throttled while the app sits idle in the menu
        // bar. `.userInitiated` is enough — it does not prevent the Mac sleeping.
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: .userInitiated,
            reason: "Horizon 20-20-20 break timer"
        )

        // Add to `.common` modes so it keeps ticking even while a menu is open.
        let timer = Timer(timeInterval: 1, target: self,
                          selector: #selector(tick), userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        tickTimer = timer

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    /// Trigger a break right now (the "Take a Break Now" menu item).
    func triggerBreakNow() {
        startBreak()
    }

    @objc private func tick() {
        guard !isBreaking else { return }
        if schedule.shouldFire(now: Date()) {
            startBreak()
        }
    }

    @objc private func handleWake() {
        // Reschedule so a break that came due during sleep doesn't fire instantly.
        schedule.handleWake(now: Date())
    }

    private func startBreak() {
        isBreaking = true
        overlay.startBreak()
    }
}
