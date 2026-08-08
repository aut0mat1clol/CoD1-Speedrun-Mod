# UI: mod settings inside the stock OPTIONS menu

Three files inside `z_sr_speedrun_loctext.pk3` (`ui/`). Two stock files are
modified minimally, one file is new. Single-player menus live in `ui/`
(NOT `ui_mp/`!): the SP engine reads its menu list from `ui/menus.txt` in the
original `localized_english_pak0.pk3`; our pk3 overrides it alphabetically
(`z_...`).

## `ui/menus.txt` (stock + 1 line)

```diff
 	loadMenu { "ui/options.menu" }
+	loadMenu { "ui/sr_settings.menu" }	// SPEEDRUN MOD
 	loadMenu { "ui/options_look.menu" }
```

## `ui/options.menu` (stock + one new entry)

1. In each of the 15 existing tab-button action blocks a single line
   `close sr_settings;` was added, so the mod settings panel closes when
   switching to any other OPTIONS tab (mirroring how the stock tabs close
   their own panels).
2. Two new `itemDef`s at the bottom of the menu (below the BACK button,
   bottom-right corner): a decorative `Speedrun Mod` header and a
   `Settings` button whose action `close`s every stock tab and does
   `open sr_settings;`.

## `ui/sr_settings.menu` (new file)

A left-side panel window: toggles for `sr_speedo`, `sr_spd_avg`, `sr_igt`,
`sr_debug`, a `sr_spd_dec` list (0-3) and a **Reset Run** button executing:

```
setcvar rt_run_total 0; setcvar rt_ms_cur 0; setcvar rt_wtotal 0;
setcvar rt_wcur_int 0; setcvar rt_spd_max 0; setcvar rt_end_frozen 0;
setcvar rt_cont_real 0; setcvar rt_cont_wall 0; setcvar rt_cmd_mreset 1
```

`rt_cmd_mreset 1` is a "latch": the GSC loop picks it up and re-anchors the
timers on the same tick.

## Persistence nuance

The menu changes cvars live, like `set` in the console. The engine saves to
`config.cfg` only cvars that carry the ARCHIVE flag (ones created via
`seta`). The mod intentionally ships NO `sr_*` lines in `autoexec.cfg`:
any `seta` there would run at every launch and would clobber the values the
player saved.
