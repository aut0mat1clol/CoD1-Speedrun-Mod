# Changelog

Only the entries that changed behaviour. Versions before 0.14 are summarised.

## 1.2.2

* `map berlin` typed right after **launching the game** could save a bogus
  full-run PB: `rt_last_map` is a session cvar, so on a fresh start the
  arrival check saw an empty previous map and treated berlin as "first map of
  the session" — `rt_norun` stayed 0. The final split now also requires the
  first map's split to exist in the current run table (`rs_<firstmap>` > 0,
  a session cvar written only when the first map is actually banked).
  `RUN END!` still prints as a reference; only the PB is blocked.
* Mod sub-pages (Level PBs / Run Splits / Delete Runs) stayed open when a
  stock Options section was clicked without pressing ESC first, stacking two
  pages on screen. Every right-hand Options button (and `options_menu`'s
  `onClose`) now closes `sr_run` / `sr_pb` / `sr_delete` too, and the
  Speedrun Settings button closes them before opening its own page.

## 1.2.1

* **PBs survive a restart without `exec sr_pb.cfg`** (patched exe v18): the
  run-once cave that declares the `sr_*` settings now also walks a table of
  all 54 PB cvars (`pb_`/`pbs_` for the 26 maps + full) and declares each
  through the engine's own `Cvar_Get` with the ARCHIVE flag. `Cvar_Get` never
  overwrites an existing value, so current records are kept; the engine
  writes them to `config.cfg` on exit. `sr_pb.cfg` stays as the fallback for
  a stock exe.
* **Berlin was added to the full-game total twice.** The final-split block
  banked berlin itself but left `rt_rta_last` alive, `sr_rta_loop()` kept
  refreshing it, and credits' `init()` re-banked it — credits is not in the
  story list, so the order check waved the arrival through as a custom map
  (`rt_banked_map` only guards the PB compare, not the total; `sr_tail` was
  added on top as well). Three independent fixes: the final split zeroes
  `rt_rta_last` / `rt_wcur_int` / `rt_lat_prev`, `sr_rta_loop()` stops once
  `rt_end_frozen` is set, and an arrival with `rt_end_frozen` up banks
  nothing at all.

## 1.2

First tagged release.

* Chat is quiet during a run: only `MAP TIME` / `RUN TOTAL`, PB lines, the
  final time and command output. Everything diagnostic (resets, skipped maps,
  pause/save accounting, the load banner) moved behind `sr_debug 1`.
* Fixed a double `[SR] [SR]` prefix on the PB lines.

## 0.19.2

* Fixed the 0.19.1 fix: clearing `nextmap` after reading it broke the very
  signal it introduced — the clear hit the *next* transition, so leaving
  pegasusnight there was no handover marker left. The split was dropped and
  the run flagged, which also made the full-game row look like it had reset.
* `nextmap` is no longer written by the mod at all (it belongs to the engine),
  and banking is allowed by default again: only an out-of-order arrival blocks
  it. Requiring a positive "level finished" signal keeps failing on maps that
  end without a victory screen, and losing a real split is worse than
  occasionally accepting a manual jump.

## 0.19.1

* Splits were dropped on levels that do not end through a victory screen
  (pegasusnight, and any other map handing over by itself) — a regression from
  0.18.2, where banking required a flag only the victory watcher could set.
  The handover is now read from the engine: `missionSuccess()` writes
  `nextmap = "map <next>"`, a manual `map` never does, so the arriving map just
  asks whether `nextmap` points at itself. State, not an event.
* `nextmap` is cleared once read, otherwise a stale value would let a later
  manual jump to the next story map pass as a legitimate transition.

## 0.19.0

* Internal cvars moved from `sr_` to `rt_`, so `sr_` in the console lists
  settings and nothing else: `rt_velx10`, `rt_wallms`, `rt_aslms`,
  `rt_asllatch`, `rt_norun`, `rt_rta`, `rt_cfg_ok`.
  Names kept their length, so the exe strings were patched in place — no code
  moved.
* Added `configs/sr_cleanup.cfg` for the old names still sitting in
  `config.cfg` from earlier versions.

## 0.18.x

* **0.18.2** — `map pathfinder` typed on training was treated as a legitimate
  transition (pathfinder really is the next story map), so a half-played
  training got banked. A level is now banked only if it *finished by itself*
  (`rt_lvl_done`, set by the victory watcher / berlin cinematic).
* **0.18.1** — loading a quicksave reset the level timer. Restart Level and F9
  are both savegame loads; they are told apart by where the level clock lands
  relative to the anchor (`rt_lvl_clk0`).
* **0.18.0** — settings persist without `exec`: the exe declares every `sr_*`
  through `Cvar_Get` with the ARCHIVE flag, once per launch.

## 0.17.x

* **0.17.1** — Restart Level did not reset L. The detector compared `gettime()`
  against a thread local, and a savegame restores both, so the rewind was
  invisible; it now compares against a cvar mirror.
* **0.17.0** — per-row switches (`sr_show_l`, `sr_show_fg`) and IL mode. Reset
  Run now holds the L row at zero instead of letting the 20 s fallback re-arm
  it.
* **0.16.2** — New Game did not clear the total: the reset ran before the
  banking block, which put the previous map straight back. Reset Run no longer
  restarts the FG row on the spot.
* **0.16.1** — Reset Run only moved `sr_starttime`, the last fallback clock, so
  with the exe bridge live nothing happened.
* **0.16.0** — settings cleanup: four contradictory cvars (`sr_ericg`,
  `sr_aio`, `sr_asl`, `sr_round`) replaced by `sr_tmr_dec`. Run splits became
  a menu page.

## 0.15.x

* **0.15.1** — a level reached with `map`/`devmap` is not banked and never
  becomes a PB; `map training` stays the documented way to restart.
* **0.15.0** — timing returned to the GSC loop plus a constant `sr_tail`
  (360 ms). The exe code cave is hooked into one branch of an engine switch,
  which does not run every frame; once the clock lived there, skipped branches
  became skipped time — one run drifted 81 s.

## 0.14.x

* Chased LiveSplit parity through the exe: an ASL-rule counter, a latch at the
  loading flag, segment stitching. Accurate in principle, but tied to the same
  unreliable hook — superseded by 0.15.0.
* **0.14.1** — established from video that the leaderboard reads *Game Time*,
  which freezes on loads, while Real Time does not.

## Earlier

* Speedometer bridged through the exe at 0.001 u/s (`rt_velx10`, ×1000).
* Timer rows in `H:MM:SS.mmm`, always visible, also over menus and end screens.
* Level PBs, full-run PB, run splits, Delete Runs page.
* Level timer anchored to the level-start autosave with a countdown intro.
* Pause counting via a wall clock published by the exe.
