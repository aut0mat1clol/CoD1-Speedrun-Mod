# CoD1 Speedrun — All-in-One mod (1.0.2)

Speedrun toolkit for **Call of Duty (2003), single-player campaign, patch 1.3**
(Windows, iw3xo-style): HUD speedometer, run timer (`H:MM:SS.mmm`) that
survives quickloads, automatic map splits, final split on berlin; **pause menu
time counts** (RTA).

## Download & install (2 minutes)

1. Download **`cod1_speedrun_1_0_2_full.zip`** from the
   **[latest release](https://github.com/aut0mat1clol/CoD1-Speedrun-Mod/releases/latest)**.
2. Unzip into your game folder (the one containing `CoDSP.exe`):
   - contents of `main\` → into `main\` (the mod pk3 + `autoexec.cfg`)
   - `game_root\gamex86.dll` → into the game root, replacing the original.
     **Back up your original `gamex86.dll` first** (any copy of it is fine).
3. Launch the game: `CoDSP.exe +set developer 1`.
4. The mod is quiet by default (`sr_debug 0`): only Reset / Map Time / Run End
   print. Sanity check: `set sr_debug 1` in the console → after a map loads
   you should see `Speedrun mod loaded (1.0.2)` + `pause clock ON`.

**Uninstall**: delete the pk3 + `autoexec.cfg` from `main\`, restore your
original `gamex86.dll`. No other game files are touched.

## Features

| Feature | How it works |
|---|---|
| Run timer (HUD, top-right, `H:MM:SS.mmm`) | scripted, survives F9 quickloads (archived-cvar channel `rt_cont_real`) |
| Auto-splits | `MAP TIME | RUN TOTAL` printed on every map change |
| F9 rollback protection | same-map trap: gap > 750 ms → total keeps running |
| Final split on berlin | freezes on the first frame of the end video (`wait (0.6)` after `cinematic()`, hardcoded — identical for every runner) |
| Credits map | timer stays pinned at the final time |
| Speedometer (HUD, center) | exact native speed; color-coded: white < 180, green 180+, yellow 230+, red 275+; decimals via `sr_spd_dec` 0–3 |

Loads and pre-mission briefing screens are excluded automatically;
starting a New Game resets the run timer.

## Console controls (~ key)

- Full run reset:
  `set rt_run_total 0; set rt_spd_max 0; set rt_end_frozen 0; set rt_cont_real 0; set rt_cmd_mreset 1`
- Toggles: `set sr_speedo 0|1`, `set sr_igt 0|1`;
  speedometer decimals: `set sr_spd_dec 0|1|2|3`
- FPS lock: `set com_maxfps 125` (or 85/250/333 — lock it for the run)
- Timer smoothness: script-driven numbers only update on server frames
  (~50 ms) — per-1-ms updates are impossible in CoD1. The `mmm` digits are
  real; the step is one frame.

## Cvars

**Settings (`sr_`):** `sr_speedo`, `sr_igt`, `sr_spd_dec`, `sr_debug`,
`sr_firstmap`
(New Game auto-reset map).
**Data (`rt_`, do not touch):** `rt_spd`, `rt_spd_max`, `rt_run_total`,
`rt_ms_cur`, `rt_igt_m/s/ds`, `rt_cont_real`, `rt_cont_wall`,
`rt_last_map`, `rt_end_frozen`, `rt_dt`.
**Internal (`rt_`):** `rt_dll_api` (set automatically), `rt_cmd_mreset`.

## For moderators: what's actually changed

The timer core is **pure GSC**. The release replaces exactly three things:

- **`main\z_sr_speedrun_loctext.pk3`** — the mod scripts. Ships three stock
  scripts with single-line diffs, each documented: `maps/_load.gsc`
  (one-line init hook, see `patches/HOOK_load_gsc.md`),
  `maps/_tankdrive.gsc` (`tankhud2.sort = 1000` — cosmetic fix for the tank
  healthbar frame), `maps/berlin.gsc` (final-split anchor). No other stock
  scripts are modified or overridden.
- **`main\autoexec.cfg`** — initializes the mod's archived cvars
  (`rt_cont_real/rt_cont_wall/rt_dll_api`).
- **`gamex86.dll`** (md5 `AB3FF2DFBF7892E6DBEBC4A23E1615B4`) — a binary patch
  of the stock dll with two minimal additive overloads: an exact speedometer
  readout and a wall clock (GetTickCount) used for counting pause-menu time.
  Stock behavior of the patched function is fully preserved — none of the 144
  stock `.gsc` scripts call it (verified).

Keep a backup of your original `gamex86.dll` — it is the only stock file
the release overwrites.
