# CoD1 Speedrun Mod — Patch Notes

Compiled from the commit history of
[aut0mat1clol/CoD1-Speedrun-Mod](https://github.com/aut0mat1clol/CoD1-Speedrun-Mod).

---

## 1.2.2 — 2026-08-17

*Double Berlin banking fix, Settings fix* (`5876bf3`)

**Fixed**
- **Berlin was added to the full-game total twice.** The final split banked
  berlin itself but left the RTA mirror (`rt_rta_last`) alive, so arriving on
  credits banked it a second time — credits is not in the story list, so the
  order check waved it through. Fixed with three independent layers: the final
  split zeroes every mirror, the RTA loop stops once `rt_end_frozen` is set,
  and an arrival with the run already over banks nothing.
- **Menu pages stacked on top of each other.** Opening Level PBs / Run Splits /
  Delete Runs and then clicking a stock Options section (without ESC) drew both
  pages at once. Every right-hand Options button and `options_menu`'s `onClose`
  now close the mod's sub-pages too.
- A bogus full-run PB could be saved by typing `map berlin` right after
  launching the game (empty previous-map cvar looked like "first map of the
  session"). The final split now also requires the first map's split to exist
  in the current run table.
- PB records (`pb_*`/`pbs_*`) are declared as ARCHIVE cvars by the patched exe
  (v18), so they survive a restart without `exec sr_pb.cfg`; the cfg stays as a
  fallback for a stock exe. PB page hint updated accordingly.
- Cleaned up the stale multi-version comment walls in `_main.gsc`.

---

## 1.2 — 2026-08-16

*Level PBs, better timing, Level and Run's menus* (`0ea17d6`) — first tagged
release; the largest update so far (+3553 / −1100 lines).

**Added**
- **Per-level PBs** with chat compare (`NEW LEVEL PB` / `PB ... delta`) and a
  full-run PB taken at the berlin final split.
- **Level timer (L row)** next to the full-game row: starts at the level-start
  autosave, counts down through the intro (`-2.8 → 0.0`), survives quickloads.
- **New menu pages:** Level PBs (story order), Run Splits (live table of the
  current run), Delete Runs (confirm + wipe), all under Options → Speedrun Mod.
- **Configs:** `sr_pb.cfg` (PB cvar declarations), `sr_pbwipe.cfg` (wipe),
  `sr_settings.cfg` (settings fallback for a stock exe).
- **Docs:** `CHANGELOG.md` and `docs/TIMING.md` (timing rules and how they were
  verified).

**Changed**
- Timing reworked toward ASL/LiveSplit parity: loads, checkpoint-save freezes
  and briefing maps excluded; pauses and death screens counted. Splits and PBs
  are stored at millisecond precision; display rounding is applied only at the
  readout (`sr_tmr_dec`: tenths / hundredths / ms).
- Chat is quiet during a run: only `MAP TIME` / `RUN TOTAL`, PB lines, the
  final time and command output. All diagnostics moved behind `sr_debug 1`.
- Internal cvars renamed `sr_*` → `rt_*`, so `sr_` in the console lists
  settings only.
- Anti-cheese: a level loaded with `map`/`devmap`, or left before finishing,
  is not banked and never becomes a PB; `map training` restarts the run.
- Repo restructured: `src_loctext/` → `src/`, patch docs replaced by the
  changelog.

---

## 1.1 — 2026-08-08

*Timing changes, Settings Menu* (`2f57708`)

**Added**
- **In-game Settings page** (Options → Speedrun Mod): Speedometer, Avg Speed,
  Timers, Decimals, Debug toggles + a Reset Run button. Ships with a modified
  `options.menu`, `sr_settings.menu` and `menus.txt` (docs in `UI_menu.md`).

**Changed**
- **Wall-clock timing channel:** with the patched dll (api ≥ 14) splits come
  from a pause-inclusive wall clock (`rt_wtotal` / `rt_wcur_int`) at ~1 ms
  accuracy; the old frame-grid numbers remain as fallback for pure-script
  installs.
- Briefing levels are excluded from the run total (`BRIEFMAP SKIP`).

---

## 1.0.3 — 2026-08-06/07

*avg speed added; avg speed + gap changes* (`b2123e1`, `882b2fd`)

**Added**
- **Rolling 5-second average speed** under the speedometer (`sr_spd_avg`,
  100-sample ring buffer @ 50 ms ticks).

**Changed**
- Quickload restore gap tightened again: 100 ms → 10 ms.
- Removed `sr_maxwin` (the max-speed auto-reset window) — superseded by the
  rolling average.

---

## 1.0.2 — 2026-08-06

*Fixed sr_igt and sr_speedo cvars; Lowered the restore gap* (`04f7b97`,
`95aeb43`)

**Fixed**
- `sr_igt` and `sr_speedo` toggles now actually hide their HUD elements
  (alpha 0/1, elements stay alive) — including the lazy hour digits.

**Changed**
- Quickload restore gap lowered: 750 ms → 100 ms.

---

## 1.0.1 — 2026-08-06

*Timer Changes* (`f225b5c`)

**Changed**
- Milliseconds rendered as three zero-padded digit elements (`MM:SS.mmm`
  proper) instead of one unpadded number — 10 live hudelems total within the
  tankdrive budget.
- Speedometer colour thresholds retuned: green/yellow/red at 190/250/300 →
  **180/230/275** u/s.

---

## 1.0 — 2026-08-06

*Initial commit* (`7110bd3`, `1d001ce`)

- First public version: `_main.gsc` (timer, speedometer, HUD, quickload
  continuity), stock `_load.gsc` with the one-line hook, `berlin.gsc` final
  split, `_tankdrive.gsc` hudelem sort fix.
- `install.ps1`, packaging/hash tools, `HOOK_load_gsc.md` patch doc,
  `configs/autoexec.cfg`.
