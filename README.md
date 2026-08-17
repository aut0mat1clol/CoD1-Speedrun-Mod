# CoD1 All-in-One Speedrun Mod 

Speedrun toolkit for **Call of Duty (2003), single player, patch 1.3**.
Level + full-game timers matching the speedrun.com autosplitter, a
millisecond speedometer, per-level PBs and an in-game settings panel.

This repo holds the **sources only** — GSC scripts, UI menus and configs.

---

## Features

| | |
|---|---|
| **Level timer (L)** | starts at the level-start autosave, counts down through the intro (`-2.8 → 0.0`) |
| **Full-game timer (FG)** | `H:MM:SS.mmm`, survives quickloads, final split on the berlin cinematic |
| **Timing rule** | matches LiveSplit *Game Time* with the `yf5y2.asl` autosplitter: loads and briefing maps excluded, pauses and death screens counted |
| **Speedometer** | 0.001 u/s precision, colour-coded, rolling 5 s average |
| **Level PBs** | per-level records with delta, plus a full-run PB |
| **Run splits** | live table of the current run |
| **Settings panel** | Options → Speedrun Mod → Settings |
| **Anti-cheese** | a level loaded with `map`/`devmap`, or left before finishing, is not banked and never becomes a PB |

Measured against LiveSplit over a full 8-map segment: **0.065 s total drift**,
no systematic sign — the remainder is rounding in the LiveSplit table plus the
50 ms server tick.

---

## Repo layout

```
src/maps/speedrun/_main.gsc   the entire mod (init, timers, HUD, PB, splits)
src/maps/_load.gsc            stock 1.3 + one hook line
src/maps/berlin.gsc           stock 1.3 + final-split hook
src/maps/_tankdrive.gsc       stock 1.3 + one hudelem sort fix
src/ui/*.menu, menus.txt      settings / PB / run-splits / delete pages
CHANGELOG.md                  what changed and why
```

### Stock files

`_load.gsc`, `berlin.gsc` and `_tankdrive.gsc` are **stock 1.3 scripts** with
minimal edits, all marked `// [SR]`:

* `_load.gsc:3` — `thread maps\speedrun\_main::init();` — the entry point;
* `berlin.gsc` — sets `rt_end_frozen` 0.6 s after `cinematic()`, freezing the
  run on the first frame of the end video;
* `_tankdrive.gsc` — raises one hudelem's `sort` so the tank HUD frame keeps
  drawing above its fill when extra script elements exist.

Two mods that both replace `_load.gsc` are incompatible — the pk3 loaded last
(alphabetically) wins.

---

## Building the pk3

A pk3 is a plain zip. Pack the **contents** of `src/` (not the folder itself):

```
maps/...
ui/...
```

Name it so it sorts last, e.g. `z_aio_il_timer.pk3`, and drop it into `main\`.

> **Paths inside the archive must use forward slashes.** Windows' built-in
> "Send to → Compressed folder" and `Compress-Archive` write backslashes; the
> archive opens fine everywhere but the engine will not find the scripts, and
> the mod silently does nothing. 7-Zip and `zip` are safe.

Optionally add `sr_pb.cfg` / `sr_settings.cfg` to `main\` as well (see below).

---

## Native bridge (optional)

The pure-GSC build works on a stock exe. A patched `CoDSP.exe` adds:

* `rt_velx10` — exact engine speed ×1000 (0.001 u/s readout);
* `rt_wallms` — `GetTickCount` wall clock;
* `rt_aslms` / `rt_asllatch` — a timer that only advances while the engine
  accepts input, i.e. the same rule the ASL load remover applies;
* archived declarations for every `sr_*` setting and every `pb_*`/`pbs_*`
  record, so settings and PBs persist without any `exec`.

Without it the mod falls back to the level clock: timing still works, the
speedometer drops to tenths, and settings need `exec sr_settings.cfg` once.

No game binary is distributed. **`tools/patch_exe.ps1` applies the patch to
your own stock 1.3 exe** — the script carries only the mod's code cave
(13 blocks, 2834 bytes) as data:

```
powershell -ExecutionPolicy Bypass -File tools\patch_exe.ps1 -GamePath "C:\path\to\game"
powershell -ExecutionPolicy Bypass -File tools\patch_exe.ps1 -GamePath "..." -Revert
```

Fail-closed: the exe's MD5 is checked before writing (stock 1.3 only —
modified/no-CD exes are refused untouched), a backup (`CoDSP.exe.sr_backup`)
is created automatically, and the result is verified after writing.
MD5: stock `8E1D57D69705485D8D641CCC636DAE6B` →
patched `C00B045D5131EB4ACB682FAFAEA439C1`.

---

## Settings

| Cvar | Default | Meaning |
|---|---|---|
| `sr_speedo` | 1 | speedometer |
| `sr_spd_avg` | 1 | rolling 5 s average |
| `sr_igt` | 1 | master switch for both timer rows |
| `sr_show_l` | 1 | LEVEL row |
| `sr_show_fg` | 1 | FULL GAME row |
| `sr_ilmode` | 0 | level timer only; nothing is banked into the run |
| `sr_tmr_dec` | 3 | timer digits: 1=tenths, 2=hundredths, 3=ms |
| `sr_spd_dec` | 3 | speedometer digits (0–3) |
| `sr_lvl_start` | 1 | 1 = L starts at the level autosave |
| `sr_tail` | 360 | per-map tail correction, ms |
| `sr_debug` | 0 | verbose `[SR]` prints |
| `sr_firstmap` | training | map a run starts on |

Fine tuning, rarely touched: `sr_spd_raw`, `sr_velprec`, `sr_lvl_pre`,
`sr_spd_hyst`.

Console latches — set to `1`, the mod acts and clears them:
`run_show`, `pb_show`, `pb_wipe`, `rt_cmd_mreset`.

### Naming

`sr_` is **settings only** — typing `sr_` in the console lists exactly the
options above and nothing else. Everything internal lives under `rt_`
(run-time): engine bridges (`rt_velx10`, `rt_wallms`, `rt_aslms`,
`rt_asllatch`), run bookkeeping (`rt_run_total`, `rt_lat_prev`, `rt_norun`,
`rt_rta`) and scratch buffers. Do not set those by hand.

Upgrading from ≤ 0.18.x leaves the old internal names in `config.cfg`, and the
engine recreates them at every start, so they keep appearing in autocomplete.
CoD1 has no `unset`, so the only real fix is deleting those lines from
`main\config.cfg` with the game closed — see `configs/sr_cleanup.cfg`.

---

## GSC notes (CoD1 quirks)

Things this engine will not let you do — each one cost a debugging session:

1. **No `int()` / `floor()`.** Round through the cvar channel: write the scaled
   float, read it back with `getcvarint` (string parsing truncates).
2. **Never `!` an undefined variable** — `cannot cast undefined to bool`. Use
   `!isdefined(level.x)`.
3. **No unary minus on variables.** Write `(0 - x)`.
4. **Dynamic HUD text is impossible.** `setText` takes only static localized
   strings (`&"..."`); runtime strings throw `cannot cast string to istring`.
   Numbers go through `setValue`, so digits are drawn as separate elements.
5. **Loop ceiling is `wait .05`** — 20 server frames per second.
6. **Savegames restore script state**, including thread locals. A script cannot
   detect its own rollback by comparing two of its own variables; mirror the
   value into a cvar, because cvars are not rolled back.
7. **Briefing maps do not run `maps\_load::main()`**, so the mod never sees
   them — they break any chain that assumes every map runs `init()`.

---

## Chat output

During a run the mod only prints what you need:

```
[SR] MAP TIME 02:28.603 | RUN TOTAL 0:27:36.403
[SR] NEW LEVEL PB: 02:28.603!
[SR] RUN END! FINAL TIME 0:28:57.405 - gg!
```

plus whatever a command returns. Everything else — resets, skipped maps,
pause/save accounting, the startup banner — is diagnostic and appears only
with `sr_debug 1`.

## Credits

Timing rules follow the community autosplitter `yf5y2.asl` used on
speedrun.com. Stock scripts © Infinity Ward.
