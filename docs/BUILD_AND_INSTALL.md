# Build, test and install Sailing JN

**Short answer:** you don't need the Connect IQ Store. You build the app on your computer,
try it in Garmin's free watch simulator, then copy one file to the watch over USB.

> This code has been **syntax-checked but not yet compiled**. The cloud environment
> it was written in can't download Garmin's SDK. If the first build shows an error, copy the
> error text back to Claude and it will be fixed.

## 1. One-time setup (about 20 min)

1. Install **VS Code**: <https://code.visualstudio.com>.
2. Install the **Connect IQ SDK Manager**:
   <https://developer.garmin.com/connect-iq/sdk/>. Open it, sign in with your Garmin account,
   download the **latest SDK** (and make it the current one), then on the **Devices** tab download **Instinct 2X Solar**.
3. In VS Code, install the extension **"Monkey C"** (publisher: Garmin).
4. VS Code → Command Palette (Cmd/Ctrl + Shift + P) → **"Monkey C: Generate a Developer Key"**.
   Save it somewhere safe **outside** the project folder. Every build is signed with it.
5. Command Palette → **"Monkey C: Verify Installation"**.

## 2. Get the code

```
git clone https://github.com/jny8630/connectiq-sailing.git
cd connectiq-sailing
git checkout ccr-72335603-8i9sgs
```
(Or on GitHub: switch to that branch → **Code → Download ZIP**.) Open the folder in VS Code.

## 3. Test in the simulator

Command Palette → **"Monkey C: Run"** → pick **instinct2x**. The simulator opens with clickable buttons
(GPS = top right, BACK = bottom right, UP/DOWN = left, hold UP = Menu).

The app waits for GPS. Use the simulator's **Simulation** menu to give it a GPS position or quality,
or to play back a GPX/FIT track for moving speed and heading. Then check:

- [ ] "Waiting for GPS signal" disappears once GPS is usable. Recording starts **without** pressing anything.
- [ ] Race screen: time of day, speed, heading in the subscreen, and nothing overlapping.
- [ ] **GPS** starts the countdown (shows 4:59 right away. That's expected, it's the original timing).
- [ ] Buzzes: 4:00 ×4, 3:00 ×3, 2:00 ×2, 1:00 ×1, 0:30 ×3, 0:20 ×2, 0:10 ×1. Gun silent, START for 5 s,
      then the race clock appears. (The simulator shows or plays tones and vibrations. Set the countdown
      to 1 min in the menu to test the last part quickly.)
- [ ] UP / DOWN during the countdown jump a minute and give one short vibration.
- [ ] **GPS** during the countdown aborts it. GPS again restarts from the full time.
- [ ] Hold UP → menu shows "Alarms: on". Selecting it toggles, and the label changes the next time you open the menu.
- [ ] Menu → **FC Cruise mode**: "FC CRUISE" screen with helm "--:--", total time and nm at the bottom.
- [ ] Menu → Set helm timer → **3** (quick test) → GPS: counts down, **2 buzzes at 2:00**, at 0:00 restarts at 3:00 by itself.
- [ ] Menu → **Race mode**: helm timer stops, race screen is back.
- [ ] BACK → Exit menu → Save closes the app (the activity is saved).

## 4. Put it on the watch (sideload over USB)

1. Command Palette → **"Monkey C: Build for Device"** → **instinct2x** → choose an output folder.
   You get a file like `connectiq-sailing.prg`.
2. Connect the Instinct 2X to the computer with its USB cable.
   - **Windows:** it appears in File Explorer as "Instinct 2X".
   - **Mac:** install **OpenMTP** (free) or Android File Transfer. Garmin watches use MTP, so the watch
     doesn't show up in Finder.
3. Copy the `.prg` into **`GARMIN/APPS/`** on the watch. You can rename it to `SailingJN.prg`.
4. Unplug. On the watch, open the activity/apps list: **Sailing JN** appears next to the store "Sailing" app.

**To update:** build again and overwrite the same `.prg`. **To remove:** delete it from `GARMIN/APPS/`.

Sideloaded apps can't be configured from the Garmin Connect phone app. That's fine here:
everything (countdown length, helm timer, alarms, mode) is in the watch menu.

## 5. Optional: install through the Connect IQ app (private beta)

If you'd rather install from your phone, or want the phone settings screen:
Command Palette → **"Monkey C: Export Project"** gives an `.iq` file. Upload it at
<https://apps.garmin.com/developer> as a **beta app**. A beta is visible only to your account,
and you install it through the Connect IQ phone app like any store app. No public listing or review is needed.
