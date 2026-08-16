# Timing rules

What the timer counts, why, and how it was verified. Everything here was
measured frame-by-frame against a LiveSplit capture, not assumed.

## The reference

The leaderboard uses LiveSplit with the community autosplitter
(`yf5y2.asl`). Its whole rule is one line:

```
isLoading = (loading == 0) || levelName in {6 briefing maps}
```

`loading` is an engine byte meaning *"the game is not accepting input"*.
So **Game Time** excludes level loads and the six briefing maps, and
**includes** ESC pauses and death screens.

Two consequences that are easy to get wrong:

* the splits in the LiveSplit table are **Game Time**, not Real Time — an
  overlay usually shows both, and they differ by the total load time;
* the timer keeps running through the fade-out **and the black screen** at the
  end of a level, and even the first frames of the LOADING image. It stops
  later than the screen goes dark.

Verified on a capture: across one load Game Time advanced `+0.006 s` while
Real Time advanced `+4.662 s`.

## What the mod does

`sr_map_ms()` is the single source for both rows. Priority:

1. `sr_aslms` — the patched exe's counter, which only advances while the
   engine accepts input (same rule as the ASL);
2. `sr_wallms` — plain wall clock, when the exe provides it but the ASL
   channel is unavailable;
3. `gettime()` — the level clock, on a stock exe.

A split is `mirror + sr_tail`, where the mirror is written every frame by a
GSC loop and `sr_tail` (default 360 ms) covers the tail the engine still
counts after the last server frame of a map.

### Why a constant

The exe code cave is hooked into **one branch** of an engine switch (the
speedometer hook). That branch does not run every frame — the console line
`NATIVE DEAD: sr_velx10='000000'` is the engine saying so. Harmless while the
cave only published speed; once the *time* lived there, every skipped branch
became skipped time, and one run drifted 81 s.

So timing moved back to the GSC loop (`wait .05`, never skips) and the
per-map tail is added as a measured constant. Across four maps the tail
measured −0.339, −0.364, −0.364, −0.372 s: a spread of 33 ms, i.e. genuinely
constant. Adding 360 ms gave a worst case of 0.021 s per map and +0.001 s over
the whole segment.

## Boundaries

| Event | Counted? | How it is detected |
|---|---|---|
| Level load | no | engine flag / clock does not advance |
| Briefing map | no | name in the skip list |
| ESC pause, menus | yes | wall clock keeps moving |
| Death screen | yes | same |
| End-of-level screen | yes | part of the map's time |
| Checkpoint write freeze | no | engine flag drops |
| Quickload | rolls back | cvar mirror vs restored state |

## Level timer

Starts at the level-start autosave — the stock chain is

```
maps\_load::main → maps\_autosave::beginingOfLevelSave
                 → waittill("finished intro screen")
                 → maps\_utility::levelStartSave → saveGame("levelstart")
```

so that notify *is* the save frame. Before it the row counts **down** from the
known intro length (2.8 s, 4.8 s on stalingrad, 0.05 s without an intro card),
re-syncing on the two mid-intro notifies so a frame hitch cannot drift the
zero. If the intro runs long the row sits at `-0:00.0` until the save lands.

Reset conditions:

* **Restart Level** — loads `save/autosave/<map>.svg`, so the level clock
  lands back at the anchor → L restarts from zero;
* **quickload** — lands mid-level → L rolls back with the clock, no restart.

Both are the same event (a savegame load) and are told apart by comparing the
restored clock against `rt_lvl_clk0`, the clock captured when L was armed.

## Run integrity

A level is banked only if it **finished by itself** (`rt_lvl_done`, set by the
victory-screen watcher or the berlin cinematic hook). Combined with the
story-order check this covers both:

* `map berlin` from pathfinder — wrong order;
* `map pathfinder` from training — right order, but training never finished.

Either way the split is dropped and the run is flagged, so no full-run PB is
written. `map training` is the documented way to restart and resets cleanly.
