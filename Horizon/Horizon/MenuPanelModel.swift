//
//  MenuPanelModel.swift
//  Horizon
//
//  Backs the custom menu-bar panel (MenuPanelView). It bridges the SwiftUI UI to
//  the existing engine — BreakScheduler, BreakSettings, SMAppService — with no new
//  logic of its own, and ticks once a second while the panel is open so the ring
//  and countdown stay live.
//

import AppKit
import Combine
import ServiceManagement

@MainActor
final class MenuPanelModel: NSObject, ObservableObject {

    private let scheduler: BreakScheduler
    private var ticker: Timer?

    /// Set by AppDelegate to dismiss the popover (e.g. after "Take a Break Now").
    var onClose: (() -> Void)?

    @Published private(set) var remaining: TimeInterval = 0
    @Published private(set) var interval: TimeInterval = BreakSettings.intervalSeconds
    @Published private(set) var isPaused = false
    @Published private(set) var intervalMinutes = 20
    @Published private(set) var durationSeconds = 20
    @Published private(set) var launchAtLogin = false

    let intervalPresets = [15, 20, 25, 30, 45, 60]   // minutes
    let durationPresets = [20, 30, 45, 60]           // seconds

    init(scheduler: BreakScheduler) {
        self.scheduler = scheduler
        super.init()
        refresh()
    }

    /// Fraction of the interval elapsed (0…1) — the ring fills as the next break nears.
    var progress: Double {
        guard interval > 0 else { return 0 }
        return min(1, max(0, 1 - remaining / interval))
    }

    func refresh() {
        remaining = scheduler.timeUntilNextBreak
        interval = BreakSettings.intervalSeconds
        isPaused = scheduler.isPaused
        intervalMinutes = Int((BreakSettings.intervalSeconds / 60).rounded())
        durationSeconds = BreakSettings.durationSeconds
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
    }

    func startTicking() {
        stopTicking()
        refresh()
        let timer = Timer(timeInterval: 1, target: self, selector: #selector(tick),
                          userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    func stopTicking() {
        ticker?.invalidate()
        ticker = nil
    }

    @objc private func tick() { refresh() }

    // MARK: - Actions

    func takeBreakNow() {
        onClose?()
        scheduler.triggerBreakNow()
    }

    func togglePause() {
        if isPaused { scheduler.resume() } else { scheduler.pauseForOneHour() }
        refresh()
    }

    func stepInterval(_ direction: Int) {
        let current = Int((BreakSettings.intervalSeconds / 60).rounded())
        let next = stepped(from: current, in: intervalPresets, by: direction)
        BreakSettings.intervalSeconds = TimeInterval(next * 60)
        scheduler.setInterval(TimeInterval(next * 60))
        refresh()
    }

    func stepDuration(_ direction: Int) {
        let next = stepped(from: BreakSettings.durationSeconds, in: durationPresets, by: direction)
        BreakSettings.durationSeconds = next
        refresh()
    }

    func setLaunchAtLogin(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() }
            else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Horizon: launch-at-login toggle failed: \(error.localizedDescription)")
        }
        refresh()
    }

    func quit() { NSApplication.shared.terminate(nil) }

    /// Move to the neighbouring preset (clamped at the ends).
    private func stepped(from value: Int, in presets: [Int], by direction: Int) -> Int {
        var closest = 0
        var smallestDiff = Int.max
        for (index, preset) in presets.enumerated() {
            let diff = abs(preset - value)
            if diff < smallestDiff { smallestDiff = diff; closest = index }
        }
        let target = max(0, min(presets.count - 1, closest + direction))
        return presets[target]
    }
}
