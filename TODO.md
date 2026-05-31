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

### Menu bar
- [ ] `MenuBarController`: real icon (SF Symbol) + items (Next break, Take a break now, Pause 1h, Launch at login, Quit)
- [ ] Rebuild "Next break in…" title in `menuWillOpen`
- [ ] Test: menu shows correct dynamic countdown

### Scheduler
- [ ] `BreakScheduler`: next break as absolute `Date` + 1s check timer  *(tests first)*
- [ ] App-Nap activity assertion (`beginActivity(.userInitiated)`)
- [ ] Pause-for-1-hour, "take a break now"
- [ ] Tests: fires at target; pause suppresses; resumes correctly

### Overlay
- [ ] Borderless `NSWindow` subclass (`canBecomeKey = true`); one window per `NSScreen`
- [ ] `level = .screenSaver`; `collectionBehavior` flags; hide menu bar; fade in/out
- [ ] Disable Esc/keys: `cancel(_:)` & `cancelOperation(_:)` no-ops; swallow `keyDown`; ×-only + hard 20s deadline
- [ ] Test: covers all displays; input blocked; only × / 20s closes; other apps keep running

### Break visuals
- [ ] Source 2–3 **CC0** nature clips (HEVC), compress, bundle, add `CREDITS`
- [ ] `BreakView` (SwiftUI via `NSHostingView`): looping `AVQueuePlayer`+`AVPlayerLooper`+`AVPlayerLayer`, message, countdown, tiny ×
- [ ] Audio on main screen only; dimmed bg + countdown on secondaries; one random clip/break
- [ ] Test: video loops seamlessly; audio only on main; countdown accurate

### Launch at login
- [ ] `SMAppService.mainApp` register/unregister; reflect `.status` in menu
- [ ] Test: toggling adds/removes it in System Settings → Login Items

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
