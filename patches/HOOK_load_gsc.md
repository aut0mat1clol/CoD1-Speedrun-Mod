# How the mod hooks into the game — technical breakdown (for moderators)

## The hook: `maps/_load.gsc`

Every one of the 26 campaign missions calls `maps\_load::main()` at the top
of its map script. The mod injects exactly **one line** at the very start of
that function:

```gsc
main()
{
	thread maps\speedrun\_main::init(); // [SR] speedrun mod hook
    ...
```

From there the mod starts itself on every map (one thread, self-healing
watchdog).

**Stock archives are never modified.** The patched `_load.gsc` ships inside
`z_sr_speedrun_loctext.pk3`. The engine resolves files across pk3 archives in
reverse-alphabetical order, so a file in `z_...pk3` overrides the same path
in `pak0.pk3` & co. Uninstalling = deleting the pk3.

## Complete list of stock-script diffs (nothing else is touched)

| File | Diff | Purpose |
|---|---|---|
| `maps/_load.gsc` | **+1 line** | the init hook shown above; the rest of the file is byte-identical to stock |
| `maps/_tankdrive.gsc` | **+1 line** | `tankhud2.sort = 1000;` in `tank_hud()` — **cosmetic only**: with the mod's extra HUD elements present, the engine's equal-sort draw order rendered the healthbar fill on top of its frame; the frame is now pinned above the fill. Zero gameplay effect |
| `maps/berlin.gsc` | final-split anchor | `setcvar("rt_end_frozen", "1")` placed **after** `cinematic("cod_end.roq");` + `wait (0.6);`, i.e. the run timer freezes on the first frame of the end video. `cinematic()` does not block the script; the 0.6 s is hardcoded — the split point is identical for every runner |

## The `gamex86.dll` patch

- md5 `AB3FF2DFBF7892E6DBEBC4A23E1615B4`, produced by patching the user's own
  stock dll (the original is not distributed anywhere).
- Two minimal **additive** overloads:
  1. `getfractionstartammo()` on the player → exact planar speed
     `sqrt(vx^2 + vy^2)` for the speedometer.
  2. `getfractionmaxammo()` called **with no arguments** →
     `float(GetTickCount())`, a wall clock used to count pause-menu time.
- Stock behavior under normal usage is unchanged — verified: **none of the
  144 stock `.gsc` scripts call either function**.

## What the timer actually is (verification-relevant)

- **Pure GSC**: server-frame accumulation (50 ms tick); the run total
  persists through F9 quickloads via archived cvars
  (`rt_cont_real` / `rt_cont_wall`, CVAR_ARCHIVE).
- Excluded automatically: loads (same-map rollback detector), pre-mission
  briefing screens (level-clock gate). ESC pause **counts** (RTA) via the
  wall clock. New Game auto-resets.
- The HUD is script hudelems only (single-digit columns; no custom shaders,
  menus or cgame changes).
- Console output (always on): `NEW GAME: run timer reset`,
  `[SR] MAP TIME … | RUN TOTAL …`, `RUN END! FINAL TIME … - gg!`.

## How to verify in-game

`CoDSP.exe +set developer 1`, then `set sr_debug 1` and load any map —
expected lines:

```
Speedrun mod loaded (1.0.2)
pause clock ON (wall clock ok)
```

and a clean console (no `script compile error`, no `runtime error`).

## Conflicts with other SP mods

If another mod overrides `_load.gsc` too, the alphabetically later pk3 wins.
To merge, inject the same one-line hook into the `_load.gsc` copy that
actually loads (i.e. from the later pk3).
