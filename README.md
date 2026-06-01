# Horizon 👁️

**A tiny macOS menu-bar app that protects your eyes with the 20‑20‑20 rule.**

Every 20 minutes, Horizon gently takes over your screen for 20 seconds and shows a calming
nature scene — your cue to look into the distance and let your eyes relax. Then it hands your
screen right back.

> **The 20‑20‑20 rule:** every **20 minutes**, look at something **20 feet** away for
> **20 seconds**. It relaxes the focusing muscles that fatigue from staring at a screen up close.

<!-- TODO: add a short demo GIF of a break in action here -->

## Features

- 🖥️ **Lives in the menu bar** — no Dock icon, no windows; just a quiet eye icon.
- ⏱️ **Automatic break every 20 minutes**, with a live “next break in M:SS” countdown.
- ⚙️ **Adjustable** interval and break length right from the menu bar (presets, saved across launches; defaults to 20 min / 20 s).
- 🌲 **Full‑screen calming break on every display**, with a 20‑second countdown.
- 🎬 **Optional nature video + ambient audio** that you supply (see [Assets](#assets-break-video--audio)). With none present it shows a calm gradient — the app works fine either way.
- 🔒 **Actually makes you pause.** During a break it blocks clicks, typing, Cmd‑Tab, Mission Control, and Spaces‑switching, so you can’t reflexively work through it. (Force Quit stays available as a safety hatch, and the break always auto‑closes after 20 s.)
- ✕ **One quiet way out** — a faint × in the corner if you genuinely must skip.
- ⏸️ **Pause for 1 hour** when you need uninterrupted time.
- 🚀 **Launch at login** toggle.
- 💤 **Stays out of your way** — it reschedules around sleep/wake and screen‑lock (no ambush when you return), and re‑covers correctly when you plug/unplug a monitor. Your background work (downloads, music, builds) keeps running the whole time.

## Requirements

- **macOS 13 (Ventura) or later** — Apple Silicon *or* Intel (universal build)
- **Xcode 15 or later** (free on the Mac App Store) — to build from source

## Download (easiest — no Xcode)

Grab the latest **`Horizon.dmg`** from the **[Releases page](https://github.com/agamjn/Horizon/releases/latest)**, open it, and drag **Horizon** into **Applications**.

**First launch (one time).** Horizon isn't notarized (that requires a paid Apple account), so macOS blocks it the first time. To allow it:

1. Double-click Horizon → you'll see *"Apple could not verify…"* → click **Done**.
2. Open **System Settings ▸ Privacy & Security**, scroll to **Security**, and click **Open Anyway**.
3. Click **Open Anyway** again and enter your password. Horizon opens and the 👁 icon appears in your menu bar.

You won't be asked again *for this version*.

> **Power-user shortcut** (skips all prompts) — after downloading, run once in Terminal:
> ```sh
> xattr -dr com.apple.quarantine /Applications/Horizon.app
> ```

**Updating.** Download the new `Horizon.dmg`, quit Horizon, and drag the new copy into Applications (choose **Replace**). Because the app is unsigned, macOS will ask you to **Open Anyway** once more for the new version (or just re-run the `xattr` command above).

> 🎬 **Calming video/audio?** Downloads ship with a plain gradient — the sample nature clips are license-restricted and aren't bundled. See [Assets](#assets-break-video--audio) to drop in your own.

## Install (build from source)

Horizon isn’t notarized for one‑click download yet, so for now you build it yourself — it only takes a minute:

1. **Clone the repo**
   ```sh
   git clone https://github.com/agamjn/Horizon.git
   cd Horizon
   ```
2. **Open it in Xcode**
   ```sh
   open Horizon/Horizon.xcodeproj
   ```
3. **Pick your signing team (one time):** select the **Horizon** target → **Signing & Capabilities** → set **Team** to your own Apple ID (a free one works fine). You can also change the bundle identifier to your own if you like.
4. **Run:** press **▶ (⌘R)**. An eye icon appears in your menu bar — that’s it.
5. *(Optional)* Click the icon → **Launch at Login** so Horizon starts with your Mac. To keep a stable copy around, build for **Release** (Product → Archive, or Product → Build) and drag the resulting **Horizon.app** into **/Applications**.

## Using Horizon

Click the eye icon in the menu bar:

| Menu item | What it does |
|---|---|
| **Next break in M:SS** | Time remaining until the next automatic break |
| **Take a Break Now** | Start a break immediately |
| **Pause for 1 Hour** / **Resume** | Temporarily stop breaks (e.g. during a presentation) |
| **Break Every** | How often a break fires (15–60 min; default 20) |
| **Break Length** | How long each break lasts (20–60 sec; default 20) |
| **Launch at Login** | Start Horizon automatically when you log in |
| **Quit Horizon** | Quit the app |

During a break, just look ~20 feet away and wait for the 20‑second countdown (that’s the point!). If you truly must get back, click the faint **×** in the top‑right corner.

## Assets (break video & audio)

Horizon plays an optional calming **nature video** behind the break, plus an optional **ambient
audio** loop. Both are optional — with neither present, the break shows a calm gradient in silence.

Add your own by dropping files into these folders (create them if they don’t exist); they’re
picked up automatically, with one chosen at random per break:

- **Video** → `Horizon/Horizon/BreakVideos/` — `.mp4`, `.mov`, or `.m4v`
- **Audio** → `Horizon/Horizon/BreakAudio/` — `.mp3`, `.m4a`, `.wav`, … (when an audio track is
  present, the video is muted so the ambient sound stays consistent across clips)

> **These folders are git‑ignored on purpose.** Typical free‑stock licenses (Pexels, Pixabay,
> Mixkit, …) let you *use* footage/audio in an app but restrict redistributing the raw files —
> which a public repo would do. So keep your downloads local. Only commit assets that are
> genuinely **CC0 / public‑domain**, by adding an explicit exception in [`.gitignore`](.gitignore).

Tip: keep clips short (≈15–25 s) and ~1080p, and audio a short seamless loop, so the app stays light. They loop automatically.

## Roadmap

- 📅 **Skip during meetings** — read your macOS Calendar (which can sync your Google Calendar)
  via EventKit and automatically skip breaks while you’re in a meeting.
- 🖥️ **Skip during full‑screen apps** — don’t interrupt a full‑screen video or presentation.
- 📦 **Notarized one‑click download**, so non‑developers can install without building.
- 🎨 A proper **app icon** and a demo GIF.

See [PLAN.md](PLAN.md) for the full design and [TODO.md](TODO.md) for live progress.

## How it works (for the curious)

- A menu‑bar **agent** app (`LSUIElement`) built with **AppKit + SwiftUI**.
- A small, **unit‑tested** wall‑clock scheduler (`BreakSchedule`) decides when breaks fire; it
  survives App Nap, sleep/wake, and screen lock rather than drifting.
- Each break puts a borderless, top‑most (`.screenSaver`‑level) window on every display, plays a
  looping clip via `AVPlayerLooper`, and uses `NSApplicationPresentationOptions` to disable
  Mission Control / Spaces‑switching for the duration.

## Contributing

Issues and pull requests are welcome — the codebase is small and heavily commented. Start with
[PLAN.md](PLAN.md) for the architecture and [TODO.md](TODO.md) for what’s next.

## License

[MIT](LICENSE) © 2026 Agam Jain.

*Nature footage and audio used during development are from [Pexels](https://www.pexels.com)
(used locally, not redistributed in this repo).*
