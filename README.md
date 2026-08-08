# CoD1 Speedrun — All-in-One mod

Speedrun toolkit for **Call of Duty (2003), single-player campaign, patch 1.3**
(Windows, iw3xo-style): HUD speedometer, run timer (`H:MM:SS.mmm`) running on
**real time with ~1 ms precision**, surviving quickloads, automatic map splits,
final split on berlin; **pause menu time counts** (RTA), briefing levels and
between-level gaps are fully excluded. Settings panel in the game's OPTIONS
menu.

## Download & install (2 minutes)

1. Download **`cod1_speedrun_*_full.zip`** from the
   **[latest release](https://github.com/aut0mat1clol/CoD1-Speedrun-Mod/releases/latest)**.
2. Unzip into your game folder (the one containing `CoDSP.exe`):
   - contents of `main\` → into `main\` (the mod pk3 + `autoexec.cfg`)
   - `game_root\gamex86.dll` → into the game root, replacing the original.
     **Back up your original `gamex86.dll` first** (any copy of it is fine).
3. Launch the game.
4. The mod is quiet by default (`sr_debug 0`): only Reset / Map Time / Run End
   print. Sanity check: `set sr_debug 1` in the console → after a map loads
   you should see `Speedrun mod loaded ("version")` + `pause clock ON`.

**Uninstall**: delete the pk3 + `autoexec.cfg` from `main\`, restore your
original `gamex86.dll`. No other game files are touched.

## Features

| Feature | How it works |
|---|---|
| Run timer (HUD, top-right, `H:MM:SS.mmm`) | real time at 1 ms resolution via the patched dll (`rt_dll_api >= 14`); survives F9 quickloads (archived-cvar channel `rt_cont_real`, re-syncs to the save moment) |
| Pause & menu counting (RTA) | speedrun.com ASL parity: ESC pauses, death screens and post-level menu/stats screens **count**; true load screens and the pre-mission briefing cradle are excluded |
| Auto-splits | `MAP TIME & RUN TOTAL` printed on every map change |
| F9 rollback protection | total rolls back to the moment the save was made |
| Final split on berlin | freezes on the first frame of the end video (`wait (0.6)` after `cinematic()`, hardcoded — identical for every runner); final time is real-clock exact (1 ms) |
| Credits map | timer stays pinned at the final time |
| Speedometer (HUD, center) | exact native speed; color-coded: white < 180, green 180+, yellow 230+, red 275+; decimals via `sr_spd_dec` 0–3 |
| Settings menu | OPTIONS → "Speedrun Mod / Settings" panel: speedometer, 5 s average, timers, decimals, debug, full run reset |

Loads and pre-mission briefing screens are excluded automatically; the six
briefing **maps** — `allied_start`, `ru_stalingrad`, `uk_6ab`, `uk_sas`,
`us_intro`, `us_mid` — are excluded entirely, so time between levels is
exactly 0; starting a New Game resets the run timer.

**LiveSplit parity.** Timing rules mirror the official speedrun.com
autosplitter (ASL) for CoD1: same exclusions, same inclusions, final split on
the berlin end cinematic. Measured residual offset vs LiveSplit "Game Time":
≈0.1–0.15 s per level, accumulated at each map boundary — the engine never
exposes the exact load-flag clear/spawn moment to GSC, so that boundary span
is unobservable from script (LiveSplit reads it from process memory
directly). For leaderboard submissions the LiveSplit timer remains the judge;
this mod gives 1 ms-true, self-consistent practice/split times.

## Console controls (~ key)

- Full run reset:
  `set rt_run_total 0; set rt_ms_cur 0; set rt_wtotal 0; set rt_wcur_int 0; set rt_spd_max 0; set rt_end_frozen 0; set rt_cont_real 0; set rt_cont_wall 0; set rt_cmd_mreset 1`
  (or use the Settings menu's **Reset Run** button)
- Toggles: `set sr_speedo 0|1`, `set sr_spd_avg 0|1`, `set sr_igt 0|1`;
  speedometer decimals: `set sr_spd_dec 0|1|2|3`
- FPS lock: `set com_maxfps 125` (or 85/250/333 — lock it for the run)
- Timer resolution: with the patched dll the run total is true real time
  at ~1 ms resolution (the HUD itself still repaints once per server frame,
  ~50 ms). Without the dll the timer falls back to the old frame-grid math.

## Settings menu persistence (one-time setup)

The engine only writes cvars created with the ARCHIVE flag to `config.cfg`.
To make menu changes stick between launches, run this **once** in the
console (`~`):

```
seta sr_speedo 1; seta sr_spd_avg 1; seta sr_igt 1; seta sr_spd_dec 1; seta sr_debug 0
```

These are just the starting defaults; any later change in the menu is saved
automatically. Repeat only if you wipe your `config.cfg`.

## Cvars

**Settings (`sr_`):** `sr_speedo`, `sr_spd_avg`, `sr_igt`, `sr_spd_dec`,
`sr_debug`, `sr_firstmap`
(New Game auto-reset map).

**Data (`rt_`, do not touch):** `rt_spd`, `rt_spd_max`, `rt_run_total`,
`rt_ms_cur`, `rt_wtotal`, `rt_wcur_int`, `rt_igt_m/s/ds`, `rt_cont_real`,
`rt_cont_wall`, `rt_last_map`, `rt_end_frozen`, `rt_dt`.

**Internal (`rt_`):** `rt_dll_api` (set automatically), `rt_cmd_mreset`.

## For moderators: what's actually changed

The timer core is **pure GSC**. The release replaces exactly three things:

- **`main\z_sr_speedrun_loctext.pk3`** — the mod scripts and the settings
  menu. Ships three stock scripts with single-line diffs, each documented:
  `maps/_load.gsc` (one-line init hook, see `patches/HOOK_load_gsc.md`),
  `maps/_tankdrive.gsc` (`tankhud2.sort = 1000` — cosmetic fix for the tank
  healthbar frame), `maps/berlin.gsc` (final-split anchor). Menu side:
  `ui/menus.txt` (+1 `loadMenu` line), `ui/options.menu` (+ a "Speedrun Mod /
  Settings" entry, see `patches/UI_menu.md`) and the new
  `ui/sr_settings.menu`. No other stock files are modified or overridden.
- **`main\autoexec.cfg`** — initializes the mod's archived cvars
  (`rt_cont_real/rt_cont_wall/rt_dll_api`).
- **`gamex86.dll`** (md5 `AB3FF2DFBF7892E6DBEBC4A23E1615B4`) — a binary patch
  of the stock dll with two minimal additive overloads: an exact speedometer
  readout and the real system clock (GetTickCount) — it drives both pause
  counting and the ~1 ms-resolution run total. Stock behavior of the
  patched function is fully preserved — none of the 144 stock `.gsc` scripts
  call it (verified).

Keep a backup of your original `gamex86.dll` — it is the only stock file
the release overwrites.
