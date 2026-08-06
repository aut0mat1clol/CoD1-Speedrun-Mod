# CoD1 Speedrun — All-in-One mod (1.0.1)

Speedrun toolkit for **Call of Duty (2003), single-player campaign, patch 1.3**
(Windows, iw3xo-style): HUD speedometer, run timer (`H:MM:SS.mmm`) that
survives quickloads (archived-cvar channel, pure GSC), automatic map splits,
final split on berlin; **pause menu time counts** (RTA, dll wall-clock).


## Two layers (important for verification)

1. **Clean pk3 (`z_sr_speedrun_loctext.pk3`)** — ZERO game-file changes.
   The total survives quickloads via the archived channel (`rt_cont_real`,
   CVAR_ARCHIVE) plus script bookkeeping. The speedometer shows 0 in this
   mode (it is patch-only).
2. **Optional patch (`install.ps1 -Patch`)** — enabled explicitly, removed
   by `install.ps1 -Revert`, automatic `.sr_backup`, expected dll md5
   `AB3FF2DFBF7892E6DBEBC4A23E1615B4` (the dll patch): exact speed from
   `ps.velocity` (speedometer) + a real wall clock for counting pause-menu
   time (RTA: menu time counts, loads do not). F9 survival works fine
   without the patch (archived channel). Treat the patch as
   **practice-only** until the speedrun.com moderators' verdict.
   Without the patch, `rt_dll_api` = 0.

## Installation

1. PowerShell in the project folder:
   - clean variant: `powershell -ExecutionPolicy Bypass -File install.ps1`
   - with native layer: `powershell -ExecutionPolicy Bypass -File install.ps1 -Patch`
2. Launch the game: `CoDSP.exe +set developer 1`.
3. The mod is quiet by default (`sr_debug 0`): only Reset / Map Time /
   Run End print. Sanity check: console `set sr_debug 1` → after map load
   you should see `Speedrun mod loaded (1.0.1)` + `pause clock ON`.

## Features

| Feature | How it works |
|---|---|
| Run timer (HUD, top-right, `H:MM:SS.mmm`) | scripted, survives F9 (archived channel `rt_cont_real`) |
| Auto-splits | `MAP TIME | RUN TOTAL` printed on every map change |
| F9 rollback protection | same-map trap: gap > 750 ms → total keeps running |
| Final split | freeze when the `cod_end.roq` video starts (hook in `maps/berlin.gsc`), `RUN END! FINAL TIME` |
| Credits map | timer stays pinned at the final time |
| Speedometer (HUD, center) | exact native speed (patch); color-coded: white < 180, green 180+, yellow 230+, red 275+; decimals `sr_spd_dec` 0–3 |

## Console controls (~ key)

- Full run reset:
  `set rt_run_total 0; set rt_spd_max 0; set rt_end_frozen 0; set rt_cont_real 0; set rt_cmd_mreset 1`
- Toggles: `set sr_speedo 0|1`, `set sr_igt 0|1`;
  speedometer decimals: `set sr_spd_dec 0|1|2|3`
- FPS lock: `set com_maxfps 125` (or 85/250/333 — lock it for the run)
- Timer smoothness: script-driven numbers only update on server frames
  (~50 ms) — per-1-ms updates are impossible in CoD1, and this binary has
  no `sv_fps` cvar (verified in the exe strings). The `mmm` digits are
  real; the step is one frame.

## Cvars

**Settings (`sr_`):** `sr_speedo`, `sr_igt`, `sr_spd_dec`, `sr_debug`,
`sr_maxwin` (max-speed auto-reset window, seconds), `sr_firstmap`
(New Game auto-reset map).
**Data (`rt_`, do not touch):** `rt_spd`, `rt_spd_max`, `rt_run_total`,
`rt_ms_cur`, `rt_igt_m/s/ds`, `rt_cont_real`, `rt_cont_wall`,
`rt_last_map`, `rt_end_frozen`, `rt_dt`.
**Internal (`rt_`):** `rt_dll_api` (set only by the patcher),
`rt_cmd_mreset`.

## Sharing the mod (recipient needs no PowerShell)

`powershell -ExecutionPolicy Bypass -File tools\package_release.ps1` builds
one full "unzip and drop into the game folder" archive —
`cod1_speedrun_1_0_1_full.zip`: the mod + exact speedometer (`gamex86.dll`
goes to the game root, replacing the original — keep your backup).
An INSTALL.txt for the recipient is included. Requires `install.ps1 -Patch`
to have been run on your machine first.

## What the gamex86.dll patch does

(md5 `AB3FF2DFBF7892E6DBEBC4A23E1615B4`, built from the user's own stock dll
by `install.ps1`): two minimal additive overloads — an exact speedometer
readout and a wall clock (GetTickCount) used to count pause-menu time.
Stock behavior of the patched function is fully preserved — none of the 144
stock `.gsc` scripts call it (verified).

The original `gamex86.dll` is **not** distributed: the installer patches
your own copy (automatic `.sr_backup`). The mod logic is otherwise pure GSC;
the only stock scripts shipped are `_load.gsc` (one-line init hook),
`_tankdrive.gsc` (cosmetic HUD sort fix) and `berlin.gsc` (final-split
anchor) — all diffs are single-line and documented in `patches/HOOK_load_gsc.md`.

## Project layout

    cod1-speedrun/
    ├── install.ps1               # single installer: pk3 build + _load.gsc hook + dll patch (-Patch/-Revert)
    ├── configs/autoexec.cfg      # seta rt_dll_api/rt_cont_*
    ├── src_loctext/              # THE only build (loctext)
    │   └── maps/
    │       ├── speedrun/_main.gsc  # mod core
    │       ├── _tankdrive.gsc      # stock + tankhud2.sort = 1000 (healthbar frame fix)
    │       └── berlin.gsc          # stock berlin + final-split anchor
    ├── tools/get_hashes.ps1      # md5 of game binaries (diagnostics)
    ├── tools/package_release.ps1 # builds the shareable drop-in zip
    └── patches/HOOK_load_gsc.md  # how the hook works (for the moderator)

