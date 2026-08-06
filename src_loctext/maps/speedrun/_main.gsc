// ============================================================================
// Speedrun All-in-One (1.0) / CoD1 SP (patch 1.3) - LOCTEXT single build
//
// Semantics:
//   - run total survives F9 quickloads via the archived cvar channel
//     (rt_cont_real/rt_cont_wall, CVAR_ARCHIVE); same-map catch-up:
//     a >750ms gap restores the run total;
//   - PAUSE COUNTS (RTA): the dll patch makes getfractionmaxammo() with
//     NO args a raw GetTickCount() wall clock; ESC freezes script frames,
//     so one long gap == a pause and is added; quickloads are excluded by
//     the rollback detector (wasload), loads stay out (ASL-style);
//   - pre-mission BRIEFING screens are excluded via the level clock
//     (gettime freezes there too) - counted only after the level clock ran
//     >=1s past the arm tick;
//   - speedometer: native-only (dll patch, exact ps.velocity), HUD center;
//     run total top-right under the stock Level Time, H:MM:SS.mmm, colors
//     white/green/yellow/red by speed;
//   - sr_debug 0|1 (default quiet): only Reset / Map Time / Run End print;
//   - NewGame autoreset (fresh-clock test + first-map briefing latch);
//   - berlin final split is anchored to the end VIDEO start: freeze after
//     cinematic() + wait(0.6) - hardcoded, identical for every runner.
// NOTE (cod1 gsc): never '!' an undefined var ("cannot cast undefined to
// bool") - level flags are read as !isdefined(level.x).
// rt_dll_api (patcher-set, fail-closed): >=1 exact speedo, >=14 pause clock.
// ============================================================================

init()
{
    // ---------- cvar defaults (created on first run) ----------
    // USER SETTINGS (sr_ prefix - these are meant to be tweaked):
    sr_cvar_default("sr_speedo",     "1"); // speedometer on/off (console)
    sr_cvar_default("sr_igt",        "1"); // IGT timer on/off (console)
    sr_cvar_default("sr_maxwin",     "30"); // rt_spd_max auto-reset, sec (0=off)
    sr_cvar_default("sr_spd_dec",    "1"); // speedometer decimals (0..3)
    sr_cvar_default("sr_firstmap",   "training"); // New Game autoreset map
    sr_cvar_default("sr_debug",      "0"); // 1 = full diagnostic [SR] prints
    // INTERNAL STATE (rt_ prefix - data, not settings):
    sr_cvar_default("rt_igt_m",      "0");
    sr_cvar_default("rt_igt_s",      "0");
    sr_cvar_default("rt_igt_ds",     "0");
    sr_cvar_default("rt_ms_cur",     "0"); // raw ms on the current map
    sr_cvar_default("rt_run_total",  "0"); // full-run accumulator, ms
    sr_cvar_default("rt_spd",        "0");
    sr_cvar_default("rt_spd_max",    "0");
    sr_cvar_default("rt_last_map",   "");
    sr_cvar_default("rt_end_frozen", "0"); // 1 = final split taken (berlin end)
    // continuity channel (ASL-style): archived cvars (autoexec.cfg seta),
    // written every tick
    sr_cvar_default("rt_cont_real",  "0");
    sr_cvar_default("rt_cont_wall",  "0");
    sr_cvar_default("rt_cmd_mreset",  "0"); // console latch: map-timer reset
    // rt_dll_api is set ONLY by the patcher (fail-closed):
    // >=1 = exact speedo present, >=14 = pause wall clock present.
    sr_cvar_default("rt_dll_api",     "0"); // set by install.ps1 -Patch

    // ---------- carry over the previous map time into the run total ----------
    // New Game autoreset: (a) landing on sr_firstmap from a DIFFERENT map
    // with a nonzero total, or (b) ANY arrival on sr_firstmap with a FRESH
    // level clock (menu New Game / `map` / mission restart). Quickloads
    // never re-run init, so the fresh-clock test cannot false-trigger.
    mapname_now = getcvar("mapname");
    freshclock = (getcvarint("rt_cont_wall") > 2000
        && gettime() + 2000 < getcvarint("rt_cont_wall"));
    if(getcvar("sr_firstmap") != "" && mapname_now == getcvar("sr_firstmap")
        && getcvarint("rt_run_total") > 0
        && (getcvar("rt_last_map") != mapname_now || freshclock))
    {
        setcvar("rt_run_total", 0);
        setcvar("rt_ms_cur", 0);
        setcvar("rt_spd_max", 0);
        setcvar("rt_end_frozen", 0);
        setcvar("rt_cont_real", 0);
        setcvar("rt_cont_wall", 0);
        sr_text("NEW GAME: run timer reset");
    }

    prev = getcvarint("rt_ms_cur");

    if(prev > 0)
    {
        total = getcvarint("rt_run_total") + prev;
        setcvar("rt_run_total", total);

        // padded like the HUD: MM:SS.mmm | H:MM:SS.mmm
        pmm = prev / 60000; pss = (prev / 1000) % 60; pms = prev % 1000;
        thh = total / 3600000; tmm = (total / 60000) % 60;
        tss = (total / 1000) % 60; tms = total % 1000;
        sr_text("MAP TIME " + sr_pad2(pmm) + ":" + sr_pad2(pss) + "." + sr_pad3(pms)
            + " | RUN TOTAL " + thh + ":" + sr_pad2(tmm) + ":" + sr_pad2(tss) + "." + sr_pad3(tms));
    }

    setcvar("rt_last_map", getcvar("mapname"));
    // credits.bsp: init() normally re-arms the end trigger, which would
    // RESUME the run timer during the credits. The run ended with the
    // berlin end cinematic - stay frozen here.
    if(getcvar("mapname") == "credits")
        setcvar("rt_end_frozen", "1"); // run already ended on berlin - stay frozen
    else
        setcvar("rt_end_frozen", "0"); // a fresh map (or same-map retry) re-arms the end trigger
    level.sr_starttime = gettime();
    setcvar("rt_ms_cur", 0);
    level.sr_walllast = undefined; // re-arm the pause clock: skip first post-init tick

    // ---------- wait for the player entity ----------
    player = sr_wait_player();
    if(!isdefined(player))
        return;

    // ---------- start loops ----------
    player thread sr_timer_loop();
    player thread sr_speedo_loop();
    player thread sr_hud_loop();

    sr_dbg("Speedrun mod loaded (1.0).");
}

// ----------------------------------------------------------------------------
sr_cvar_default(name, val)
{
    if(getcvar(name) == "")
        setcvar(name, val);
}

sr_wait_player()
{
    p = getentarray("player", "classname");
    for(i = 0; i < 100; i++)
    {
        if(isdefined(p) && p.size > 0)
            return p[0];
        wait .05;
        p = getentarray("player", "classname");
    }
    return undefined;
}

sr_text(msg)
{
    iprintln("^3[SR] " + msg);
    println("[SR] " + msg);
}

// diagnostic-only print (sr_debug 1); OFF by default for clean runs
sr_dbg(msg)
{
    if(getcvarint("sr_debug"))
        sr_text(msg);
}

// console-friendly zero-padding for the important always-on prints
sr_pad2(x)
{
    if(x < 10)
        return "0" + x;
    return "" + x;
}

sr_pad3(x)
{
    if(x < 10)
        return "00" + x;
    if(x < 100)
        return "0" + x;
    return "" + x;
}

// ============================================================================
// IGT timer: autostarts on map load. Computed for splits; not drawn in HUD.
// Also owns the continuity channels (archived cvars), the pause/menu wall
// clock (dll patch), the NewGame safety latch and the final split.
// ============================================================================
sr_timer_loop()
{
    self endon("disconnect");

    for(;;)
    {
        level.sr_beat = gettime(); // watchdog heartbeat

        // ---- save-load continuity (ASL-style: total survives quickloads) ----
        froz = getcvarint("rt_end_frozen");
        if(froz)
            cont_disp = getcvarint("rt_run_total");
        else
            cont_disp = getcvarint("rt_run_total") + (gettime() - level.sr_starttime);

        // same-map check: map TRANSITIONS bank the old map time instead
        wasload = 0;
        if(!froz && getcvar("mapname") != "" && getcvar("rt_last_map") == getcvar("mapname"))
        {
            gap = getcvarint("rt_cont_real") - cont_disp; // >0 => state rewound by a quickload
            if(gap > 750)
            {
                level.sr_starttime = gettime() - (getcvarint("rt_cont_real") - getcvarint("rt_run_total"));
                setcvar("rt_ms_cur", getcvarint("rt_cont_real") - getcvarint("rt_run_total"));
                cont_disp = getcvarint("rt_cont_real");
                wasload = 1;
                sr_dbg("LOAD: total continued from " + (cont_disp / 1000) + "s");
            }
        }
        setcvar("rt_cont_real", cont_disp);
        setcvar("rt_cont_wall", gettime());

        // ---- NewGame safety latch -------------------------------------
        // While the first map is in its briefing cradle (level clock
        // <1.5s since init), any leftover BANKED total can only be a
        // restarted run - reset it, one-shot per map arrival.
        if(!isdefined(level.sr_greset)
            && getcvar("sr_firstmap") != ""
            && getcvar("mapname") == getcvar("sr_firstmap")
            && getcvarint("rt_run_total") > 0
            && gettime() - level.sr_starttime <= 1500)
        {
            level.sr_greset = 1;
            setcvar("rt_run_total", 0);
            setcvar("rt_ms_cur", 0);
            setcvar("rt_spd_max", 0);
            setcvar("rt_end_frozen", 0);
            setcvar("rt_cont_real", 0);
            setcvar("rt_cont_wall", 0);
            level.sr_starttime = gettime();
            sr_text("NEW GAME: run timer reset (start latch)");
        }

        // ---- pause/menu time COUNTS (RTA, dll wall clock) -------------
        // getfractionmaxammo() with NO args returns raw GetTickCount ms as
        // a float. HUGE number (ms since Windows boot) -> keep it in LEVEL
        // float vars only, never in a cvar (%g would mangle them). Nearby big floats
        // subtract exactly. Script frames do not run while ESC is open ->
        // one long off-script gap == a pause; a quickload is told apart by
        // the rollback detector above (wasload), loads never add. Briefing
        // cradles are skipped via the level clock.
        if(getcvarint("rt_dll_api") >= 14 && !froz)
        {
            w = self getfractionmaxammo();
            if(w <= 0)
            {
                if(!isdefined(level.sr_walldead))
                {
                    level.sr_walldead = 1; // stock dll answers 0/errors here
                    sr_dbg("pause clock DEAD (wall read 0): dll patch missing - rerun install.ps1 -Patch");
                }
            }
            else
            {
                if(!isdefined(level.sr_walllast))
                {
                    level.sr_walllast = w; // first tick after init: just arm
                    level.sr_wallarm = gettime(); // level clock at arm
                    sr_dbg("pause clock ON (wall clock ok)");
                }
                d = w - level.sr_walllast;
                level.sr_walllast = w;
                if(!wasload && d > 750 && d < 3600000)
                {
                    di = sr_floor_big(d); // float ms -> INTEGER ms!
                    if(gettime() - level.sr_wallarm <= 1000) // pre-mission screen!
                    {
                        // level clock frozen -> this gap is the briefing
                        // screen, NOT a gameplay pause: skip it (visible).
                        sr_dbg("PRE-MISSION: +" + (di / 1000) + "." + (di % 1000) + "s screen time skipped (not counted)");
                    }
                    else
                    {
                        level.sr_starttime = level.sr_starttime - di; // stretch: pause counts
                        setcvar("rt_ms_cur", gettime() - level.sr_starttime);
                        sr_dbg("PAUSE: +" + (di / 1000) + "." + (di % 1000) + "s counted (menu time runs)");
                    }
                }
            }
        }
        else if(getcvarint("rt_dll_api") >= 1 && !isdefined(level.sr_wall_noted))
        {
            level.sr_wall_noted = 1; // one-time hint when the dll patch is missing
            sr_dbg("pause clock needs the dll patch: rerun install.ps1 -Patch");
        }

        if(getcvarint("rt_cmd_mreset"))
        {
            setcvar("rt_cmd_mreset", "0");
            level.sr_starttime = gettime(); // manual map-timer reset (console)
        }

        // final split: a stock-script hook (berlin end cinematic) sets
        // rt_end_frozen=1 -> bank the time once and freeze every readout
        if(getcvarint("rt_end_frozen"))
        {
            if(!isdefined(level.sr_end_banked))
            {
                level.sr_end_banked = 1;
                fin = getcvarint("rt_run_total") + (gettime() - level.sr_starttime);
                setcvar("rt_run_total", fin);
                setcvar("rt_ms_cur", 0);
                level.sr_starttime = gettime(); // pinned: elapsed stays 0
                rhh = fin / 3600000; rmm = (fin / 60000) % 60;
                rss = (fin / 1000) % 60; rms = fin % 1000;
                sr_text("RUN END! FINAL TIME " + rhh + ":" + sr_pad2(rmm) + ":" + sr_pad2(rss) + "." + sr_pad3(rms) + " - gg!");
            }
        }
        else
        {
            level.sr_end_banked = undefined;
        }

        if(getcvarint("sr_igt") && !getcvarint("rt_end_frozen"))
        {
            t = gettime() - level.sr_starttime; // ms on this map
            setcvar("rt_ms_cur", t);

            setcvar("rt_igt_m",  (t / 60000));
            setcvar("rt_igt_s",  (t / 1000) % 60);
            setcvar("rt_igt_ds", (t / 100) % 10); // tenths
        }
        wait .05;
    }
}

// ============================================================================
// Speedometer: horizontal player speed (units/sec), EXACT native value from
// the gamex86.dll patch (getfractionstartammo -> sqrt(vx^2+vy^2) of
// ps.velocity). No origin-delta fallback. Color by speed in the HUD loop.
// Also tracks the max speed with an auto-reset window (bhop practice).
// ============================================================================
sr_speedo_loop()
{
    self endon("disconnect");

    need_note = 1; // "patch required" hint, printed once

    for(;;)
    {
        wait .05; // 20Hz server tick - the max cadence any script number gets

        level.sr_beat2 = gettime(); // watchdog heartbeat

        // rt_spd_max auto-reset window (seconds; 0 = disabled)
        win = getcvarint("sr_maxwin");
        if(win > 0)
        {
            if(!isdefined(level.sr_maxwin_at))
                level.sr_maxwin_at = gettime();
            if(gettime() - level.sr_maxwin_at >= win * 1000)
            {
                setcvar("rt_spd_max", "0");
                level.sr_maxwin_at = gettime();
            }
        }

        if(!getcvarint("sr_speedo"))
            continue;

        // native exact speed (needs the dll patch; rt_dll_api is patcher-set):
        if(!getcvarint("rt_dll_api"))
        {
            if(need_note)
            {
                need_note = 0;
                sr_dbg("speedo is patch-only: run install.ps1 -Patch");
            }
            setcvar("rt_spd", "0");
            continue;
        }

        nv = self getfractionstartammo();
        if(nv > getcvarfloat("rt_spd_max"))
            setcvar("rt_spd_max", nv); // max keeps the RAW native peak

        // display rounding: sr_spd_dec digits after the point (0..3).
        // CoD1 GSC has NO int/floor builtins -> round via the cvar string
        // channel: write the scaled float, read back as integer (string
        // parse truncates at the dot; +0.5 = round half up).
        dec = getcvarint("sr_spd_dec");
        mul = 1.0;
        if(dec == 1)
            mul = 10.0;
        else if(dec == 2)
            mul = 100.0;
        else if(dec >= 3)
            mul = 1000.0;
        setcvar("rt_dt", nv * mul + 0.5);
        setcvar("rt_spd", getcvarint("rt_dt") / mul); // integer div by float = float
    }
}

// ============================================================================
// HUD - speedo center + run total top-right under the built-in Level Time.
// Only 8 live elems (tankdrive hudelem budget): the total renders
// zero-padded MM:SS.mmm as single-digit columns, the hours pair appears
// lazily at >=1h, mmm is one unpadded elem (user asked padding for MM/SS
// only). Punctuation via the missing-istring fallback. Watchdog.
// ============================================================================
sr_hud_loop()
{
    self endon("disconnect");

    // ---- speedometer: raised above the dialogue band ----
    hud_spd = newHudElem();
    hud_spd.x = 320;
    hud_spd.y = 300;
    hud_spd.alignX = "center";
    hud_spd.alignY = "top";
    hud_spd.sort = 10; // stay above stock fade overlays
    hud_spd.fontscale = 1.4;
    hud_spd.color = (1, 1, 1);

    // ---- formatted total, ZERO-PADDED digits, only 8 live elems ----
    // Right edge pinned at 612 under the built-in Level Time .
    hud_mm1 = newHudElem(); hud_mm1.x = 530; hud_mm1.alignX = "left";
    hud_mm2 = newHudElem(); hud_mm2.x = 540; hud_mm2.alignX = "left";
    hud_c1  = newHudElem(); hud_c1.x  = 551; hud_c1.alignX  = "left";
    hud_ss1 = newHudElem(); hud_ss1.x = 556; hud_ss1.alignX = "left";
    hud_ss2 = newHudElem(); hud_ss2.x = 566; hud_ss2.alignX = "left";
    hud_c2  = newHudElem(); hud_c2.x  = 577; hud_c2.alignX  = "left";
    hud_mmm = newHudElem(); hud_mmm.x = 612; hud_mmm.alignX = "right";

    tel[0] = hud_mm1; tel[1] = hud_mm2; tel[2] = hud_c1;
    tel[3] = hud_ss1; tel[4] = hud_ss2; tel[5] = hud_c2; tel[6] = hud_mmm;
    for(ti = 0; ti < tel.size; ti++)
    {
        tel[ti].y = 62;
        tel[ti].alignY = "top";
        tel[ti].sort = 10; // stay above stock fade overlays
        tel[ti].fontscale = 1.1;
        tel[ti].color = (1, 1, 0.4);
    }
    hud_c1 setText(&":");
    hud_c2 setText(&".");

    sr_dbg("HUD elems created: spd center, total MM:SS.mmm (8 live, lazy H)");

    for(;;)
    {
        // Watchdog: restart dead loops (self-healing, reports to console)
        dead1 = isdefined(level.sr_beat)  && gettime() - level.sr_beat  > 1000;
        dead2 = isdefined(level.sr_beat2) && gettime() - level.sr_beat2 > 1000;
        if(dead1 || dead2)
        {
            if(dead1)
                self thread sr_timer_loop();
            if(dead2)
                self thread sr_speedo_loop();
            sr_dbg("WATCHDOG: loop(s) restarted - report this!");
            wait 2;
        }

        spd = getcvarfloat("rt_spd");
        hud_spd setValue(spd); // fractional u/s
        if(spd >= 300)      hud_spd.color = (1, 0.15, 0.15); // red
        else if(spd >= 250) hud_spd.color = (1, 0.9, 0.1);   // yellow
        else if(spd >= 190) hud_spd.color = (0.25, 1, 0.3);  // green
        else                hud_spd.color = (1, 1, 1);       // idle

        if(getcvarint("rt_end_frozen"))
            total = getcvarint("rt_run_total"); // frozen final time
        else
            total = getcvarint("rt_run_total") + gettime() - level.sr_starttime;

        // lazy hours pair: exists only from 1h on (hudelem budget)
        if(total >= 3600000 && !isdefined(hud_th))
        {
            hud_th = newHudElem(); hud_th.x = 521; hud_th.alignX = "right";
            hud_c0 = newHudElem(); hud_c0.x = 525; hud_c0.alignX = "left";
            hud_th.y = 62; hud_th.alignY = "top"; hud_th.sort = 10;
            hud_th.fontscale = 1.1; hud_th.color = (1, 1, 0.4);
            hud_c0.y = 62; hud_c0.alignY = "top"; hud_c0.sort = 10;
            hud_c0.fontscale = 1.1; hud_c0.color = (1, 1, 0.4);
            hud_c0 setText(&":");
        }
        if(isdefined(hud_th))
        {
            if(total >= 3600000)
            {
                hud_th.alpha = 1;
                hud_c0.alpha = 1;
                hud_th setValue(total / 3600000);
            }
            else
            {
                hud_th.alpha = 0; // run restarted: hide the stale pair
                hud_c0.alpha = 0;
            }
        }

        // MM:SS.mmm (pure int math)
        hud_mm1 setValue(((total / 60000) % 60) / 10);
        hud_mm2 setValue((total / 60000) % 10);
        hud_ss1 setValue(((total / 1000) % 60) / 10);
        hud_ss2 setValue((total / 1000) % 10);
        hud_mmm setValue(total % 1000);

        // .02 still amounts to one server frame (50ms) - script numbers
        // cannot refresh faster than the server tick in this binary.
        wait .02;
    }
}

// ============================================================================
// floor() for 0 <= f < 10000000 via the cvar string channel (CoD1 GSC has no
// int/floor builtins; cvar int parse truncation == floor for non-negative
// input). Millions are split off first so every setcvar stays below 1e6 -
// engine float->string is only exact/reliable under that magnitude.
// Error: <=1ms per call, always toward zero.
// ============================================================================
sr_floor_big(f)
{
    hi = 0;
    if(f >= 1000000)
    {
        setcvar("rt_ih", f / 1000000);
        hi = getcvarint("rt_ih") * 1000000;
        f = f - hi;
    }
    setcvar("rt_il", f);
    return hi + getcvarint("rt_il");
}
