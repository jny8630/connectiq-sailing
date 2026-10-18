# Sailing JN code review

> **Decisions (2026-10-18):** Option A chosen. Sailing JN is now built on OLD (`b769266`) plus the
> upstream fixes for R4, R5, R10 and R14. R2 (gun ~1 s early) is kept **on purpose**: better late than over early.
> R3 (GPS aborts the countdown) is kept, because a quick abort/restart is needed when the committee restarts.
> R8 is fixed (menu shows "Alarms: on/off"). R9 is replaced by a new buzz pattern. FC Cruise mode was added.
> See [../CUSTOMISATION.md](../CUSTOMISATION.md).

Reviewed 2026-10-18. Two versions were compared:

| Name used below | Commit | Date | What it is |
|---|---|---|---|
| **OLD** | `b769266` | 2025-10-06 | Upstream `master` a year ago, i.e. the simple app most people knew |
| **NEW** | `22721b0` | 2026-09-02 | Upstream `master` today, the version this fork was taken from |

Everything between them landed in roughly 20 commits from July to Sept 2026 (see "Timeline").
Both versions are in this repo's git history, so **we can go back to OLD without asking the publisher**.

No build was run for this review: the Connect IQ SDK isn't available in this environment.
Anything marked *verify* should be checked in the simulator or on the watch.

---

## 1. What the app does

A full-screen watch app for sailing. It:

1. Turns on GPS and shows **speed in knots**, **heading** (GPS course over ground) and the **time of day**.
2. **Records a Garmin "Sailing" activity** (track, speed and distance) that syncs to Garmin Connect.
3. Runs a **race start countdown** (default 5 min) with beeps and vibrations, lets you **sync**
   to the committee's signals with Up/Down, and at the gun shows "START", **adds a lap** and
   then shows **elapsed race time**.

NEW adds: a Cruise mode with no countdown, manual Start/Pause, a pause menu, manual laps on BACK,
and two extra data pages (lap and totals).

---

## 2. Software components

```
SailingApp.mc ── the "brain": settings, GPS on/off, activity recording, owns CountDown
   │
   ├── SailingView.mc ── draws the screen (GPS screen / countdown ring / START / data pages)
   │        ▲ position updates every second (speed, heading, GPS quality)
   │
   ├── CountDown.mc ── 1-second countdown timer, beep and vibrate patterns, gun → lap and race clock
   │
   └── SailingDelegate.mc ── what each BUTTON does on the main screen
            ├── hold UP → main menu → SailingMenuDelegate.mc
            │                     ├── Set timer → TimePicker.mc + TimeFactory.mc + TimePickerDelegate.mc
            │                     ├── Countdown signals → ModeMenuDelegate.mc
            │                     └── Sailing mode → SailingModeMenuDelegate.mc   (NEW only)
            ├── BACK → Exit menu → ExitMenuDelegate.mc
            └── START (Cruise) → Paused menu → PauseMenuDelegate.mc               (NEW only)

MessageAlert.mc        – small "Need Race mode…" popup                           (NEW only)
RaceTimeDebugTests.mc  – unit tests only, not part of the watch app              (NEW only)
resources/resources.xml   – fixed menus (labels and order)
resources/properties.xml  – saved settings and the phone-app settings screen
manifest.xml / monkey.jungle – app id, name, supported watches, icons
```

| File | Lines OLD → NEW | Role |
|---|---|---|
| `SailingApp.mc` | 191 → 355 | Settings get/set, GPS start/stop, activity start/pause/save/discard, lap tracking |
| `SailingView.mc` | 340 → 582 | All drawing, GPS-to-text conversion (knots, compass point, degrees) |
| `CountDown.mc` | 225 → 309 | Countdown state, beep schedules (Standard / Dynamic), gun, ±1 min sync |
| `SailingDelegate.mc` | 53 → 99 | Button handling on the main screen; builds the main menu (NEW) |
| `SailingMenuDelegate.mc` | 29 → 51 | Main menu actions |
| `ExitMenuDelegate.mc` | 18 → 19 | Save / Discard / Resume |
| `ModeMenuDelegate.mc` | 22 → 18 | Standard / Dynamic beep pattern |
| `SailingModeMenuDelegate.mc` | — → 17 | Race / Cruise |
| `PauseMenuDelegate.mc` | — → 24 | Resume / Lap / Save / Discard |
| `TimePicker*.mc`, `TimeFactory.mc` | unchanged | 0–30 min countdown length picker |
| `MessageAlert.mc` | — → 46 | Popup text screen |

---

## 3. Feature inventory: OLD vs NEW

Fill in the **Decision** column (Keep / Disable / Change / Replace) to tell us what to change.

| # | Feature | OLD (Oct 2025) | NEW (Sept 2026) | Where | Decision |
|---|---|---|---|---|---|
| F1 | Start of activity recording | **Automatic** once GPS reaches "usable" quality | **Manual**: GPS screen with quality bar and "Press START", any GPS quality accepted | `SailingApp.startActivityRecording` (OLD) / `startRecording` (NEW), `SailingView.drawGpsAcquisition` | |
| F2 | Speed (knots, 0.1) | ✔ | ✔ (handles missing GPS data safely) | `SailingView.onPosition` | |
| F3 | Heading | ✔ compass point plus degrees; Instinct: degrees in subscreen | same | `SailingView.onPosition/headingToStr` | |
| F4 | Time of day | ✔ | ✔ | `drawSpeedPage` | |
| F5 | Race countdown, Start = start/stop | ✔ always | ✔ only in Race mode **while recording** | `SailingDelegate.onSelect`, `CountDown` | |
| F6 | Countdown length | Menu picker 0–30 min, phone setting | same (hidden in Cruise) | `TimePicker*`, `properties.xml` | |
| F7 | Sync ±1 min (Up/Down during countdown) | ✔ | ✔ | `CountDown.fixTimeUp/Down` | |
| F8 | Beep patterns Standard / Dynamic | ✔ ("Configure Mode") | ✔ ("Countdown signals", hidden in Cruise) | `CountDown.timerCallback` | |
| F9 | Alarms on/off | "Toggle alarms", no on-screen state | same | `SailingMenuDelegate` | |
| F10 | Gun: "START" screen, long buzz ×10, auto-lap, race clock | ✔ | ✔ | `CountDown.finishCountdown/finalRing` | |
| F11 | Elapsed race time after gun | ✔ under speed | ✔ | `drawSpeedPage` | |
| F12 | Countdown graphic | Filled wedge "pie" | Thin ring (arc) | `buildProgress` (OLD) / `drawCountdownRing` (NEW) | |
| F13 | BACK button | Always opens Exit menu | **Marks a lap while recording**; Exit menu only when paused or not started | `SailingDelegate.onBack/onKey` | |
| F14 | Exit menu Save / Discard / Resume | ✔ (Resume just closes the menu) | ✔ | `ExitMenuDelegate` | |
| F15 | Cruise mode (no countdown) | — | ✔ menu and phone setting; forced to Race on first launch | `SailingModeMenuDelegate`, `SailingApp.onStart` | |
| F16 | Pause / Resume, Paused menu | — | ✔ **Cruise mode only** | `SailingDelegate.onSelect`, `PauseMenuDelegate` | |
| F17 | Data pages (Up/Down when no countdown) | — single screen | 3 pages: Speed · Lap (time, nm, km) · Total (time, nm, km) | `SailingView.drawLapPage/drawTotalPage` | |
| F18 | Mode label on screen ("RACE"/"CRUISE") | — | ✔ | `drawSpeedPage` | |
| F19 | Main menu items depend on mode | — fixed list | ✔ built in code | `SailingDelegate.buildMainMenu` | |
| F20 | "Need Race mode and activity started" popup | — | ✔ | `MessageAlert.mc` | |
| F21 | Screen refresh | Only on GPS update or countdown tick | Every second (1 Hz timer) | `SailingView.startUiTimer` | |

---

## 4. Button map: OLD vs NEW (Instinct 2X)

GPS = Start (top right), BACK (bottom right), UP / DOWN (left), hold UP = Menu.
The CTRL/light button can't be used by apps.

**OLD**

| Button | Any time | During countdown |
|---|---|---|
| GPS | Start countdown | Cancel countdown |
| BACK | Exit menu: Save / Discard / Resume | Exit menu |
| UP / DOWN | nothing | +1 min / −1 min (sync) |
| hold UP | Menu: Start timer · Set timer · Toggle alarms · Configure Mode | same |

**NEW**

| Button | GPS screen (not started) | Recording, Race | Recording, Cruise | Paused |
|---|---|---|---|---|
| GPS | Start recording | Start / cancel countdown | Pause → Paused menu | Resume |
| BACK | Exit menu | **Lap** | **Lap** | Exit menu |
| UP / DOWN | — | Change page (countdown: ±1 min) | Change page | Change page |
| hold UP | Menu | Menu | Menu (fewer items) | Menu |

---

## 5. Is it working correctly? Findings

Ranked by how much they matter on the water. "Both" means OLD and NEW both have it.

### Serious

**R1. NEW: in Race mode there is no button route to stop or save the activity.** *(NEW only, certain)*
While recording in Race mode, GPS only starts or cancels the countdown and BACK only marks a lap.
The Exit menu appears only when you're paused or not started, and pausing exists only in Cruise mode. The only way out is
Menu → Sailing mode → Cruise → GPS (pause) → Save. Switching to Cruise also **wipes the race clock**.
OLD didn't have this problem because BACK always opened Save/Discard.

**R2. Both: the countdown appears to run about 1 second short (gun early).** *(Both, high confidence by code reading, verify with a stopwatch)*
`CountDown.startTimer` takes one second off the moment you press Start (`updateTimer()` runs immediately), and
`timerCallback` fires the gun when `secLeft` reaches 1, not 0. So on a 5:00 countdown the gun fires at 4:59,
and the minute and 30-second beeps are also 1 s early. One-line fix once confirmed.

**R3. Both: one accidental press of GPS during the start sequence cancels the countdown, with no confirmation.**
Pressing GPS again restarts from the **full** length (e.g. 5:00), not from where it was. In NEW, a GPS press
at any point after the gun also starts a brand-new countdown. When that one ends it resets the race clock and adds a lap.

**R4. OLD: with alarms turned off, the screen stays stuck on "START" after the gun.** *(OLD only, certain)*
`finalRing` returns early without clearing `timerComplete` or stopping its timer, so speed and the race clock
never come back. Upstream fixed it in PR #20 (`3946396`, merged July 2026). It must be ported if we go back to OLD.

**R5. OLD: it can crash when the GPS reports no speed or heading.** *(OLD only, likely)*
`onPosition` multiplies `info.speed` and `info.heading` without checking for "no value", which crashes the app
on the watch (it closes). NEW checks for this. Upstream also fixed a separate crash in the race-clock
formatting (`289c0d1`, Aug 2026, "race-time crash when formatting non-integer durations"). OLD has that code too.

### Moderate

**R6. Both: sync is only accurate to about ±1 s, and the countdown can drift.** The countdown counts timer
ticks instead of reading the clock. Pressing Up/Down snaps the remaining seconds to a minute but doesn't
re-align the tick, so the error can be up to 1 s. Ticks can also arrive late while the watch beeps or vibrates, and the
error builds up over a long countdown. A clock-based countdown would fix both.

**R7. Both: Down at an exact minute does nothing.** −1 min rounds *down* to the minute: at 4:00 it stays 4:00
(it still buzzes). Up at 4:00 goes to 5:00. Behaviour is uneven; "snap to nearest minute" is the usual sync convention.

**R8. Both: no way to see whether alarms are on.** "Toggle alarms" flips the setting silently, and nothing on screen
shows its state. It's easy to start a race with alarms off without knowing.

**R9. Both: some beep signals can't be told apart.**
- Standard: on the minute the code calls the buzzer twice in the same instant. The second call probably overrides
  the first, so a minute likely feels the same as a 30-second mark (*verify on watch*).
- Dynamic: "buzz N times for N minutes" is capped at 4, so 9…5 minutes all buzz 4 times.
  At 50 s and 40 s, NEW also buzzes 4 times for both. OLD tried 4 then 1 more, which probably got overridden too.

**R10. OLD: the countdown "pie" graphic has a hard-coded screen size.** `buildProgress` uses `109`
(the centre of the 218-px fenix 3 screen) for one segment. On the 176-px Instinct, the wedge is drawn wrongly
from about 7 to 15 s into each minute. NEW replaced it with a ring.

### Minor / cosmetic

- **R11. Instinct layout (both):** the elapsed race time is placed with generic maths that likely
  overlaps the large speed digits on the Instinct (*verify*). NEW's lap/total pages and GPS screen have no
  Instinct-specific layout. Colours used: green, orange, red, yellow, dark grey. On the two-colour screen the
  **dark-grey page dots and GPS-bar background may disappear** (*verify*).
- **R12. Heading is GPS course over ground (both)**, not the compass. When slow or drifting it jumps around.
  That's normal for GPS, but worth knowing.
- **R13. Lap and total times in NEW use *elapsed* time**, which includes paused time.
- **R14. OLD: ModeMenuDelegate has a stray `'`** after `{` (from 2024 to July 2026). Upstream shipped
  builds with it, so the compiler accepts it, but it should be removed.
- **R15. NEW: switching to Cruise mid-race erases the race clock** (it's the only stop route, see R1).

---

## 6. Two ways forward

**Option A: base on OLD, port the essential fixes.** *(Recommended if the old behaviour suits you better.)*
1. Start a branch from `b769266`; re-apply the Sailing JN name and app ID.
2. Port fixes: R4 (alarms-off START), R5 (null-safe GPS plus the race-clock crash), and the pre-built
   buzz profiles from NEW (fewer memory allocations per beep). Optionally the R10 ring graphic.
3. Fix R2 (1 s early) and anything else you choose from section 5.
4. Then add only the NEW features you actually want (e.g. lap/total pages, manual lap).

**Option B: keep NEW, disable or change features.** E.g. remove Cruise mode and the pause menu, restore BACK → Exit menu,
re-enable automatic recording start, keep the pages. More code to strip out, and the NEW-only
interactions (R1, R3, R15) need careful work.

OLD is about 1,030 lines and NEW about 1,900. If most of what you liked is in OLD, A is less work and less risk.

---

## 7. Timeline of upstream changes (OLD → NEW)

| Date | Commit | Change |
|---|---|---|
| 2025-10-06 | `b769266` | **OLD**: layout fix for round screens (PR #19) |
| 2025-10-06 | `3946396` | Alarms-off START fix (PR #20, merged later) |
| 2026-07-18 | `6fe7486` | **Cruise mode** added |
| 2026-07-18 | `0ab4537` | More watches supported |
| 2026-07-18 | `45f1ad3` | **Pause menu, lap and totals pages, manual start**, BACK = lap |
| 2026-07-18 | `959d7d8` | Exact-size launcher icons |
| 2026-07-18 | `a2f2090` | Phone settings as choice lists |
| 2026-07-18 | `6098427` | 1 Hz screen refresh |
| 2026-08-03 | `72ed193` | Countdown out-of-memory fix (ring instead of pie, pre-built buzz profiles) |
| 2026-08-03 | `4fb6b3f` | Mode label on screen; Race-only menu items hidden in Cruise |
| 2026-08-03 | `c92091b` | "Need Race mode" warning popup |
| 2026-08-24 | `289c0d1` | Race-clock crash fix |
| 2026-09-02 | `1fd2b31` | Review fixes, "0.7-upd6" (**NEW**) |

To try either version in the simulator: `git checkout b769266` (OLD) or `git checkout 22721b0` (NEW).
