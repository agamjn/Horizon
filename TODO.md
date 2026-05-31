# Horizon — TODO

The build, phase by phase. Each step is checked off **only after it's done and basic-tested**.
See [PLAN.md](PLAN.md) for the full design and the working process (§11).

Legend: `[ ]` not started · `[~]` in progress · `[x]` done & verified

## Phase 0 — Setup

### 0a · Repo & docs  *(no Xcode needed)* — ✅ done
- [x] Write project docs: PLAN.md, README.md, MIT LICENSE, Swift `.gitignore`, TODO.md
- [x] `git init` (branch `main`) and make the first commit
- [x] Create GitHub repo `agamjn/Horizon` (**private**) and push
- [x] Verify: repo exists on GitHub, `origin` remote set, first commit pushed

### 0b · Xcode project  *(needs Xcode installed)* — ✅ done
- [x] **(You)** Install Xcode from the Mac App Store; accept license + install components
- [x] Create a macOS **App** project "Horizon" (SwiftUI, Swift), bundle id `io.github.agamjn.Horizon`
- [x] Set **Application is agent (UIElement) = YES** (`LSUIElement`)
- [x] Replace default window with `AppDelegate` + `NSStatusItem`; Quit → `terminate(_:)`
- [x] Verify: builds & runs; menu-bar icon shows; **no** Dock icon; **no** window; Quit works
- [x] Commit "Phase 0: menu-bar shell"

## Phase 1 — Core eye-break app  *(your usable v1)*

### Menu bar — ✅ done & user-verified
- [x] Menu (in `AppDelegate`, `NSMenuDelegate`): icon + "Next break in…", Take a Break Now, Pause for 1 Hour/Resume, Launch at Login, Quit
- [x] Refresh "Next break in…" + pause/launch state in `menuWillOpen`
- [x] Test: countdown shows & decreases on reopen; Pause → "Paused" / "Resume" toggles correctly

### Scheduler
- [x] `BreakSchedule` pure logic (interval · pause · resume · wake) — **TDD: 7 tests green**
- [x] `BreakScheduler` class: 1s check timer driving `BreakSchedule`; triggers + reschedules the overlay
- [x] App-Nap activity assertion (`beginActivity(.userInitiated)`); reschedule on wake
- [x] Behavioral test: auto-fires on schedule (verified at a short test interval, then set back to 20 min)
- [ ] Pause-for-1-hour menu item + "next break in…" countdown

### Overlay — ✅ done & user-verified
- [x] Borderless `NSWindow` subclass (`canBecomeKey = true`); one window per `NSScreen`
- [x] `level = .screenSaver` (also covers the menu bar — no presentationOptions needed); `collectionBehavior` flags; fade in/out
- [x] Disable Esc/keys: `cancel(_:)` & `cancelOperation(_:)` no-ops; swallow `keyDown`; ×-only + safety timer
- [x] Test: covers all displays; input blocked; Esc ignored; only × / 20s closes; other apps keep running
- [x] Wired to a "Take a Break Now" menu item (manual trigger)
- [x] Block Space-switching during a break: consume scroll/swipe + `disableProcessSwitching` (Force Quit kept as a safety hatch) — user-verified

### Break visuals
- [x] Video engine: looping `AVQueuePlayer`+`AVPlayerLooper`+`AVPlayerLayer` via SwiftUI `NSViewRepresentable`; one random clip/break; audio on primary only; **gradient fallback when no clips bundled**
- [x] Test: user-verified — video loops, fills the screen, text legible over footage, × works (tested locally with Pexels clips)
- [x] Repo ships an empty `BreakVideos/` (README only) + gradient fallback; clip files stay local & git-ignored (license). Awaiting user's CC0/royalty-free clips to commit
- [ ] (Follow-up) Soothing audio on *every* break — most stock clips are silent; add a dedicated ambient audio loop

### Launch at login — ✅ done & user-verified
- [x] `SMAppService.mainApp` register/unregister via a "Launch at Login" menu toggle
- [x] `menuWillOpen` refreshes the checkmark from `.status` (AppDelegate is `NSMenuDelegate`)
- [x] Test: toggling adds/removes Horizon in System Settings → Login Items

### Robustness
- [ ] Sleep/wake (recompute from target `Date`; reschedule missed break)
- [ ] Pause while screen locked (`screenIsLocked`/`screenIsUnlocked`)
- [ ] Rebuild windows on `didChangeScreenParametersNotification` (display hot-plug)
- [ ] Test: lock/unlock, sleep/wake, plug/unplug a display all behave
- [ ] Commit "Phase 1: core eye-break app (v1)"

## Phase 2 — Meeting & full-screen awareness
- [ ] Add `NSCalendarsFullAccessUsageDescription`; `requestFullAccessToEvents()`
- [ ] `MeetingChecker` (calendar): events overlapping now, `.busy`, exclude all-day + declined
- [ ] `MeetingChecker` (full-screen): detect foreground app in native full-screen *(validate vs official docs)* → also skip
- [ ] Scheduler asks before firing; skip + reschedule; menu shows reason
- [ ] Tests: busy event skips; declined/all-day don't; full-screen skips; normal fires
- [ ] Commit "Phase 2: skip during meetings and full-screen"

## Phase 3 — Polish & release  *(later)*
- [ ] App icon; README with demo GIF + build-from-source steps
- [ ] Flip repo **public**; tag `v1.0`
- [ ] *(Optional, paid)* Developer ID signing + notarization for prebuilt downloads
