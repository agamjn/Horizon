//
//  BreakScheduleTests.swift
//  HorizonTests
//
//  Unit tests for the pure scheduling logic in `BreakSchedule`. Every test passes
//  in a controlled "now" date, so they're fully deterministic — no waiting on real
//  timers.
//

import Testing
import Foundation
@testable import Horizon

@MainActor
struct BreakScheduleTests {

    // Fixed reference points so the tests are deterministic.
    let start = Date(timeIntervalSinceReferenceDate: 1_000_000)
    let interval: TimeInterval = 20 * 60   // 20 minutes

    @Test func nextBreakIsOneIntervalAfterStart() {
        let schedule = BreakSchedule(interval: interval, now: start)
        #expect(schedule.timeUntilNextBreak(now: start) == interval)
        #expect(schedule.shouldFire(now: start) == false)
    }

    @Test func firesOnlyOnceTheIntervalHasElapsed() {
        let schedule = BreakSchedule(interval: interval, now: start)
        #expect(schedule.shouldFire(now: start.addingTimeInterval(interval - 1)) == false)
        #expect(schedule.shouldFire(now: start.addingTimeInterval(interval)) == true)
        #expect(schedule.shouldFire(now: start.addingTimeInterval(interval + 5)) == true)
    }

    @Test func schedulingNextResetsTheInterval() {
        var schedule = BreakSchedule(interval: interval, now: start)
        let firedAt = start.addingTimeInterval(interval)
        schedule.scheduleNext(from: firedAt)
        #expect(schedule.shouldFire(now: firedAt) == false)
        #expect(schedule.timeUntilNextBreak(now: firedAt) == interval)
        #expect(schedule.shouldFire(now: firedAt.addingTimeInterval(interval)) == true)
    }

    @Test func pauseSuppressesBreaksUntilItEnds() {
        var schedule = BreakSchedule(interval: interval, now: start)
        schedule.pause(forSeconds: 3600, now: start)        // pause for 1 hour

        #expect(schedule.isPaused(now: start) == true)
        // Won't fire while paused, even past the original break time.
        #expect(schedule.shouldFire(now: start.addingTimeInterval(interval)) == false)
        #expect(schedule.isPaused(now: start.addingTimeInterval(3599)) == true)

        // When the pause ends, a fresh interval remains — no instant break.
        let afterPause = start.addingTimeInterval(3600)
        #expect(schedule.isPaused(now: afterPause) == false)
        #expect(schedule.shouldFire(now: afterPause) == false)
        #expect(schedule.shouldFire(now: afterPause.addingTimeInterval(interval)) == true)
    }

    @Test func resumingEarlyStartsAFreshInterval() {
        var schedule = BreakSchedule(interval: interval, now: start)
        schedule.pause(forSeconds: 3600, now: start)
        let resumeAt = start.addingTimeInterval(600)        // resume after 10 minutes
        schedule.resume(now: resumeAt)

        #expect(schedule.isPaused(now: resumeAt) == false)
        #expect(schedule.timeUntilNextBreak(now: resumeAt) == interval)
        #expect(schedule.shouldFire(now: resumeAt.addingTimeInterval(interval)) == true)
    }

    @Test func wakingFromSleepReschedulesInsteadOfAmbushing() {
        var schedule = BreakSchedule(interval: interval, now: start)
        let wake = start.addingTimeInterval(3 * 3600)       // asleep for 3 hours
        #expect(schedule.shouldFire(now: wake) == true)      // would ambush right on wake
        schedule.handleWake(now: wake)
        #expect(schedule.shouldFire(now: wake) == false)     // rescheduled instead
        #expect(schedule.timeUntilNextBreak(now: wake) == interval)
    }

    @Test func wakingDoesNotOverrideAnActivePause() {
        var schedule = BreakSchedule(interval: interval, now: start)
        schedule.pause(forSeconds: 3600, now: start)
        schedule.handleWake(now: start.addingTimeInterval(600))
        // Still paused, and the post-pause break time is unchanged.
        #expect(schedule.isPaused(now: start.addingTimeInterval(600)) == true)
        let afterPause = start.addingTimeInterval(3600)
        #expect(schedule.shouldFire(now: afterPause) == false)
        #expect(schedule.shouldFire(now: afterPause.addingTimeInterval(interval)) == true)
    }
}
