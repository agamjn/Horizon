# Horizon — Build Plan

A native macOS menu-bar app that enforces the **20-20-20 rule**: every 20 minutes it
takes over the screen for 20 seconds and shows a calming nature video, reminding you to
look ~20 feet away to relax your eye muscles. It automatically skips breaks while you're
in a calendar meeting.

> **Status:** planning complete, ready to build. This is the first Mac app for the author
> (a complete beginner to macOS development), so this document explains the *why* and the
> beginner-relevant details, not just the *what*.

---

## 1. Context — why this exists

The author spends long hours at the screen and suffers eye strain despite blue-light
glasses and eye drops. The 20-20-20 rule (every **20** min, look **20** ft away for **20**
sec) relaxes the eye's focusing muscle. Reminders are easy to ignore, so the app **takes
over the screen** to make the break unavoidable — but it's intentionally lightweight and
never pauses your actual work (downloads, music, builds keep running underneath).

---

## 2. What we're building (the experience)

- **Menu-bar-only app.** A small icon lives in the top-right menu bar. **No Dock icon, no
  window.** Clicking the icon opens a small menu:
  - *Next break in: 14:32* (live countdown, refreshed when you open the menu)
  - *Take a break now*
  - *Pause for 1 hour* (shows "Paused — resumes in 43 min" when active)
  - *Launch at login* (a checkbox)
  - *Quit*
- **Every 20 minutes → a 20-second break.** Every connected display fades into a calm
  full-screen cover.
  - On the screen you're actively using: a **looping nature video plays with soft audio**,
    a centered line like *"Look ~20 feet away — relax your eyes,"* and a **0:20 countdown**.
  - Other monitors show a matching dimmed/calm background + the same countdown (no video,
    no duplicate audio — keeps it smooth).
  - The overlay **blocks all clicks and typing** so you actually take the break.
  - **The only way to exit early is a tiny, almost-invisible × in the top-right corner.**
    The **Esc key and every other key/shortcut are disabled.** Otherwise it closes itself
    automatically after 20 seconds and you're exactly where you left off.
- **Skips meetings.** While a calendar event marks you busy, breaks are silently skipped.
- **Skips full-screen apps.** If the foreground app is in macOS *native* full-screen (the
  green-button kind — e.g. a full-screen movie or presentation), the break is skipped too,
  treated the same as a meeting (see §4). Windowed apps and non-full-screen video still get
  breaks normally.

**Adjustable from the menu bar:** the break **interval** (15/20/25/30/45/60 min) and **break
length** (20/30/45/60 sec) are pickable from submenus and persist across launches
(UserDefaults via `BreakSettings`); defaults are 20 min / 20 sec. (The "20 feet" is a
real-world cue, not a setting.)

---

## 3. Tech choice — native Swift + AppKit/SwiftUI, built in Xcode

We use Apple's own toolkit because this app's exact needs (menu-bar utility, full-screen
overlays across monitors with custom window behavior, system-calendar access, smooth video)
are all first-class natively, and it produces the smallest, most native result. Electron
(bundles a whole browser, ~150 MB) and Python (painful overlays + packaging) were both
rejected as overkill/awkward for an always-on utility.

**App shell = AppKit, visuals inside the overlay = SwiftUI.** We deliberately do **not**
use SwiftUI's `MenuBarExtra`, because it gives no access to the low-level window controls
(window level, "appear on all Spaces," "become key," borderless, per-screen frames) that
the break overlay depends on. Instead:
- AppKit `NSStatusItem` for the menu-bar icon/menu (full control), with `LSUIElement = YES`
  to hide the Dock icon.
- The break overlay is a borderless `NSWindow` whose content is a **SwiftUI view embedded
  via `NSHostingView`** — so the pretty parts (video, message, countdown, × button) are
  written in friendly SwiftUI, while AppKit handles the hard window behavior.

---

## 4. Full-screen apps — skip the break (and why)

macOS does **not** allow any normal app to reliably paint over **another app that is in
true full-screen mode** (the green-button kind, e.g. a full-screen movie or presentation).
There is no public API for it (only the OS screensaver/login window can). Rather than fire a
break that can't fully cover the screen, **Horizon treats "the foreground app is in native
full-screen" exactly like "you're in a meeting" — it skips the break and reschedules.** This
respects the OS limit *and* avoids interrupting full-screen video/presentations.

- The full-screen detection is implemented alongside the meeting-skip logic in **Phase 2**,
  and the detection technique will be **validated against official Apple documentation**
  before use (no guessing at private/undocumented behavior).
- Breaks still fire normally for windowed apps and browser video that isn't in native
  full-screen.
- For the normal desktop case, the overlay still uses the strongest legal window settings
  (`NSWindow.level = .screenSaver`, appear-on-all-Spaces) so it reliably covers ordinary
  multi-window, multi-display setups.

---

## 5. Architecture — five small parts, each with one job

```
        ┌─────────────────┐     "are we busy now?"     ┌─────────────────┐
        │ BreakScheduler  │ ─────────────────────────▶ │  MeetingChecker │  (Phase 2)
        │ (the 20-min     │ ◀───────  yes/no  ───────── │  (EventKit)     │
        │  timer + state) │                             └─────────────────┘
        └───────┬─────────┘
                │ "start break"
                ▼
        ┌─────────────────┐     builds 1 window per     ┌─────────────────┐
        │ OverlayController│ ──────  display  ─────────▶ │   BreakView     │
        │ (windows, ×,    │                             │ (SwiftUI: video,│
        │  20s auto-close)│                             │  msg, countdown,│
        └─────────────────┘                             │  × button)      │
                ▲                                        └─────────────────┘
                │ menu actions (break now / pause / quit / launch-at-login)
        ┌───────┴─────────┐
        │ MenuBarController│  (NSStatusItem + NSMenu)
        └─────────────────┘
```

- **BreakScheduler** — owns the timer and the "next break" target time; handles pause/snooze;
  asks MeetingChecker before firing; tells OverlayController to start a break.
- **MeetingChecker** *(Phase 2)* — answers "should we skip this break right now?": yes if a
  calendar event marks you busy (EventKit) **or** the foreground app is in native full-screen.
- **OverlayController** — creates one overlay window per display, shows/fades them, enforces
  the ×-only / 20-second-only exit, tears everything down afterward.
- **BreakView** — the SwiftUI visuals shown inside each overlay window.
- **MenuBarController** — the menu-bar icon and menu.

Each part is small enough to build and test on its own.

---

## 6. Phased build plan

### Phase 0 — Setup (foundations) ⚙️
*Goal: an empty app that launches silently into the menu bar, in a git repo on GitHub.*

1. **Install Xcode** from the Mac App Store (free, but a large multi-GB download — do this
   first, it takes a while). Then in Terminal accept the license and tools when prompted.
   *(This is the one step only you can do; I'll guide it.)*
2. Create a new Xcode project: macOS **App**, SwiftUI interface, language Swift. Name it
   **Horizon**. Suggested bundle id: `io.github.agamjn.Horizon`.
3. In the target's **Info** settings, add **`Application is agent (UIElement)` = YES**
   (this is `LSUIElement`) so there's no Dock icon and no window at launch.
4. Replace the default window scene with an `NSApplicationDelegateAdaptor` + AppDelegate
   that creates a placeholder `NSStatusItem` with a "Quit" item that calls
   `NSApplication.shared.terminate(nil)` (an agent app gets no free Cmd-Q).
5. **Create the GitHub repo** on the `agamjn` account (via the `gh` CLI you're logged into):
   `Horizon`, **private to start**, with a `.gitignore` (Swift), an MIT `LICENSE`, and a
   README stub. Commit this plan + the empty project.

**Verify:** Run in Xcode (Cmd+R) → an icon appears in the menu bar, no Dock icon, no window;
"Quit" works.

### Phase 1 — The core eye-break app 👁️ (this is your usable "v1")
*Goal: the full 20-20-20 experience, no calendar yet.*

1. **MenuBarController:** real icon (template SF Symbol like `eye`), menu with live "next
   break in…" (rebuilt in `menuWillOpen`), *Take a break now*, *Pause for 1 hour*, *Launch
   at login*, *Quit*.
2. **BreakScheduler:** schedule the next break as an absolute **wall-clock `Date`** (not a
   naive repeating tick — see §7) and check it on a 1-second timer; expose pause/snooze and
   "break now."
3. **OverlayController + custom borderless `NSWindow` subclass** (`canBecomeKey = true`):
   one window per `NSScreen.screens`, `level = .screenSaver`,
   `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]`,
   fade in via `alphaValue` animation. Disable Esc/keys: override `cancel(_:)` **and**
   `cancelOperation(_:)` as no-ops and swallow `keyDown`. Only the × button and a hard 20s
   deadline (`asyncAfter`, independent of the display timer) dismiss it.
4. **BreakView (SwiftUI in `NSHostingView`):** full-bleed looping video on the main screen
   via `AVQueuePlayer` + `AVPlayerLooper` + `AVPlayerLayer` (`.resizeAspectFill`); centered
   message + 0:20 countdown; tiny low-opacity (`xmark`) button top-trailing. Secondary
   screens: dimmed background + mirrored countdown, no audio. Pick **one random clip per
   break** from the 2–3 bundled clips.
5. **Launch at login:** `SMAppService.mainApp.register()` / `.unregister()`; reflect real
   `.status` in the menu checkbox.
6. **Robustness (§7):** handle Mac sleep/wake, screen lock (pause while locked), and display
   hot-plug (rebuild windows on `didChangeScreenParametersNotification`); keep an App-Nap
   activity assertion so the timer stays honest.

**Verify:** Temporarily set the interval to ~15s for testing. Confirm: overlay covers all
displays; video + audio play; × closes it; Esc and other keys do nothing; it auto-closes at
20s; a download/music in another app keeps running; "Launch at login" appears in System
Settings → General → Login Items.

### Phase 2 — Meeting & full-screen awareness 📅
*Goal: silently skip breaks during calendar meetings (incl. Google Calendar synced into
macOS) and while a foreground app is in native full-screen.*

1. Add **`NSCalendarsFullAccessUsageDescription`** to Info **and the
   `com.apple.security.personal-information.calendars` entitlement** (App Sandbox is on);
   request access with `EKEventStore().requestFullAccessToEvents()`.
2. **MeetingChecker (calendar):** query `predicateForEvents` for a 1-minute window around
   "now"; consider you busy if an event is `availability == .busy`, **excluding all-day
   events and invitations you've declined**. (Google calendars added in **System Settings →
   Internet Accounts** show up here automatically — no Google API/OAuth needed.)
3. **MeetingChecker (full-screen):** detect whether the foreground app is in macOS native
   full-screen and, if so, also skip — **detection technique validated against official
   Apple docs first** (§4).
4. BreakScheduler asks MeetingChecker before firing; if it should skip, reschedule. Menu
   shows the reason ("Paused — in a meeting" / "Paused — full-screen app").

**Verify:** Add a Google account's Calendars in Internet Accounts; create a test event marked
*Busy* covering now; confirm the break is skipped and fires normally outside the event. Put
an app into native full-screen; confirm the break is skipped there too.

### Phase 3 — Polish & share (later, optional) ✨
App icon; nicer menu; README with a demo GIF + build-from-source instructions; tag a `v1.0`
release. A one-click **notarized** download for non-technical users is a separate, **paid**
Apple step (Developer Program + Developer ID + notarization) — documented for when/if wanted.
Not needed for build-from-source.

---

## 7. Key technical decisions (validated reference)

| Area | Decision |
|---|---|
| App shell | AppKit `NSStatusItem` + `LSUIElement = YES`; SwiftUI only **inside** overlays via `NSHostingView` |
| Overlay windows | One **borderless `NSWindow` per screen**, subclassed so `canBecomeKey = true`; `makeKeyAndOrderFront` + `NSApp.activate(ignoringOtherApps: true)` |
| Window stacking | `level = .screenSaver`; `collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]`; `NSApp.presentationOptions = [.autoHideMenuBar, .autoHideDock]` while shown |
| Disable Esc/keys | Override `cancel(_:)` **and** `cancelOperation(_:)` as no-ops; swallow `keyDown`; no default button. Exits = × button + hard 20s deadline only |
| Video | `AVQueuePlayer` + `AVPlayerLooper` + `AVPlayerLayer` (`.resizeAspectFill`); local **HEVC** `.mov/.mp4`; keep strong refs to player/looper/windows; one random clip per break; audio on main screen only |
| Launch at login | `SMAppService.mainApp.register()`; read `.status` for the menu state (don't trust UserDefaults alone) |
| Calendar (Phase 2) | `requestFullAccessToEvents()` + `NSCalendarsFullAccessUsageDescription`; filter `.busy`, drop all-day + declined; Google-via-Internet-Accounts works |
| Signing / sandbox | Automatic signing with your **free Personal Team**. **Keep Xcode 26's default App Sandbox ON** (good for a distributed app); add the `com.apple.security.personal-information.calendars` entitlement in Phase 2 for EventKit, and revisit only if full-screen detection needs broader access. Notarize only to ship prebuilt binaries |
| Timer | Schedule next break as an absolute `Date`; 1s check timer; `ProcessInfo.beginActivity(.userInitiated, …)` to dodge App Nap |
| Sleep/lock/displays | Observe `NSWorkspace` sleep/wake; pause while screen locked (`com.apple.screenIsLocked`); rebuild windows on `didChangeScreenParametersNotification` |
| Safety | Independent `asyncAfter` 20s dismissal so a missed timer can never trap you behind the overlay |

---

## 8. Open source & licensing

- **License:** MIT (permissive, simple).
- **Distribution:** others **build from source** (README will show: open in Xcode → Run).
  No notarization needed for that.
- **Bundled videos must be royalty-free / CC0** (e.g. from Pexels/Pixabay) since the repo is
  public. We'll credit each clip's source in the README/`CREDITS`. Keep them small,
  well-compressed HEVC so the repo stays light (consider Git LFS only if they get large).

---

## 9. Beginner glossary

- **Xcode** — Apple's free app for building Mac/iOS apps.
- **AppKit / SwiftUI** — Apple's two UI toolkits; SwiftUI is newer/simpler, AppKit is older
  with more low-level control. We use both (AppKit for the shell, SwiftUI for the visuals).
- **`NSStatusItem`** — the API for a menu-bar icon. **`NSWindow`** — a window. **`NSScreen`**
  — a connected display.
- **`LSUIElement`** — an Info.plist flag that makes an app a background "agent" (no Dock icon).
- **EventKit** — Apple's framework for reading the system Calendar.
- **Notarization** — Apple scanning your built app so other people's Macs trust it; needs a
  paid account; only for distributing prebuilt binaries.

---

## 10. Who does what

- **You:** install Xcode (the big download); approve the GitHub repo creation; click through
  the macOS permission prompts (calendar access in Phase 2); be the tester.
- **Me:** scaffold the project, write all the code, create the repo, and walk you through each
  step in detail as we go.

---

## 11. How we'll work (process)

- **One TODO list, checked off as we go.** Every phase is broken into small, targeted steps
  in [`TODO.md`](TODO.md). Each step is ticked `[x]` the moment it's done and verified.
- **Active working memory.** The project's status is kept current in Claude's project memory
  (updated each phase) so progress survives across sessions.
- **Test after each actionable step.** Every implementation step is followed by a basic check
  — for scaffolding that means "it builds and the app launches/behaves as expected"; for
  logic (the timer, the meeting/full-screen filtering) that means small automated tests,
  written test-first.
- **Authentic sources only.** API decisions are based on **official Apple Developer and Swift
  documentation** (and other authoritative sources), linked/quoted when it matters — never
  guesswork.
- **No unnecessary dependencies.** We build with Apple's system frameworks only. No cloning
  random third-party repos and no extra packages unless there's a clear, justified reason
  (discussed first).

---

## 12. Distribution — free unsigned download (with a paid upgrade path)

*Researched & decided 2026-05-31 (deep-research report).* Goal: let people download and run
Horizon **without Xcode** and **without the $99/yr Apple fee**.

- **Reality:** there is **no free way** to avoid Gatekeeper's "unidentified developer"
  warning — notarization requires the paid Developer Program. So the free download has a
  **one-time** approval step.
- **How (free, now):** `scripts/package.sh` builds Release, **ad-hoc signs** the app
  (`codesign --sign -`), and makes a **`.dmg`** (`hdiutil` — no third-party tools). A
  **GitHub Actions** workflow (`.github/workflows/release.yml`) runs it on every `v*` tag and
  uploads the `.dmg` to **GitHub Releases** via the built-in `gh` CLI + `GITHUB_TOKEN`.
- **User experience:** download `.dmg` → drag to Applications → first launch is blocked →
  **System Settings ▸ Privacy & Security ▸ "Open Anyway"** + password (once per version).
  Power users can instead run `xattr -dr com.apple.quarantine /Applications/Horizon.app`.
- **Media caveat:** CI clones the repo, which has **no bundled clips** (git-ignored stock
  footage), so the **downloaded app uses the gradient + silence** unless CC0 media is
  committed. Shipping media in the download requires CC0/public-domain assets.
- **Upgrade path (no lock-in):** later, enrol in the Developer Program and add Developer ID
  signing + `notarytool` + `stapler` to the same pipeline → downloads & updates become
  warning-free. Same code/repo/bundle id. (Switching signing identity resets TCC, so
  post-Phase-2 users re-grant Calendar once.)
- **Testing:** a packaging pipeline has no XCTest unit test; instead `scripts/package.sh`
  carries smoke-test asserts (built `.app` exists, `codesign --verify` passes, `.dmg` mounts),
  run locally and in CI, plus a real tagged CI release as the end-to-end check.
