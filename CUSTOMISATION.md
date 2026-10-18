# Sailing JN

A personal fork of [dmrrlc/connectiq-sailing](https://github.com/dmrrlc/connectiq-sailing)
(MIT, © 2015 antistatique.net) for a **Garmin Instinct 2X Solar** (`instinct2x`).
`README.md` is upstream's. This file describes Sailing JN.

- **Name:** "Sailing JN". **App id:** `A539BFC7389E42C09EE986AD316F9A23`. It installs **alongside**
  the store "Sailing" app and never replaces it.
- **Base:** upstream as of **Oct 2025** (`b769266`), plus the crash and bug fixes upstream made since.
  The Sept 2026 upstream features (Cruise mode, pause menu, manual start, BACK = lap, data pages) are **not** included.
- Background analysis: [docs/CODE_REVIEW.md](docs/CODE_REVIEW.md).
- How to test and get it onto the watch: [docs/BUILD_AND_INSTALL.md](docs/BUILD_AND_INSTALL.md).

## How it works

Open the app and leave it. **Recording starts by itself** as soon as the GPS is usable
("Waiting for GPS signal" until then). It always opens in **Race** mode.

### Buttons (both modes)

| Button | Race mode | FC Cruise mode |
|---|---|---|
| **GPS** (top right) | Start / stop (abort) the race countdown | Start / stop the helm timer |
| **UP / DOWN** | During countdown: sync +1 min / −1 min | While helm timer runs: +1 / −1 min |
| **BACK** | Exit menu: Save · Discard · Resume | same |
| **Hold UP** (Menu) | Menu (below) | Menu (below) |

### Menu (hold UP)

| Race mode | FC Cruise mode |
|---|---|
| Start timer | Start helm timer |
| Set timer (0–30 min, default 5) | Set helm timer (1–60 min, default 20) |
| Alarms: on / off (shows current state) | Alarms: on / off |
| **FC Cruise mode** (switches immediately) | **Race mode** (switches immediately) |

Switching mode stops the other mode's timer. The activity keeps recording either way.
The mode is not saved: the app opens in Race mode every time.

### Race mode

Screen: time of day, speed (kts), heading in the subscreen, and race clock after the gun.

Countdown buzzes, by time left on the display:

| 5:00 | 4:00 | 3:00 | 2:00 | 1:00 | 0:30 | 0:20 | 0:10 | 0 (gun) |
|---|---|---|---|---|---|---|---|---|
| — | ×4 | ×3 | ×2 | ×1 | ×3 | ×2 | ×1 | — |

For countdowns longer than 5 min, the 5:00-and-above minute marks are silent.
At the gun: "START" shows for 5 s (silent), a lap is added, and the race clock starts.
A sync press gives one short vibration (no tone).
Timing is unchanged from the original, so the gun comes about 1 s early. That's deliberate.

### FC Cruise mode (helm changes)

Screen: "FC CRUISE", helm time left, speed, heading in the subscreen, and at the bottom
total elapsed time and distance (nm).

Press **GPS** once to start the helm timer. It **buzzes twice at 2:00 left**, and at 0:00 it **starts the next
period by itself** (silent), so you don't have to press anything every 20 minutes. Press GPS again to stop it.

"Alarms: off" silences all buzzes and tones in both modes.

## Changes from upstream Oct 2025

| Change | Why |
|---|---|
| New name and app id | Installs alongside the store app |
| Buzz pattern replaced (Standard/Dynamic and the "Configure Mode" menu removed) | Clearer minute counts, silent gun |
| FC Cruise mode with repeating helm timer | Helm changes when cruising |
| Menu built in code, shows alarm state, one-step mode switch | Fewer presses, no hidden state |
| Null-safe GPS handling | Upstream crash fix (no speed/heading → app crash) |
| Race-clock formatting accepts any number type | Upstream crash fix `289c0d1` |
| START screen always clears after 5 s | Upstream fix `3946396` (stuck START with alarms off) |
| Ring countdown graphic instead of polygon pie | Upstream `72ed193`; old pie had a fenix-3 hard-coded size |
| Buzz patterns built once (`Buzzer.mc`) | Upstream `72ed193` memory fix |
| All timers stopped on exit; null checks | Upstream robustness fixes |
| Picker clamps out-of-range values | Prevents a picker crash if a setting is out of range |
| Removed broken `ModeMenuDelegate.mc` | Contained a syntax error (stray `'`) |
| Exact 62×62 launcher icon for Instinct 2X | No icon-scaling warning |

## Source map

| File | Role |
|---|---|
| `source/SailingApp.mc` | Settings, GPS, auto-start recording, mode, routes button actions |
| `source/SailingView.mc` | Draws Waiting-for-GPS / countdown ring / START / Race / FC Cruise screens |
| `source/CountDown.mc` | Race countdown, buzz schedule, sync, gun |
| `source/HelmTimer.mc` | FC Cruise repeating helm timer |
| `source/Buzzer.mc` | Shared vibrate and tone patterns (respects Alarms) |
| `source/SailingDelegate.mc` | Buttons and the main menu |
| `source/SailingMenuDelegate.mc` | Menu actions |
| `source/ExitMenuDelegate.mc` | Save / Discard / Resume |
| `source/TimePicker*.mc`, `TimeFactory.mc` | Minute picker (race countdown or helm period) |
| `resources/properties.xml` | Saved settings: `time`, `alarms`, `helmTime` |
