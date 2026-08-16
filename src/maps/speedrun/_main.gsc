// ============================================================================
// Speedrun All-in-One (1.0.3) / CoD1 SP (patch 1.3) - LOCTEXT single build
// PURE-GSC side build v0.5 ("1.1 in tenths, script-only"): the whole 1.1
// feature set with the dll layer REMOVED - no patches, no native hooks.
//
// Semantics:
//   - run total survives F9 quickloads via the archived cvar channel
//     (rt_cont_real/rt_cont_wall; the names are historical - both carry
//     LEVEL-clock ms now); same-map catch-up: a >10ms gap restores the
//     run total;
//   - timing = LEVEL CLOCK (gettime): true load screens and pre-mission
//     briefings never advance it, so they are excluded for free. The
//     ESC/menu PAUSE freezes the clock too -> pause time is NOT counted
//     (a pure script has no real-time source; the CoD4 AiO-canon frame
//     timer freezes in pause exactly the same way);
//   - two timers (v0.7.2, CoD4-AiO style): LEVEL time from the moment
//     of control (origin-delta heuristic) over the banked full total;
//   - per-level PBs with chat compare + a PB menu page (v0.7.0; menu
//     reordered to story order + left-aligned labels in v0.7.2), CoD4-AiO
//     semantics; persistence via seta lines in sr_pb.cfg), full-run PB
//     compare at the berlin final split;
//     (exe v8 tried vieworg-delta: too noisy at 300+ fps, reverted in
//      v0.7.5 back to exe v7 which field-tested as the good readout);
//   - speedometer: native engine velocity when the patched CoDSP.exe is
//     present (cvar sr_velx10 bridge, v0.6.x); otherwise SCRIPT origin-
//     delta @20Hz (horizontal units/sec from the player origin between
//     server frames; teleport spikes clamped),
//     shown via an ADAPTIVE filter: box average over sr_spd_win ticks
//     (default 10 = 0.5s) when speed is steady, an instant 2-tick
//     average whenever the change exceeds sr_spd_fast u/s (no lag on
//     jumps/landings), plus a display deadband (sr_spd_hyst),
//     HUD center; white/green/yellow/red by speed (180/230/275) + rolling
//     5s average below it (sr_spd_avg) + max tracker (rt_spd_max);
//   - PAUSE COUNTING (v0.9.0, ported from the 1.1 dll build): with the
//     patched gamex86.dll (rt_dll_api >= 14) getfractionmaxammo() returns a
//     raw GetTickCount wall clock, so ESC pauses / menus / the end-of-level
//     screen COUNT (RTA), while briefings and true loads stay excluded.
//     Stock dll -> the block is skipped and timing is level-clock as before;
//   - run_show 1: prints every split of the CURRENT run (v0.9.0);
//   - sr_debug 0|1 (default quiet): only Reset / Map Time / Run End print;
//   - NewGame autoreset (fresh-clock test + first-map briefing latch);
//   - berlin final split is anchored to the end VIDEO start: freeze after
//     cinematic() + wait(0.6) - hardcoded, identical for every runner.
// TIME READOUTS: tenths of a second (HUD MM:SS.d, chat splits, final).
// NOTE (cod1 gsc): never '!' an undefined var ("cannot cast undefined to
// bool") - level flags are read as !isdefined(level.x).
// ============================================================================

init()
{
    // ---------- cvar defaults (created on first run) ----------
    // USER SETTINGS (sr_ prefix - these are meant to be tweaked):
    sr_cvar_default("sr_speedo",     "1"); // speedometer on/off (console)
    sr_cvar_default("sr_igt",        "1"); // master switch for both rows
    // v0.17.0: per-row switches. sr_igt still hides everything at once.
    sr_cvar_default("sr_show_l",     "1"); // LEVEL row on/off
    sr_cvar_default("sr_show_fg",    "1"); // FULL GAME row on/off
    // IL MODE: only the level timer runs. The full-game row is hidden and
    // its total is not banked, so practising single levels never builds up
    // a bogus run. Level PBs still work.
    sr_cvar_default("sr_ilmode",     "0");
    sr_cvar_default("sr_spd_avg",    "1"); // rolling 5s average on/off (console)
    sr_cvar_default("sr_spd_dec",    "3"); // speedometer decimals (0..3)
    // v0.11.0: bridge scale (1000 = exe v9 thousandths, 10 = old v7/v8 exe).
    sr_cvar_default("sr_velprec",    "0"); // 0=auto, 1000=exe v9, 10=old exe
    // 1 = HUD shows the exact per-frame engine speed (needed for precise
    // skips); 0 = the old 2-tick average, smoother but blurs decimals.
    sr_cvar_default("sr_spd_raw",    "1");
    // Display deadband, u/s: the readout only repaints when it moves by at
    // least this much. 1.0 was fine for tenths but would completely hide the
    // third decimal, so it defaults to 0 now (always repaint).
    sr_cvar_default("sr_firstmap",   "training"); // New Game autoreset map
    // v0.8.4: WHERE the L (level) timer starts.
    //   1 = the frame the game WRITES THE LEVEL-START AUTOSAVE (default),
    //   0 = legacy v0.7.2 heuristic (first origin change = control gained).
    sr_cvar_default("sr_lvl_start",  "1");
    // v0.8.6: length of the intro countdown, ms. The L row counts DOWN from
    // this to zero and then up. 0 = auto (stock introscreen timing).
    // v0.9.3: ASL PARITY. 1 = match the speedrun.com autosplitter exactly
    // (yf5y2.asl): ESC pauses and death screens COUNT, but the END-OF-LEVEL
    // victory screen does NOT - the game sits at loading==0 there, which the
    // ASL treats as "loading" and stops the timer.
    // 0 = count the victory screen too (v0.8.8..v0.9.2 behaviour).
    // v0.10.0: TIMER STYLE.
    //   sr_aio 1 = CoD4 AiO style (default now): a 0.1s tick counter that
    //     counts EVERYTHING while the game is up - ESC pauses, menus, the
    //     end-of-level screen and the death screen all keep running, and the
    //     readout advances in tenths. No AiO death penalty (+4.9s) - you
    //     asked for the plain clock without it.
    //   sr_aio 0 = the ASL/LiveSplit-parity behaviour of v0.9.x (the end
    //     screen is excluded so splits match the speedrun.com autosplitter).
    // v0.12.0: ERICG08 / LEADERBOARD PRESET.
    // v0.14.0: SIMPLE RTA (sr_rta 1, default).
    // The level timer is just wall time between "the map started" and "the
    // next load begins" - nothing is classified, nothing is subtracted.
    // Everything that happens while you are ON the map counts: pauses, the
    // death screen, checkpoint hitches, low fps. Only the load screen and
    // the briefing cradle fall outside, because the map has not started /
    // has already ended by then.
    // This is deliberately dumb: no frame heuristics, no ASL flag, so there
    // is nothing left to mis-detect.
    // v0.16.0: TIMER DECIMALS - how many digits after the point the timer
    // rows show: 1 = tenths, 2 = hundredths, 3 = milliseconds (default).
    // Replaces the old sr_ericg / sr_aio / sr_asl / sr_round tangle: those
    // were four cvars describing one decision, and three of them could
    // contradict each other.
    sr_cvar_default("sr_lvl_pre",    "0"); // intro countdown length, 0 = auto
    sr_cvar_default("sr_spd_hyst",   "0"); // speedo deadband, u/s
    sr_cvar_default("sr_tmr_dec",    "3");
    sr_cvar_default("rt_rta",        "1");
    // v0.10.1: HOW the 0.1s readout is rounded.
    //   0 = down (floor, what AiO itself does)
    //   1 = nearest (default - smallest possible error)
    //   2 = up (ceil - never shows a time better than the real one)
    // ASL parity switch - only consulted when sr_aio is 0.
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
    // written every tick; both carry LEVEL-clock ms (names are historical)
    sr_cvar_default("rt_cont_real",  "0");
    sr_cvar_default("rt_cont_wall",  "0");
    sr_cvar_default("rt_cmd_mreset",  "0"); // console latch: map-timer reset
    // L-timer anchor mirror (v0.8.4): the level-clock ms of the autosave
    // frame + the map it belongs to. Cvars are process-global and are NOT
    // rolled back by a quickload, so they re-arm level.sr_lvl_off if the
    // restored script snapshot predates the anchor assignment by a frame.
    sr_cvar_default("rt_lvl_off",     "0");
    sr_cvar_default("rt_lvl_clock",   "0"); // v0.17.1: level-clock mirror
    sr_cvar_default("rt_lvl_clk0",    "0"); // v0.18.1: clock at the L anchor
    sr_cvar_default("rt_lvl_done",    "0"); // v0.18.2: level was completed
    sr_cvar_default("rt_lvl_cmap",    "");  // map the mirror belongs to
    sr_cvar_default("rt_lvl_map",     "");
    // v0.8.7: name of the map whose split was ALREADY banked at its victory
    // screen, so the next map's init() does not bank it a second time.
    sr_cvar_default("rt_banked_map",  "");
    sr_cvar_default("rt_lvl_pb_ms",   "0"); // level time taken at missionSuccess
    // WALL CLOCK / PAUSE COUNTING (v0.9.0, ported from the 1.1 dll build).
    // rt_dll_api is set ONLY by install.ps1 -Patch (fail-closed):
    //   >=1  = patched dll present (exact speedo),
    //   >=14 = the wall clock is available -> pauses count (RTA).
    sr_cvar_default("rt_dll_api",     "0");
    // v0.9.1: the SAME pause clock without any dll - the patched CoDSP.exe
    // (v8) writes GetTickCount into sr_wallms every client frame. Empty
    // cvar = stock/older exe -> pause counting stays off.
    sr_cvar_default("rt_wtotal",      "0"); // banked WALL ms across maps
    sr_cvar_default("rt_wcur_int",    "0"); // current-map WALL ms
    sr_cvar_default("rt_rta_last",    "0"); // v0.14.0: RTA elapsed mirror
    // v0.15.0: fixed tail added to every split, ms. 360 = measured average
    // of the engine time that runs after the last server frame of a map
    // (fade-out + black screen). Set 0 to disable.
    sr_cvar_default("sr_tail",       "360");
    // v0.15.1: 1 = this run was entered through a manual `map`/`devmap`,
    // so level PBs and the full-run PB are not saved. Cleared by a proper
    // New Game (or `map training`, which restarts the run from scratch).
    sr_cvar_default("rt_norun",      "0");
    sr_cvar_default("pb_show",        "0"); // console latch: print PB table
    sr_cvar_default("run_show",       "0"); // console latch: print THIS RUN splits
    sr_cvar_default("pb_wipe",        "0"); // console/menu latch: erase all PBs

    // ---------- carry over the previous map time into the run total ----------
    // New Game autoreset: (a) landing on sr_firstmap from a DIFFERENT map
    // with a nonzero total, or (b) ANY arrival on sr_firstmap with a FRESH
    // level clock (menu New Game / `map` / mission restart). Quickloads
    // never re-run init, so the fresh-clock test cannot false-trigger.
    mapname_now = getcvar("mapname");
    freshclock = (getcvarint("rt_cont_wall") > 2000
        && gettime() + 2000 < getcvarint("rt_cont_wall"));
    // v0.16.3: ANY arrival on the first map is a new run - drop the two extra
    // conditions that used to gate this. They both had holes:
    //   - "rt_run_total > 0" missed the case where the total was already
    //     zeroed but per-map state (rt_rta_last / rt_lat_prev) still held the
    //     previous run's tail, which the banking block then added back;
    //   - "different map OR fresh clock" missed New Game started while
    //     already standing on training.
    // Landing on the first map can only mean a run is (re)starting, so just
    // reset unconditionally.
    if(getcvar("sr_firstmap") != "" && mapname_now == getcvar("sr_firstmap"))
    {
        setcvar("rt_run_total", 0);
        setcvar("rt_ms_cur", 0);
        setcvar("rt_spd_max", 0);
        setcvar("rt_end_frozen", 0);
        setcvar("rt_cont_real", 0);
        setcvar("rt_cont_wall", 0);
        setcvar("rt_norun", 0); // v0.15.1: fresh run - PBs allowed again
        setcvar("rt_wtotal", 0);
        setcvar("rt_wcur_int", 0);
        sr_run_clear(); // v0.9.0: drop the previous run's split table
        // v0.16.2: the banking block further down would immediately put the
        // PREVIOUS map's time back into the freshly zeroed total (it runs
        // AFTER this reset). Clear the sources it reads, so a New Game really
        // starts from zero.
        setcvar("rt_rta_last", 0);
        setcvar("rt_lat_prev", 0);
        setcvar("rt_last_map", "");
        setcvar("rt_banked_map", "");
        sr_dbg("NEW GAME: run timer reset");
    }

    // v0.15.1: `map training` is the documented way to restart a run, so it
    // always resets the timer and clears the manual-load flag - unlike any
    // other `map X`, which taints the run instead.
    if(getcvar("mapname") == "training" && getcvar("rt_last_map") != "training")
    {
        setcvar("rt_norun", 0);
        setcvar("rt_run_total", 0);
        setcvar("rt_wtotal", 0);
        setcvar("rt_end_frozen", 0);
        sr_run_clear();
    }
    prev = getcvarint("rt_ms_cur");
    // v0.14.0: in RTA mode the split is the last value the previous map
    // mirrored before its load screen started.
    if(getcvarint("rt_rta") && getcvarint("rt_rta_last") > 0)
        prev = getcvarint("rt_rta_last");
    // v0.15.0: back to the v0.14.2 scheme - the split is the mirror written
    // by the GSC loop while the map was running, PLUS a fixed offset.
    //
    // Why the latch chain was dropped: the exe code cave is hooked into ONE
    // branch of an engine switch (the v7 speedometer hook). That branch does
    // not run every frame - the "NATIVE DEAD: sr_velx10='000000'" line is the
    // engine telling us so. Harmless while the cave only published speed, but
    // once the TIME lived there too, every skipped branch was skipped time:
    // one run drifted 81s. The GSC loop (wait .05) never skips, so the timing
    // goes back there and the cave keeps doing what it always did well.
    //
    // The offset: v0.14.2 measured -0.360s on EVERY map with a spread of only
    // 0.033s (training -0.339, pathfinder -0.364, burnville -0.364, dawnville
    // -0.372). That is the fade-out tail the engine still counts after the
    // server has already stopped running script. A constant is the honest fix
    // for a constant: no guessing what a frame gap meant.
    if(getcvarint("rt_rta") && prev > 0)
        prev = prev + getcvarint("sr_tail");
    sr_dbg("MAP ARRIVE: '" + getcvar("mapname") + "' prev-map '" + getcvar("rt_last_map")
        + "' prev " + prev + "ms brief="
        + sr_is_briefmap(getcvar("rt_last_map")));

    if(prev > 0 && sr_is_briefmap(getcvar("rt_last_map")))
    {
        // leaving a briefing level: its time is NOT banked into the run total
        sr_dbg("BRIEFMAP SKIP: '" + getcvar("rt_last_map") + "' excluded " + prev + "ms");
        setcvar("rt_wcur_int", 0);
    }
    else if(prev > 0)
    {
        // The FULL-GAME total always gets the complete map time, victory
        // screen included (v0.8.8). The level PB may already have been taken
        // at missionSuccess - rt_banked_map says so - then skip the compare.
        // v0.17.0: IL mode banks nothing into the run total - only level PBs
        // matter when you are practising single levels.
        // v0.18.2: bank the run total only for a level that was actually
        // FINISHED. `map pathfinder` typed on training looks legitimate to
        // sr_arrival_legit() - pathfinder really is the next story map - so
        // the half-played training used to be banked as a real split and the
        // whole run went out of sync. rt_lvl_done is set by the victory
        // watcher (and by the berlin cinematic), i.e. only when the level
        // ended by itself.
        // v0.19.2: bank unless the ARRIVAL ITSELF is wrong. Requiring a
        // positive "level finished" signal (0.18.2) or a nextmap handover
        // (0.19.1) both failed the same way: maps that end without a victory
        // screen produced no signal, and their split was thrown away
        // (pegasusnight). Losing real splits is far worse than occasionally
        // accepting a manual jump, so the story-order check is the gate again
        // and the finish signals only flag the run.
        if(!getcvarint("sr_ilmode")
            && sr_arrival_legit(getcvar("rt_last_map"), getcvar("mapname")))
            sr_bank_total(getcvar("rt_last_map"), prev);
        else if(!getcvarint("sr_ilmode"))
        {
            sr_dbg("MAP SKIPPED: '" + getcvar("rt_last_map")
                + "' left out of order - not counted in the run");
            setcvar("rt_norun", "1");
        }
        if(getcvar("rt_banked_map") == getcvar("rt_last_map"))
            sr_dbg("LEVEL PB already taken at the victory screen: '"
                + getcvar("rt_last_map") + "'");
        else if(sr_arrival_legit(getcvar("rt_last_map"), getcvar("mapname")))
            sr_pb_compare(getcvar("rt_last_map"), prev);
        else
        {
            // v0.15.1: reached by `map`/`devmap`, not by finishing the
            // previous level - the time is a fragment, never a PB.
            sr_dbg("MANUAL MAP LOAD: PB for '" + getcvar("rt_last_map")
                + "' not saved");
            setcvar("rt_norun", "1"); // run is tainted from here on
        }
    }

    setcvar("rt_banked_map", "");
    setcvar("rt_lvl_done", 0); // v0.18.2: armed again by the next victory
    setcvar("rt_last_map", getcvar("mapname"));
    // credits.bsp: init() normally re-arms the end trigger, which would
    // RESUME the run timer during the credits. The run ended with the
    // berlin end cinematic - stay frozen here.
    if(getcvar("mapname") == "credits")
        setcvar("rt_end_frozen", "1"); // run already ended on berlin - stay frozen
    else
        setcvar("rt_end_frozen", "0"); // a fresh map (or same-map retry) re-arms the end trigger
    level.sr_starttime = gettime();
    level.sr_fg_hold = undefined; // v0.16.2: a new map resumes the FG row
    level.sr_lvl_hold = undefined; // v0.17.0: and the L row
    setcvar("rt_ms_cur", 0);
    setcvar("rt_wcur_int", 0);
    level.sr_walllast = undefined; // re-arm the pause clock: skip first tick
    level.sr_wstart = undefined;   // wall anchor: armed once the level clock runs
    level.sr_wcur = undefined;
    // v0.13.0: zero the ASL channel for this map (the exe counter is global
    // and never resets, so we remember where the map began).
    // v0.14.0: RTA anchor. rt_rta_last is refreshed every frame while we are
    // on the map, so the value that survives into the NEXT map's init() is
    // the elapsed time as of the last frame BEFORE the load screen - the
    // load itself can no longer pollute it.
    if(getcvar("rt_wallms") != "")
    {
        level.sr_rtabase = sr_wall_now();
        if(getcvar("rt_aslms") != "")
            level.sr_aslbase = getcvarint("rt_aslms"); // same frame, no gap
        // v0.14.3: the latch is a running total too - remember where this map
        // began so the next init() can subtract it.
        // v0.14.4: the new map must start EXACTLY where the previous one
        // ended - at the latch, not at init(). init() runs several client
        // frames after the loading flag came back up (engine still bringing
        // the map up), and the engine counts that gap. Anchoring here would
        // drop it from BOTH splits: the previous one is already closed on the
        // latch, the new one would start later. Using the latch as the base
        // makes the segments butt up against each other with no hole.
        setcvar("rt_rta_last", 0);
        thread sr_rta_loop();
    }
    if(getcvar("rt_aslms") != "")
    {
        level.sr_aslbase = getcvarint("rt_aslms");
        // v0.13.2: the PRE-MISSION BRIEFING screen sits between the load and
        // actual gameplay, and init() runs BEFORE it. The engine keeps
        // accepting input there, so the ASL byte stays "live" and the exe
        // counter keeps ticking - LiveSplit's own isLoading rule drops those
        // maps whole (they are in the skipSplit list), so the briefing must
        // not land in the split either. Re-anchor once the level clock has
        // actually started, which is exactly when the briefing is over.
        thread sr_asl_rebase();
    }
    level.sr_wpin = undefined;     // v0.9.3: ASL victory-screen pin

    // fresh map arrival: drop the previous L-timer anchor and re-arm the
    // autosave listener. Quickloads never re-run init(), so an anchor that
    // belongs to THIS map always survives F9.
    setcvar("rt_lvl_off", 0);
    setcvar("rt_lvl_map", getcvar("mapname"));
    level.sr_lvl_zero = gettime() + sr_intro_len(); // v0.8.6 countdown target
    thread sr_autosave_watch(); // must be armed BEFORE the first wait
    thread sr_lvl_restart_watch(); // v0.16.3: L resets on Restart Level
    // v0.12.1: baseline of the savegame cvars. The engine rewrites them on
    // EVERY save (checkpoint included), and the disk write freezes the game
    // for 0.5-2s - which the ASL load remover cuts out and we must too.
    level.sr_lastsave = getcvar("g_lastSaveGame") + "|" + getcvar("g_internalSaveGame");
    // v0.8.7: baseline for the victory detector. `nextmap` keeps the value the
    // PREVIOUS level armed, so the test is "did it CHANGE on this map", never
    // "is it non-empty" - otherwise an ESC pause would look like a victory.
    level.sr_nextmap0 = getcvar("nextmap");
    thread sr_victory_watch();  // v0.8.7: bank the split at the victory screen

    // map-name tracker: runs on EVERY map incl. cutscene-only intros (no player
    // ent -> timer loop never starts there); keeps prev-map truthful at arrivals
    thread sr_mapname_watcher();

    // ---------- wait for the player entity ----------
    player = sr_wait_player();
    if(!isdefined(player))
        return;

    // ---------- start loops ----------
    player thread sr_timer_loop();
    player thread sr_speedo_loop();
    player thread sr_hud_loop();

    // native velocity bridge (v0.6.6): the patched CoDSP.exe registers the
    // cvar sr_velx10 and mirrors ENGINE speed into it every client frame.
    // Stock exe -> cvar absent -> automatic fallback to origin-delta.
    // The chat echo shows WHICH exe is up: '000000' = bridge v5 (good),
    // '0' = the old v0.6.0 exe (its string never updates -> dead readback).
    level.sr_native_has = (getcvar("rt_velx10") != "");
    if(level.sr_native_has)
        sr_dbg("native velocity bridge ON (sr_velx10): '" + getcvar("rt_velx10") + "'");
    // v0.18.0: settings persist by themselves now - the patched exe declares
    // every sr_* setting through Cvar_Get with the ARCHIVE flag, so the engine
    // writes them into config.cfg on exit. No "exec sr_settings.cfg" needed.
    // The cfg is still shipped as a fallback for anyone on an older exe.
    sr_dbg("Speedrun mod loaded (v1.2).");
}

// ----------------------------------------------------------------------------
sr_cvar_default(name, val)
{
    if(getcvar(name) == "")
        setcvar(name, val);
}

// ----------------------------------------------------------------------------
// INTRO COUNTDOWN (v0.8.6)
// The L row shows the intro as a COUNTDOWN (-2.8 -> -0.0) instead of a growing
// minus, so the number always runs the same direction: toward zero, then up.
// The length is known ahead of time because stock introscreen() is hardcoded:
//   0.1 (black) + 1.2 (text fade-in) + 1.0 + 0.5 (fade-out, controls back)
//   = 2.8s, plus an extra 2.0s on stalingrad.
// Maps with no intro card fall through main()'s `wait 0.05` tail instead.
// The value is only the SEED: sr_autosave_watch() re-syncs the countdown on
// the two mid-intro notifies, so a frame-rate hitch cannot desync the zero -
// and the zero itself is always the real autosave frame.
// ----------------------------------------------------------------------------
sr_intro_len()
{
    ovr = getcvarint("sr_lvl_pre");
    if(ovr > 0)
        return ovr; // manual override

    mn = getcvar("mapname");
    if(mn == "stalingrad" || mn == "stalingrad_nolight")
        return 4800; // introscreen() waits an extra 2.0s there
    if(sr_has_introcard(mn))
        return 2800; // 0.1 + 1.2 + 1.0 + 0.5
    return 50; // no card: main() just does `wait 0.05` before the notify
}

// maps that draw a place/date/time intro card (stock _introscreen::main)
sr_has_introcard(mn)
{
    return mn == "training" || mn == "pathfinder"
        || mn == "burnville" || mn == "burnville_nolight"
        || mn == "dawnville" || mn == "dawnville_nolight"
        || mn == "carride" || mn == "brecourt"
        || mn == "chateau" || mn == "powcamp"
        || mn == "pegasusnight" || mn == "pegasusday"
        || mn == "dam" || mn == "ship"
        || mn == "stalingrad" || mn == "stalingrad_nolight"
        || mn == "redsquare" || mn == "sewer"
        || mn == "factory" || mn == "tankdrivecountry"
        || mn == "hurtgen" || mn == "rocket"
        || mn == "berlin";
}

// ----------------------------------------------------------------------------
// LEVEL-START AUTOSAVE HOOK (v0.8.4)
// The stock chain is:
//   maps\_load::main()  ->  thread maps\_autosave::beginingOfLevelSave()
//     -> level waittill("finished intro screen")
//     -> maps\_utility::levelStartSave() -> saveGame("levelstart", ...)
// so that notify IS the autosave frame - the same server frame the engine
// writes save/autosave/<map>start.svg. Anchoring the L timer there makes the
// start deterministic (identical for every runner, no origin heuristics) and
// it lines up exactly with what an F9 quickload rewinds to.
// Every campaign map reaches the notify: maps with an intro card fire it right
// after freezeControls(false), the rest fall through _introscreen::main()'s
// `wait 0.05; level notify(...)` tail. Only `credits` has no level-start save.
// ----------------------------------------------------------------------------
sr_autosave_watch()
{
    thread sr_intro_resync();

    // Always listen (the flag is read AFTER the notify, so flipping the menu
    // toggle mid-map still takes effect on this very map).
    level waittill("finished intro screen");

    if(getcvarint("sr_lvl_start") != 1)
        return; // legacy origin-delta mode owns the start (sr_lvl_start 0)
    if(getcvar("mapname") == "credits")
        return; // beginingOfLevelSave() returns early there: no save is written
    if(sr_is_briefmap(getcvar("mapname")))
        return; // briefing levels are outside the run anyway

    // v0.15.3: back to the notify. v0.15.2 waited for the actual disk write
    // (g_lastSaveGame changing) because pathfinder looked like it saved late -
    // field-checked and reverted: the fades line up fine as they are.
    sr_lvl_anchor("level-start autosave");
}

// ----------------------------------------------------------------------------
// ONE CLOCK FOR BOTH ROWS (v0.9.6)
// sr_map_ms() = milliseconds elapsed on THIS map, taken from the very same
// channel the run total is banked from:
//   * wall channel (exe bridge) when it is live - pause-inclusive, ~1ms, and
//     re-anchored to the save moment by the quickload detector (sr_wrel);
//   * otherwise the level clock, whose sr_starttime is stretched by every
//     counted pause and restored on quickloads by the same detector.
// The LEVEL row is then simply sr_map_ms() minus the offset captured when the
// level timer started. Because both rows read one source, L now inherits
// EVERYTHING the full-game row does - counted pauses and save rollbacks - for
// free, instead of running on its own untouched gettime() anchor.
// ----------------------------------------------------------------------------
// TRUE ASL CLOCK (v0.13.0, exe v10).
// The patched exe now accumulates time itself, using the very byte the
// speedrun.com autosplitter reads ("game not accepting inputs"): a frame is
// counted only when that flag says the game is live. Level loads, checkpoint
// writes and every other engine freeze are excluded AT THE SOURCE, so the
// script no longer has to guess what a gap in the frames meant - which is
// what kept costing us a couple of seconds per save-heavy map.
// Re-zero the ASL channel at the first frame the level clock moves.
// gettime() is frozen during the briefing cradle, so the moment it advances
// is the moment gameplay begins - everything before that (briefing screen,
// the "press any key" wait) is dropped from the map time, matching the
// autosplitter.
// Keep the map's RTA elapsed mirrored into a cvar every frame.
// A cvar is NOT rolled back by a quickload and NOT reset by a map change, so
// the next map's init() can read the final value even though every level.*
// variable is long gone by then.
sr_rta_loop()
{
    if(getcvar("rt_wallms") == "")
        return;
    mymap = getcvar("mapname");
    for(;;)
    {
        wait .05;
        if(getcvar("mapname") != mymap && getcvar("mapname") != "")
            return; // moved on; the last written value is the split
        // v0.14.1: mirror the ASL channel when the exe provides it. The exe
        // only ticks while the game accepts input, so level loads AND the
        // checkpoint-write freezes are already excluded AT THE SOURCE -
        // which is exactly what LiveSplit's Game Time shows. Video proof:
        // across a load GT moved +0.006s while RT moved +4.662s.
        // Plain wall time stays as the fallback for an un-patched exe.
        a = sr_asl_ms();
        if(a >= 0 && isdefined(level.sr_aslbase))
            t = a - level.sr_aslbase;
        else
            t = sr_wall_now() - level.sr_rtabase;
        if(t < 0)
            t = 0; // GetTickCount fold wrapped - keep it sane
        setcvar("rt_rta_last", t);
    }
}

sr_asl_rebase()
{
    if(getcvar("rt_aslms") == "")
        return;
    t0 = gettime();
    for(i = 0; i < 400; i++) // up to 20s of briefing
    {
        wait .05;
        if(gettime() > t0)
        {
            level.sr_aslbase = getcvarint("rt_aslms");
            sr_dbg("ASL channel re-anchored after the briefing screen");
            return;
        }
    }
}

sr_asl_ms()
{
    if(getcvar("rt_aslms") == "")
        return -1; // exe older than v10 -> caller falls back
    return getcvarint("rt_aslms");
}

sr_map_ms()
{
    // v0.14.0: plain RTA on this map - wall time since the map started.
    if(getcvarint("rt_rta") && isdefined(level.sr_rtabase) && getcvar("rt_wallms") != "")
    {
        a = sr_asl_ms();
        if(a >= 0 && isdefined(level.sr_aslbase))
            t = a - level.sr_aslbase;
        else
            t = sr_wall_now() - level.sr_rtabase;
        if(t < 0)
            t = 0;
        return t;
    }
    // exe v10 channel first: it is the same rule LiveSplit applies.
    a = sr_asl_ms();
    if(a >= 0 && isdefined(level.sr_aslbase))
        return a - level.sr_aslbase;
    if(sr_wall_ok() && isdefined(level.sr_wcur))
        return sr_floor_big(level.sr_wcur);
    return gettime() - level.sr_starttime;
}

// DISPLAY rounding to the AiO 0.1s grid (v0.10.1).
// IMPORTANT: this is applied ONLY when a number is shown. Everything that is
// STORED - splits, PBs, the run total - keeps full millisecond precision.
// v0.10.0 rounded the split itself before banking it, so the error piled up
// map after map (~1.3s over a 26-map run with floor or ceil). Rounding at the
// readout instead caps the error at 0.099s for the WHOLE run, no matter how
// many maps, because the sum underneath is always exact.
sr_quant(t)
{
    // Round the DISPLAY to sr_tmr_dec digits. Stored values always keep full
    // millisecond precision, so the error never accumulates across a run.
    if(t <= 0)
        return 0;
    d = getcvarint("sr_tmr_dec");
    if(d >= 3)
        return t;                       // milliseconds: nothing to round
    if(d == 2)
        return ((t + 5) / 10) * 10;     // hundredths
    return ((t + 50) / 100) * 100;      // tenths
}

// current LEVEL-row value in ms (0 before the level timer is armed)
sr_lvl_now()
{
    if(!isdefined(level.sr_lvl_off))
        return 0;
    t = sr_map_ms() - level.sr_lvl_off;
    if(t < 0)
        t = 0; // quickload landed before the level-start anchor
    return t;
}

// Restart Level / loading an autosave must put the LEVEL row back to zero.
// Neither re-runs init() (the map stays loaded), so nothing else notices.
// What does change: the engine writes a new savegame name on the load, and
// the level clock jumps backwards. Either of those means "this level started
// over" - so drop the anchor and let the normal start logic arm it again.
sr_lvl_restart_watch()
{
    // Restart Level / loading an autosave must put the LEVEL row back to zero.
    // Neither re-runs init() - the map stays loaded - so nothing else notices.
    //
    // v0.17.1: the previous version compared gettime() against a value kept
    // in a local variable, and that CANNOT work: a savegame restores the whole
    // script state, so the local rewinds together with the clock and the two
    // stay consistent. The rewind is invisible from inside the script.
    // Cvars are NOT rolled back, so the level clock is mirrored into one and
    // compared against that - same trick the quickload guard uses.
    for(;;)
    {
        wait .05;
        cl = gettime();
        mirror = getcvarint("rt_lvl_clock");
        setcvar("rt_lvl_clock", cl);
        if(getcvar("rt_lvl_cmap") != getcvar("mapname"))
        {
            setcvar("rt_lvl_cmap", getcvar("mapname"));
            continue; // new map: init() already handled the anchor
        }
        if(mirror <= 0 || cl + 250 >= mirror)
            continue; // clock moved forward as usual

        // Clock jumped BACKWARDS on the same map = a savegame was loaded.
        // v0.18.1: that is true for BOTH Restart Level and a quicksave load,
        // and they must behave differently:
        //   Restart Level -> loads save/autosave/<map>.svg, i.e. the
        //     level-start save, so the clock lands back AT the L anchor and
        //     the level really does start over -> reset L.
        //   F9 quickload  -> lands wherever you saved, later in the level;
        //     L must simply roll back with it, NOT restart from zero.
        // rt_lvl_clk0 holds the level clock captured when L was armed; cvars
        // survive the load, so comparing against it separates the two cases.
        if(getcvarint("rt_lvl_clk0") > 0 && cl > getcvarint("rt_lvl_clk0") + 1000)
            continue; // landed mid-level = quickload, leave the timer alone
        if(!isdefined(level.sr_lvl_off) && !isdefined(level.sr_lvl_ctime))
            continue; // timer was not running anyway
        level.sr_lvl_off = undefined;
        level.sr_lvl_ctime = undefined;
        level.sr_lvl_zero = undefined;
        level.sr_lvl_mapstart = gettime();
        level.sr_vic_frozen = undefined;
        level.sr_lvl_hold = undefined; // a real restart clears the reset hold
        // The intro notify will not fire again on this map, so anchor now:
        // loading a save means the level is already under way.
        level.sr_lvl_off = sr_map_ms();
        setcvar("rt_lvl_off", level.sr_lvl_off);
        setcvar("rt_lvl_map", getcvar("mapname"));
        sr_dbg("LEVEL TIMER: reset (level restarted)");
    }
}

// single entry point for "the level timer starts NOW" - first anchor wins
sr_lvl_anchor(src)
{
    if(isdefined(level.sr_lvl_off))
        return;
    if(isdefined(level.sr_lvl_hold))
        return; // v0.17.0: reset in progress - stay at zero until a new map
    // store an OFFSET INTO THE MAP CLOCK, not an absolute timestamp: the map
    // clock is the thing that gets stretched by pauses and rewound by loads,
    // so an offset keeps L glued to FG through both.
    level.sr_lvl_off = sr_map_ms();
    setcvar("rt_lvl_off", level.sr_lvl_off);
    setcvar("rt_lvl_map", getcvar("mapname"));
    // v0.18.1: remember the LEVEL CLOCK at the anchor. Used to tell a Restart
    // Level (loads the level-start autosave -> clock lands back here) from a
    // quicksave load (lands wherever you saved, later in the level).
    setcvar("rt_lvl_clk0", gettime());
    sr_dbg("LEVEL TIMER: started at " + src + " (map offset "
        + level.sr_lvl_off + "ms)");
}

// Keep the countdown honest: stock introscreen() fires two notifies on its way
// out, and the remaining time after each is a fixed constant. Re-seating the
// zero on them means a long frame during the fade cannot drift the readout.
sr_intro_resync()
{
    level endon("finished intro screen");

    level waittill("finished final intro screen fadein");
    // remaining: wait 1 -> fadeout notify -> wait 0.5 -> controls + save
    level.sr_lvl_zero = gettime() + 1500;

    level waittill("starting final intro screen fadeout");
    level.sr_lvl_zero = gettime() + 500; // remaining: wait 0.5
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
sr_mapname_watcher()
{
    for(;;)
    {
        // mapname is EMPTY during _load init on some transition flows; keep the
        // tracker live so the next map's arrival always sees the real prev map
        mn = getcvar("mapname");
        if(mn != "" && mn != getcvar("rt_last_map"))
            setcvar("rt_last_map", mn);
        wait 1;
    }
}

sr_is_briefmap(name)
{
    // interlude/briefing maps: their time is excluded from the run total
    return name == "allied_start" || name == "ru_stalingrad"
        || name == "uk_6ab" || name == "uk_sas"
        || name == "us_intro" || name == "us_mid";
}

// ----------------------------------------------------------------------------
// VICTORY SCREEN WATCH (v0.8.7)
// Goal: the level timer reports itself the moment the END-OF-LEVEL screen
// starts, not on the next map's loading screen.
//
// How the end of a level actually works in CoD1:
//   the map script calls the BUILT-IN missionSuccess("nextmap", true), which
//   is engine code (gamex86.dll) - a pure-GSC mod cannot hook the call. What
//   it CAN see is the state the engine puts up for ui/victoryscreen.menu:
//   the menu opens fullscreen and its onOpen sets cl_paused 1, and the engine
//   arms `nextmap` for the Continue button.
// So the signal is: `nextmap` CHANGED on this map + the player is alive.
// ESC-pause and the in-game menus never write nextmap, and a death goes to
// the dead screen (isalive test), so neither can trigger this.
//
// Why not test cl_paused as well: victoryscreen.menu pauses the game in its
// onOpen, and a paused server executes NO script frames - waiting for that
// state would deadlock the loop. missionSuccess() writes nextmap one frame
// EARLIER, while the server still ticks, so we catch the handover itself.
// The banked number is the level clock at the end of gameplay; the screen
// never advances it.
// The chat split is printed too, but it is only readable once the fullscreen
// menu is gone (the engine draws no chat under it) - the VALUE is what
// matters here: PBs are written immediately instead of one map later.
// ----------------------------------------------------------------------------
sr_victory_watch()
{
    level endon("sr_victory_banked");

    mymap = getcvar("mapname");
    if(mymap == "" || mymap == "credits" || sr_is_briefmap(mymap))
        return;
    // berlin has NO victory screen: it ends on the cod_end.roq cinematic and
    // its script sets `nextmap "map credits"` BY HAND a moment before that.
    // That write looks exactly like missionSuccess() to the detector, so the
    // watcher would fire ~0.6s early and steal the split. The end-cinematic
    // hook (rt_end_frozen) owns berlin instead - see the final-split block.
    if(mymap == "berlin")
        return;

    for(;;)
    {
        wait .05;

        if(getcvarint("rt_end_frozen"))
            return; // berlin final split owns the end of the run
        if(getcvar("mapname") != mymap)
            return; // already moved on: init() on the new map banks it
        if(!sr_victory_up())
            continue;

        // v0.9.4: take the PB from the SAME clock the split is banked from.
        // Before, the PB used the level clock while sr_bank_total used the
        // wall channel, so the chat could disagree with itself by ~0.2s
        // (e.g. "NEW LEVEL PB 02:27.9" next to a 02:27.681 split).
        t = gettime() - level.sr_starttime;
        t = sr_map_ms(); // v0.13.2: one clock for PB and split
        if(t <= 0)
            continue;

        // freeze the L row exactly here, then bank the split
        if(isdefined(level.sr_lvl_off) && !isdefined(level.sr_lvl_ctime))
            level.sr_lvl_ctime = sr_lvl_now();
        // ASL parity: pin the wall elapsed on THIS frame - the victory screen
        // starts now and must not leak into the banked number.
        if(sr_asl_on() && !isdefined(level.sr_wpin) && isdefined(level.sr_wcur))
            level.sr_wpin = level.sr_wcur;

        // v0.8.8: take the PB HERE (pure gameplay, comparable), but do NOT
        // bank the total yet - the victory screen itself still counts toward
        // the full-game time, so rt_ms_cur keeps accruing until the map ends.
        setcvar("rt_lvl_pb_ms", t);
        setcvar("rt_banked_map", mymap);
        setcvar("rt_lvl_done", 1); // v0.18.2: level finished for real
        sr_pb_compare(mymap, t);
        sr_dbg("VICTORY SCREEN: level PB taken on '" + mymap + "' at " + t + "ms");

        // freeze only the L ROW readout; the clock behind it keeps running
        level.sr_vic_frozen = 1;
        if(isdefined(level.sr_lvl_off) && !isdefined(level.sr_lvl_ctime))
            level.sr_lvl_ctime = sr_lvl_now();
        level notify("sr_victory_banked");
        return;
    }
}

// Did the gap we just measured come from the game WRITING A SAVE?
// The ASL load remover hooks "game not accepting inputs because it's
// loading", and that flag is up not only on level loads but also while a
// checkpoint save is being compressed and written to disk (the
// "G_SaveGame: Compressed N bytes" line in the console). The game freezes
// there for 0.5-2s, LiveSplit does not count it - so neither may we, or the
// run drifts a couple of seconds long on save-heavy maps (measured:
// burnville +2.76s, chateau +1.23s against LiveSplit).
// The engine rewrites g_lastSaveGame / g_internalSaveGame on every write, so
// a gap that coincides with those cvars changing is a save, not a pause.
sr_save_gap()
{
    now = getcvar("g_lastSaveGame") + "|" + getcvar("g_internalSaveGame");
    if(!isdefined(level.sr_lastsave))
    {
        level.sr_lastsave = now;
        return false;
    }
    if(now == level.sr_lastsave)
        return false;
    level.sr_lastsave = now; // remember the new save name
    return true;
}

// Did the gap we just measured belong to the END-OF-LEVEL screen?
// Race-free version of sr_victory_up(): it does not need the watcher to have
// observed anything, it just asks whether the engine has handed over to the
// next map (nextmap changed on this map) while the player is alive.
sr_victory_gap()
{
    nm = getcvar("nextmap");
    if(nm == "")
        return false;
    if(isdefined(level.sr_nextmap0) && nm == level.sr_nextmap0)
        return false;
    if(isdefined(level.player) && !isalive(level.player))
        return false; // dead screen: ASL counts that one
    return true;
}

// is the end-of-level screen up right now?
sr_victory_up()
{
    // TRIGGER = `nextmap` changing, which missionSuccess() does as it hands
    // over to the victory screen.
    // Deliberately NOT testing cl_paused: victoryscreen.menu pauses the game
    // in its onOpen, and a paused server runs NO script frames - a loop that
    // waited for the paused state would simply never run again. The nextmap
    // write lands a frame earlier, while the server still ticks, so this is
    // both observable and exactly "the end screen is starting".
    nm = getcvar("nextmap");
    if(nm == "")
        return false;
    if(isdefined(level.sr_nextmap0) && nm == level.sr_nextmap0)
        return false; // unchanged since map start = leftover from the last level
    if(isdefined(level.player) && !isalive(level.player))
        return false; // died: the dead screen, not a victory
    return true;
}

// ----------------------------------------------------------------------------
// Bank one finished level: add it to the run total, print the split and run
// the PB compare. Called from TWO places (v0.8.7):
//   - sr_victory_watch(), the instant that level's victory screen starts;
//   - init() on the next map, for anything that ended without one.
// rt_banked_map keeps the two from double-counting the same level.
// ----------------------------------------------------------------------------
sr_bank_total(mapkey, prev)
{
    // wall channel (dll patch): bank the pause-inclusive number instead, so
    // the printed split and the run total match the RTA clock in the HUD.
    // v0.13.2: the split MUST come from the same clock the HUD shows.
    // Before, this read rt_wcur_int (the old heuristic wall channel) even
    // when the exe v10 ASL channel was live - so the HUD was right while the
    // banked split still carried whatever the guesswork produced. That is why
    // the error had no consistent sign (burnville -1.27s, chateau +4.28s).
    aprev = sr_map_ms();
    if(getcvarint("rt_rta"))
    {
        // prev already holds the RTA split (set by the caller); just bank it.
        setcvar("rt_wtotal", getcvarint("rt_wtotal") + prev);
    }
    else if(sr_asl_ms() >= 0 && isdefined(level.sr_aslbase) && aprev > 0)
    {
        prev = aprev; // exe-measured, ASL-exact
        setcvar("rt_wtotal", getcvarint("rt_wtotal") + aprev);
    }
    else
    {
        wprev = getcvarint("rt_wcur_int");
        if(sr_wall_ok() && wprev > 0)
        {
            prev = wprev;
            setcvar("rt_wtotal", getcvarint("rt_wtotal") + wprev);
        }
    }
    total = getcvarint("rt_run_total") + prev;
    setcvar("rt_run_total", total);

    // v0.9.0: remember THIS RUN's split for `run_show` - rs_<map> = the map
    // time in ms, rc_<map> = the cumulative run total at that point. Session
    // cvars on purpose (not seta): a run table should not outlive the run.
    setcvar("rs_" + mapkey, prev);
    setcvar("rc_" + mapkey, total);
    // v0.16.0: display string for the Run Splits menu page - same idea as
    // pbs_<map> for the PB page. "MM:SS.mmm +d" where d is the delta to the
    // level PB (blank when there is no PB yet).
    rstr = sr_ms_str(prev);
    pbv = getcvarint("pb_" + mapkey);
    if(pbv > 0)
    {
        if(prev <= pbv)
            rstr = rstr + " PB";
        else
        {
            // v0.16.1: short delta (SS.d) - the full MM:SS.mmm form made the
            // line overflow its column and spill onto the second half of the
            // page. Minutes are shown only when the loss is that big.
            dms = prev - pbv;
            if(dms >= 60000)
                rstr = rstr + " +" + (dms / 60000) + "m";
            else
                rstr = rstr + " +" + (dms / 1000) + "." + ((dms / 100) % 10);
        }
    }
    setcvar("rss_" + mapkey, rstr);
    setcvar("rss_total", sr_ms_str_h(total));

    // chat splits: level-clock ms, padded like the HUD: MM:SS.d | H:MM:SS.d
    dprev = sr_quant(prev); dtotal = sr_quant(total); // 0.1s grid on display
    pmm = dprev / 60000; pss = (dprev / 1000) % 60; pds = (dprev / 100) % 10;
    thh = dtotal / 3600000; tmm = (dtotal / 60000) % 60;
    tss = (dtotal / 1000) % 60; tds = (dtotal / 100) % 10;
    if(sr_ms_on())
        sr_text("MAP TIME " + sr_pad2(pmm) + ":" + sr_pad2(pss) + "." + sr_pad3(prev % 1000)
            + " | RUN TOTAL " + thh + ":" + sr_pad2(tmm) + ":" + sr_pad2(tss) + "." + sr_pad3(total % 1000));
    else
        sr_text("MAP TIME " + sr_pad2(pmm) + ":" + sr_pad2(pss) + "." + pds
            + " | RUN TOTAL " + thh + ":" + sr_pad2(tmm) + ":" + sr_pad2(tss) + "." + tds);
}

// PB compare for one level. Split off from the total banking in v0.8.8:
// the PB is taken at missionSuccess (pure gameplay time, comparable between
// runs), while the run TOTAL keeps accruing past that point so the victory
// screen is not silently dropped from the full-game time.
sr_pb_compare(mapkey, prev)
{
    dprev = sr_quant(prev); // display grid only - the PB is stored exact
    pmm = dprev / 60000; pss = (dprev / 1000) % 60; pds = (dprev / 100) % 10;
    pbkey = "pb_" + mapkey;
    pbold = getcvarint(pbkey);
    if(pbold <= 0 || prev < pbold)
    {
        setcvar(pbkey, prev);
        if(sr_ms_on())
            pstr = sr_pad2(pmm) + ":" + sr_pad2(pss) + "." + sr_pad3(prev % 1000);
        else
            pstr = sr_pad2(pmm) + ":" + sr_pad2(pss) + "." + pds;
        setcvar("pbs_" + mapkey, pstr);
        sr_text("NEW LEVEL PB: " + pstr + "!");
    }
    else
    {
        bmm = pbold / 60000; bss = (pbold / 1000) % 60; bds = (pbold / 100) % 10;
        dms = prev - pbold;
        dmm = dms / 60000; dss = (dms / 1000) % 60; dds = (dms / 100) % 10;
        sr_text("PB " + sr_pad2(bmm) + ":" + sr_pad2(bss) + "." + bds
            + " | delta +" + sr_pad2(dmm) + ":" + sr_pad2(dss) + "." + dds);
    }
}

// ----------------------------------------------------------------------------
// WALL CLOCK SOURCE (v0.9.1) - no dll required.
// The patched CoDSP.exe (v8) publishes GetTickCount() into the cvar
// sr_wallms every client frame, exactly the way v7 publishes sr_velx10.
// That is the same millisecond source the 1.1 dll build exposes through
// getfractionmaxammo(), so the pause logic below is unchanged - only the
// READ differs. Priority: exe bridge first, dll builtin second (if someone
// runs this pk3 on top of the patched dll), otherwise pause counting is off.
// ----------------------------------------------------------------------------
// ASL parity is only active in non-AiO mode: the AiO clock counts the
// end-of-level screen like everything else.
sr_asl_on()
{
    return true; // v0.16.0: ASL parity is the only timing mode now
}

// milliseconds on the HUD? The preset says yes; otherwise follow sr_aio
// (the AiO look is a 0.1s grid, so it shows tenths only).
sr_ms_on()
{
    return getcvarint("sr_tmr_dec") >= 3; // .mmm strings in chat/PB
}

// Scale of the sr_velx10 bridge. exe v9 writes speed*1000, older builds
// wrote speed*10. Both are fixed-width %06d, so the value alone cannot tell
// them apart - sr_velprec pins it (1000 = v9, this pack; 10 = old exe).
sr_vel_scale()
{
    p = getcvarint("sr_velprec");
    if(p == 10)
        return 10.0;    // forced: old v7/v8 exe (x10)
    if(p == 1000)
        return 1000.0;  // forced: v9 exe (x1000)

    // AUTO (sr_velprec 0, default since v0.11.1) - the pack ships exe v9,
    // but somebody may still be running v7/v8, and guessing wrong is silent
    // and ugly: the whole readout comes out 100x too small (a 190 u/s sprint
    // shows as 1.90, slow movement rounds to 0.000). That was the "speedo
    // drops to 0" report.
    // A single sample cannot separate the two scales - 2000 is "2.0 u/s on
    // v9" or "200 u/s on v8". The SESSION PEAK can: once the raw value has
    // ever exceeded 5000, the x10 reading would mean 500 u/s, which is far
    // beyond anything reachable in CoD1 (~300 u/s with bhop). So a peak that
    // high proves v9, and until then we stay on the old x10 scale, which is
    // the safe guess - it only ever reads 100x HIGH on a v9 exe for a moment
    // at very low speed, instead of hiding movement entirely.
    if(isdefined(level.sr_velscale))
        return level.sr_velscale;
    raw = getcvarint("rt_velx10");
    if(!isdefined(level.sr_velpeak) || raw > level.sr_velpeak)
        level.sr_velpeak = raw;
    if(level.sr_velpeak > 5000)
    {
        level.sr_velscale = 1000.0; // latched for the session
        sr_dbg("speedo bridge: exe v9 detected (x1000 scale)");
        return 1000.0;
    }
    return 10.0;
}

sr_wall_src()
{
    if(getcvar("rt_wallms") != "")
        return "exe v8";
    return "dll v14";
}

sr_wall_ok()
{
    if(getcvar("rt_wallms") != "")
        return true;                       // exe v8 bridge is live
    return getcvarint("rt_dll_api") >= 14;  // legacy dll build
}

// Wall clock WITHOUT touching self - safe to call from init() and from any
// level thread. (sr_wall_read() below falls back to a player-scoped builtin
// for the legacy dll bridge, so it must never be called outside a player
// thread; the RTA path uses this one instead.)
sr_wall_now()
{
    if(getcvar("rt_wallms") == "")
        return -1;
    return getcvarint("rt_wallms") % 10000000;
}

sr_wall_read()
{
    if(getcvar("rt_wallms") != "")
    {
        // GetTickCount wraps every ~49.7 days and exceeds the range where
        // this engine's float<->string stays exact, so fold it into a
        // 10,000,000 ms window (~2.7h). Only DIFFERENCES are ever used, and
        // the fold is applied consistently, so a wrap costs at most one
        // discarded gap - never a wrong split.
        return getcvarint("rt_wallms") % 10000000;
    }
    return self getfractionmaxammo();
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

// ----------------------------------------------------------------------------
// RUN SPLIT TABLE (v0.9.0) - `run_show 1` prints every split of the CURRENT
// run: per-level time, the running total at that level, and the delta vs the
// level PB. Lives in session cvars rs_<map>/rc_<map> written by sr_bank_total.
// ----------------------------------------------------------------------------
sr_run_clear()
{
    setcvar("rss_total", "");
    mm = sr_pb_maplist();
    for(i = 0; i < mm.size; i++)
    {
        setcvar("rs_" + mm[i], "0");
        setcvar("rc_" + mm[i], "0");
        setcvar("rss_" + mm[i], "");
    }
}

// ms -> "MM:SS.mmm" (levels never reach an hour)
sr_ms_str(t)
{
    t = sr_quant(t);
    return sr_pad2(t / 60000) + ":" + sr_pad2((t / 1000) % 60) + "." + sr_pad3(t % 1000);
}

// ms -> "H:MM:SS.mmm" for the cumulative column
sr_ms_str_h(t)
{
    t = sr_quant(t);
    return (t / 3600000) + ":" + sr_pad2((t / 60000) % 60) + ":"
        + sr_pad2((t / 1000) % 60) + "." + sr_pad3(t % 1000);
}

sr_run_print()
{
    sr_text("== THIS RUN - SPLITS ==");
    mm = sr_pb_maplist();
    shown = 0;
    for(i = 0; i < mm.size; i++)
    {
        t = getcvarint("rs_" + mm[i]);
        if(t <= 0)
            continue; // level not played in this run yet
        shown++;
        line = mm[i] + ": " + sr_ms_str(t)
            + "  [" + sr_ms_str_h(getcvarint("rc_" + mm[i])) + "]";
        pb = getcvarint("pb_" + mm[i]);
        if(pb > 0)
        {
            if(t <= pb)
                line = line + "  PB!";
            else
            {
                d = t - pb;
                line = line + "  +" + sr_ms_str(d);
            }
        }
        sr_text(line);
    }
    if(!shown)
    {
        sr_text("(no splits yet - finish a level first)");
        return;
    }
    // live total: banked run + whatever the current map has accrued
    if(getcvarint("rt_end_frozen"))
        tot = getcvarint("rt_run_total");
    else
        tot = getcvarint("rt_run_total") + getcvarint("rt_ms_cur");
    sr_text("RUN TOTAL: " + sr_ms_str_h(tot));
}

sr_pb_line(mn)
{
    s = getcvar("pbs_" + mn);
    if(s == "")
        s = "-";
    sr_text("PB " + mn + ": " + s);
}

// clear one map's PB pair (ms + display string)
sr_pb_clear(mn)
{
    setcvar("pb_" + mn, "0");
    setcvar("pbs_" + mn, "");
}

// campaign maps in STORY order - the single source of truth for the PB
// table, the wipe and the "anything to erase?" test.
// Did the engine hand over to THIS map, or did someone type `map <name>`?
// missionSuccess() sets  nextmap = "map <next>"  as it ends a level, and a
// manual map/devmap never touches that cvar. So on arrival we simply ask:
// does nextmap point at the map we are standing on?
//
// v0.19.1: this replaces the rt_lvl_done flag from 0.18.2, which was set ONLY
// by the victory-screen watcher. Levels that hand over some other way -
// pegasusnight is one, berlin is another - never set it, so their splits were
// thrown away ("MAP SKIPPED"). Reading nextmap is state, not an event: no
// watcher has to catch anything, and it works for every transition style.
sr_engine_handover(curmap)
{
    nm = getcvar("nextmap");
    if(nm == "")
        return false;
    return nm == "map " + curmap || nm == curmap;
}

// Position of a map in story order, -1 if unknown (custom map).
sr_map_index(mn)
{
    mm = sr_pb_maplist();
    for(i = 0; i < mm.size; i++)
    {
        if(mm[i] == mn)
            return i;
    }
    return 0 - 1;
}

// Was this map reached by PLAYING the campaign, or typed into the console?
// A legit arrival is the next story map after the one we just finished
// (briefing levels sit between them and are skipped by the index list).
// `map burnville` from the console jumps the chain, so the level time is
// only a fragment of a real run and must not become a PB.
// Exception handled by the caller: training always resets and is allowed.
sr_arrival_legit(prevmap, curmap)
{
    if(prevmap == "" || prevmap == curmap)
        return true;              // first map of the session, or a retry
    if(sr_is_briefmap(prevmap))
        return true;              // came through a journal screen - normal
    pi = sr_map_index(prevmap);
    ci = sr_map_index(curmap);
    if(pi < 0 || ci < 0)
        return true;              // custom map: do not police it
    return ci == pi + 1;          // strictly the next level in story order
}

sr_pb_maplist()
{
    m = [];
    m[m.size] = "training";         m[m.size] = "pathfinder";
    m[m.size] = "burnville";        m[m.size] = "dawnville";
    m[m.size] = "carride";          m[m.size] = "brecourt";
    m[m.size] = "chateau";          m[m.size] = "powcamp";
    m[m.size] = "pegasusnight";     m[m.size] = "pegasusday";
    m[m.size] = "dam";              m[m.size] = "truckride";
    m[m.size] = "airfield";         m[m.size] = "ship";
    m[m.size] = "stalingrad";       m[m.size] = "redsquare";
    m[m.size] = "trainstation";     m[m.size] = "sewer";
    m[m.size] = "pavlov";           m[m.size] = "factory";
    m[m.size] = "railyard";         m[m.size] = "tankdrivecountry";
    m[m.size] = "tankdrivetown";    m[m.size] = "hurtgen";
    m[m.size] = "rocket";           m[m.size] = "berlin";
    return m;
}

// is there any PB left to erase? (used to keep the latch quiet)
sr_pb_any()
{
    if(getcvarint("pb_full") > 0)
        return true;
    mm = sr_pb_maplist();
    for(i = 0; i < mm.size; i++)
    {
        if(getcvarint("pb_" + mm[i]) > 0)
            return true;
    }
    return false;
}

// erase every stored PB - level times AND the full run (v0.8.5)
sr_pb_wipe_all()
{
    mm = sr_pb_maplist();
    for(i = 0; i < mm.size; i++)
        sr_pb_clear(mm[i]);
    setcvar("pb_full", "0");
    setcvar("pbs_full", "");
}

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
// Also owns the continuity channels (archived cvars), the NewGame safety
// latch and the final split.
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
            if(gap > 10)
            {
                wasload = 1;
                level.sr_starttime = gettime() - (getcvarint("rt_cont_real") - getcvarint("rt_run_total"));
                setcvar("rt_ms_cur", getcvarint("rt_cont_real") - getcvarint("rt_run_total"));
                cont_disp = getcvarint("rt_cont_real");
                // wall anchor re-sync: THIS-MAP elapsed at the save moment.
                // (Re-anchoring to the FULL total would count rt_wtotal twice.)
                level.sr_wrel = cont_disp - getcvarint("rt_run_total");
                sr_dbg("LOAD: total continued from " + (cont_disp / 1000) + "s");
            }
        }
        setcvar("rt_cont_real", cont_disp);
        setcvar("rt_cont_wall", gettime());

        // ---- LEVEL timer start marker (v0.8.4: AUTOSAVE-anchored) -----
        // Default (sr_lvl_start 1): the anchor is set by sr_autosave_watch()
        // on the level-start autosave frame. This loop only keeps the intro
        // reference point and re-arms the anchor after a quickload.
        // Legacy (sr_lvl_start 0): the old v0.7.2 heuristic - control ~= the
        // first origin change vs where the loop first saw the player (scripted
        // ride intros move the origin without control, so it can fire early).
        if(!isdefined(level.sr_lvl_org))
        {
            level.sr_lvl_org = self.origin;
            level.sr_lvl_mapstart = gettime(); // v0.8.1: negative intro phase
        }

        // F9 guard: saveGame() and our anchor assignment land on the SAME
        // server frame, so a restored snapshot can predate the assignment.
        // The cvar mirror is not rolled back by a load -> re-arm from it.
        if(!isdefined(level.sr_lvl_off)
            && !isdefined(level.sr_lvl_hold) // v0.17.0: respect the reset hold
            && getcvarint("rt_lvl_off") > 0
            && getcvar("rt_lvl_map") == getcvar("mapname"))
        {
            level.sr_lvl_off = getcvarint("rt_lvl_off");
            sr_dbg("LEVEL TIMER: anchor restored from cvar (quickload)");
        }

        if(getcvarint("sr_lvl_start") != 1
            && !isdefined(level.sr_lvl_off)
            && distance(self.origin, level.sr_lvl_org) > 4)
            sr_lvl_anchor("control gained (origin delta)");

        // Safety net: a custom/edited map that never fires the notify would
        // otherwise leave L stuck in the negative intro phase forever. After
        // 20s of level clock WITH the player actually moving, fall back to the
        // old heuristic so the row still produces a usable number.
        if(getcvarint("sr_lvl_start") == 1
            && !isdefined(level.sr_lvl_off)
            && gettime() - level.sr_lvl_mapstart > 20000
            && distance(self.origin, level.sr_lvl_org) > 4)
            sr_lvl_anchor("FALLBACK: no level-start autosave seen in 20s");

        // ---- pause/menu time COUNTS (RTA, dll wall clock) -------------
        // Ported from the 1.1 dll build (v0.9.0). getfractionmaxammo() with
        // NO args is patched to return raw GetTickCount ms as a float - a
        // HUGE number (ms since Windows boot), so it lives in LEVEL float
        // vars only, never in a cvar (%g would mangle it); nearby big floats
        // still subtract exactly.
        // Script frames do not run while ESC / the victory screen is open ->
        // one long off-script gap == a pause, and it is ADDED back. A
        // quickload is told apart by the rollback detector (wasload); true
        // load screens never add; the pre-mission briefing cradle is skipped
        // via the level clock (it runs on wall time with gettime() frozen).
        // Stock dll (rt_dll_api 0) -> this whole block is skipped and the
        // timer behaves exactly like v0.8.9.
        if(sr_wall_ok() && !froz)
        {
            w = sr_wall_read();
            if(w <= 0)
            {
                if(!isdefined(level.sr_walldead))
                {
                    level.sr_walldead = 1; // stock dll answers 0/errors here
                    sr_dbg("pause clock DEAD (wall read 0): apply exe_patch.ps1 (v8)");
                }
            }
            else
            {
                if(!isdefined(level.sr_walllast))
                {
                    level.sr_walllast = w;        // first tick after init: just arm
                    level.sr_wallarm = gettime(); // level clock at arm
                    sr_dbg("pause clock ON (wall clock ok, source: " + sr_wall_src() + ")");
                }
                d = w - level.sr_walllast;
                level.sr_walllast = w;

                // ---- QUICKLOAD GUARD (v0.12.2) ----------------------------
                // level.* variables live INSIDE the savegame, so F9 restores
                // sr_walllast to whatever it was when the save was written -
                // while the wall clock outside kept running. The gap we just
                // measured is therefore "time played since the save + the
                // load screen itself", which is exactly what a quickload is
                // supposed to ERASE. Counting it made the timer jump forward
                // by tens of seconds (reported on burnville/carride/brecourt,
                // the maps with the most quicksave abuse).
                // The cvar mirror rt_wcur_int is NOT rolled back, so it still
                // holds this map's elapsed time as of the save: re-anchor the
                // wall channel to it and swallow the gap.
                if(!isdefined(level.sr_wrel) && d > 250 && isdefined(level.sr_wcur))
                {
                    back = level.sr_wcur - getcvarint("rt_wcur_int");
                    if(back < 0)
                        back = 0 - back;
                    // sr_wcur (restored, = save moment) far behind the cvar
                    // (live) means the script state was rewound.
                    if(getcvarint("rt_wcur_int") - level.sr_wcur > 250)
                    {
                        // ASL channel: rebase so this map's elapsed matches
                        // the save moment as well.
                        if(sr_asl_ms() >= 0)
                            level.sr_aslbase = sr_asl_ms() - level.sr_wcur;
                        level.sr_wstart = w - level.sr_wcur; // keep save-time elapsed
                        sr_dbg("QUICKLOAD: wall channel re-anchored, +"
                            + sr_floor_big(d) + "ms of gap dropped");
                        d = 0; // nothing to classify: this was a load
                    }
                }

                if(isdefined(level.sr_wrel))
                {
                    level.sr_wstart = w - level.sr_wrel; // quickload: restore elapsed
                    level.sr_wrel = undefined;
                }
                if(!isdefined(level.sr_wstart) && gettime() - level.sr_starttime > 0)
                {
                    // arm only AFTER the level clock actually started: the
                    // pre-mission BRIEFING screen runs on wall time with the
                    // level clock frozen and must NOT count.
                    level.sr_wstart = w - (gettime() - level.sr_starttime);
                    sr_dbg("wall RTA CLOCK armed (menus/stats count, loads+briefings excluded)");
                }
                if(isdefined(level.sr_wstart))
                {
                    // ASL parity: once the victory screen is up the level is
                    // over for the autosplitter - PIN the wall elapsed so the
                    // banked split never absorbs the screen time. Without this
                    // the gap test below is not enough: sr_wcur would keep
                    // growing across the paused frames all by itself.
                    // v0.9.7 - ORDER MATTERS. This block runs BEFORE the gap
                    // detector below, so it must not depend on sr_vic_frozen
                    // either: on the frame the server wakes up from the end
                    // screen the flag is still unset (same race as v0.9.5),
                    // and sr_wcur would swallow the whole screen time before
                    // anyone gets to classify the gap. That is why MAP TIME
                    // read 01:18.8 while the PB line of the SAME level said
                    // 01:15.4 - the PB came from the corrected clock, the
                    // split from the polluted one.
                    // sr_victory_gap() is state, not an event -> race-free.
                    if(sr_asl_on() && (isdefined(level.sr_vic_frozen)
                        || sr_victory_gap()))
                    {
                        if(!isdefined(level.sr_wpin))
                        {
                            // Pin to the elapsed time as it was BEFORE this
                            // frame's gap. sr_wcur still holds the previous
                            // tick's value here (it is only recomputed below),
                            // so it is already the clean pre-screen number -
                            // subtracting the gap again would over-correct and
                            // cut real gameplay out of the split.
                            level.sr_wpin = level.sr_wcur;
                            sr_dbg("ASL: wall clock pinned at " + sr_floor_big(level.sr_wpin)
                                + "ms (end screen excluded)");
                        }
                        level.sr_wstart = w - level.sr_wpin; // hold it steady
                        level.sr_wcur = level.sr_wpin;
                    }
                    else
                        level.sr_wcur = w - level.sr_wstart;
                    setcvar("rt_wcur_int", sr_floor_big(level.sr_wcur));
                }
                // 250ms (was 750 in v0.9.2): the old threshold silently
                // dropped short pauses, which made counting arbitrary - a
                // 0.7s stop vanished while a 0.8s one counted. 250ms is still
                // far above a normal frame hitch at any playable fps.
                if(!wasload && d > 250 && d < 3600000)
                {
                    di = sr_floor_big(d); // float ms -> INTEGER ms
                    if(gettime() - level.sr_wallarm <= 1000)
                    {
                        // level clock frozen -> briefing screen, not a pause
                        sr_dbg("PRE-MISSION: +" + (di / 1000) + "." + (di % 1000) + "s skipped");
                    }
                    else if(sr_asl_on() && sr_save_gap())
                    {
                        // checkpoint write: the game was frozen, not paused
                        sr_dbg("SAVE +" + (di / 1000) + "." + sr_pad3(di % 1000)
                            + "s NOT counted (load removed)");
                        if(isdefined(level.sr_wcur))
                        {
                            level.sr_wcur = level.sr_wcur - di;
                            if(level.sr_wcur < 0)
                                level.sr_wcur = 0;
                            level.sr_wstart = w - level.sr_wcur;
                        }
                    }
                    else if(sr_asl_on() && sr_victory_gap())
                    {
                        // ASL parity: this gap is the end-of-level screen.
                        // The autosplitter stops there (loading==0 -> isLoading),
                        // so the run clock must not absorb it either.
                        //
                        // v0.9.5 - do NOT rely on level.sr_vic_frozen here!
                        // missionSuccess() writes nextmap and victoryscreen.menu
                        // sets cl_paused 1 within the SAME client frame, so the
                        // 20Hz watcher thread often never gets a frame in between
                        // and the flag is still unset when the server wakes up.
                        // That is exactly why a long wait on the end screen used
                        // to leak into the split (dawnville +4.1s, chateau +2.2s)
                        // while a quick Continue stayed under the 250ms threshold.
                        // Testing nextmap itself is race-free.
                        sr_dbg("END SCREEN +" + (di / 1000) + "." + sr_pad3(di % 1000)
                            + "s NOT counted (ASL parity)");
                        if(!isdefined(level.sr_vic_frozen))
                            level.sr_vic_frozen = 1; // catch up: freeze the L row
                        if(!isdefined(level.sr_wpin) && isdefined(level.sr_wcur))
                            level.sr_wpin = level.sr_wcur - di; // drop the screen time
                    }
                    else
                    {
                        level.sr_starttime = level.sr_starttime - di; // stretch: pause counts
                        setcvar("rt_ms_cur", gettime() - level.sr_starttime);
                        // v0.9.4: say WHERE it happened - a run that disagrees
                        // with LiveSplit can be diagnosed from this line alone
                        // (map + level-clock timestamp + size of the gap).
                        sr_dbg("PAUSE +" + (di / 1000) + "." + sr_pad3(di % 1000)
                            + "s counted on '" + getcvar("mapname") + "' at "
                            + ((gettime() - level.sr_starttime) / 1000) + "s");
                    }
                }
            }
        }

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
            setcvar("rt_wtotal", 0);
            setcvar("rt_wcur_int", 0);
            level.sr_wstart = undefined;
            sr_run_clear(); // v0.9.0: drop the previous run's split table
            level.sr_starttime = gettime();
            sr_dbg("NEW GAME: run timer reset (start latch)");
        }

        if(getcvarint("rt_cmd_mreset"))
        {
            setcvar("rt_cmd_mreset", "0");
            // v0.16.1: Reset Run has to re-anchor EVERY clock the readout can
            // come from. It used to move only sr_starttime, which is the last
            // fallback in sr_map_ms() - so with the exe bridge alive (the
            // normal case) the timer just kept running and the button looked
            // dead. Re-base the ASL/wall anchors as well, and clear the
            // banked totals + the split table so the run really starts over.
            level.sr_starttime = gettime();
            level.sr_wstart = undefined;
            level.sr_rtabase = sr_wall_now();
            if(getcvar("rt_aslms") != "")
                level.sr_aslbase = getcvarint("rt_aslms");
            level.sr_wcur = undefined;
            // v0.16.2: a reset must leave the FULL GAME row STOPPED at zero,
            // not restart it on the spot. It resumes when the next map loads
            // (init() clears this flag), which is where a run actually begins.
            level.sr_fg_hold = 1;
            // v0.17.0: hold the LEVEL row too. Clearing sr_lvl_off alone was
            // not enough: the fallback branch below re-anchors it after 20s
            // of movement, so the row silently started again a few seconds
            // later. The hold is lifted when the next map loads.
            level.sr_lvl_hold = 1;
            setcvar("rt_lvl_off", 0);
            setcvar("rt_lvl_map", "");
            level.sr_lvl_off = undefined;   // L row restarts too
            level.sr_lvl_ctime = undefined;
            level.sr_lvl_zero = undefined;
            level.sr_vic_frozen = undefined;
            level.sr_end_banked = undefined;
            setcvar("rt_ms_cur", 0);
            setcvar("rt_rta_last", 0);
            setcvar("rt_wcur_int", 0);
            setcvar("rt_wtotal", 0);
            setcvar("rt_run_total", 0);
            setcvar("rt_lat_prev", 0);
            setcvar("rt_norun", 0);
            sr_run_clear();
            sr_text("RUN RESET");
        }

        // print the whole PB table to the console (story order, v0.7.6):
        // cvar-bound menu editfields double-render their value in this
        // engine build, so the live table lives here instead of the page.
        // Delete Runs (v0.8.5): the menu page sets this latch and also execs
        // sr_pbwipe.cfg. The cfg is what makes the cleared values ARCHIVED
        // (seta) so they survive the restart; this latch is the in-game half
        // - it guarantees the wipe happens even if the cfg is missing from
        // main\ (pk3-only install), and it refreshes the live PB table at once.
        if(getcvarint("pb_wipe"))
        {
            setcvar("pb_wipe", "0");
            // sr_pbwipe.cfg usually already cleared everything a moment ago
            // (menu execs it): stay quiet then, only report a real wipe.
            had = sr_pb_any();
            sr_pb_wipe_all();
            if(had)
                sr_text("ALL PBs DELETED (level + full run).");
        }

        if(getcvarint("run_show"))
        {
            setcvar("run_show", "0");
            sr_run_print();
        }

        if(getcvarint("pb_show"))
        {
            setcvar("pb_show", "0");
            sr_text("== LEVEL PBs (story order) ==");
            mm = sr_pb_maplist();
            for(i = 0; i < mm.size; i++)
                sr_pb_line(mm[i]);
            sr_pbf = getcvar("pbs_full");
            if(sr_pbf == "")
                sr_pbf = "-";
            sr_text("PB FULL RUN: " + sr_pbf);
        }

        // final split: a stock-script hook (berlin end cinematic) sets
        // rt_end_frozen=1 -> bank the time once and freeze every readout
        // v0.8.0 exploit guard: bank only ON berlin - a manual `map credits`
        // also sets rt_end_frozen, and would otherwise bank a fake ~0s full PB.
        if(getcvarint("rt_end_frozen"))
        {
            if(!isdefined(level.sr_end_banked) && getcvar("mapname") == "berlin")
            {
                level.sr_end_banked = 1;
                // berlin ends on the cinematic, not on a victory screen, so
                // its LEVEL split is banked right here (v0.8.7) - otherwise
                // the last map of the run would never get a level PB.
                // v0.8.9: berlin is banked like ANY other level - PB compare
                // + MAP TIME/RUN TOTAL split - so the last map of the run
                // finally shows up as a level instead of only inside the
                // final full-run time.
                blvl = gettime() - level.sr_starttime;
                if(sr_wall_ok() && isdefined(level.sr_wcur))
                    blvl = sr_map_ms(); // v0.13.2: same clock as every other split
                if(blvl > 0)
                {
                    setcvar("rt_banked_map", "berlin");
                    setcvar("rt_lvl_done", 1);
                    sr_pb_compare("berlin", blvl);  // level PB for berlin
                    sr_bank_total("berlin", blvl);  // adds to rt_run_total
                }
                fin = getcvarint("rt_run_total"); // already includes berlin
                setcvar("rt_ms_cur", 0);
                level.sr_starttime = gettime(); // pinned: elapsed stays 0
                if(isdefined(level.sr_lvl_off)) // pin the level timer too
                    level.sr_lvl_ctime = sr_lvl_now();
                rhh = fin / 3600000; rmm = (fin / 60000) % 60;
                rss = (fin / 1000) % 60; rds = (fin / 100) % 10;
                if(sr_ms_on())
                    sr_text("RUN END! FINAL TIME " + rhh + ":" + sr_pad2(rmm) + ":"
                        + sr_pad2(rss) + "." + sr_pad3(fin % 1000) + " - gg!");
                else
                    sr_text("RUN END! FINAL TIME " + rhh + ":" + sr_pad2(rmm) + ":" + sr_pad2(rss) + "." + rds + " - gg!");

                // --- full-run PB (v0.7.0): pb_full ms, pbs_full string ---
                finstr = rhh + ":" + sr_pad2(rmm) + ":" + sr_pad2(rss) + "." + rds;
                pbf = getcvarint("pb_full");
                if(getcvarint("sr_ilmode"))
                {
                    sr_dbg("IL MODE: full-run time not saved");
                    pbf = 0 - 1;
                }
                else if(getcvarint("rt_norun"))
                {
                    sr_dbg("RUN NOT SAVED: a map was loaded manually");
                    pbf = 0 - 1; // block the full-run PB below
                }
                if(pbf == 0 - 1)
                {
                    // tainted run: keep the old record
                }
                else if(pbf <= 0 || fin < pbf)
                {
                    setcvar("pb_full", fin);
                    setcvar("pbs_full", finstr);
                    if(pbf > 0)
                        sr_text("NEW FULL-RUN PB: " + finstr + "!");
                    else
                        sr_text("FIRST FULL-RUN TIME SAVED: " + finstr);
                }
                else
                {
                    dms2 = fin - pbf;
                    qhh = dms2 / 3600000; qmm = (dms2 / 60000) % 60;
                    qss = (dms2 / 1000) % 60; qds = (dms2 / 100) % 10;
                    sr_text("FULL PB " + getcvar("pbs_full")
                        + " | delta +" + qhh + ":" + sr_pad2(qmm) + ":" + sr_pad2(qss) + "." + qds);
                }
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
// Speedometer: horizontal player speed (units/sec). Source: native engine
// velocity via the cvar bridge sr_velx10 when the patched CoDSP.exe runs
// (v0.6.x), otherwise pure-SCRIPT origin-delta between 20Hz server
// frames: 2D distance * 1000 / dt_ms.
// Teleport/ride snaps (>2000 u/s) are dropped so max/avg stay clean.
// Tracks max speed (rt_spd_max) + rolling 5s average; colors in HUD loop.
// The DISPLAYED number is adaptive: a box average over the last
// sr_spd_win ticks (default 10 = 0.5s) in steady state, or an instant
// 2-tick average when |fast - slow| > sr_spd_fast (default 15 u/s) -
// kills straight-line jitter AND the smoothing lag at the same time.
// Deadband (sr_spd_hyst, default 0 = off) hides residual wobble.
// ============================================================================
sr_speedo_loop()
{
    self endon("disconnect");

    // rolling 5s average: 100-sample ring @50ms ticks (thread-locals, so a
    // watchdog respawn simply restarts the window - harmless)
    ring = [];
    ring_i = 0;
    sum = 0;
    cnt = 0;
    level.sr_avg = 0;

    have_prev = 0;
    porg = (0, 0, 0);
    pt = 0;

    // display smoothing: box average over the last sr_spd_win ticks
    // (1..20, ~50ms each; default 10 = 0.5s) - kills per-frame jitter
    dring = [];
    dring_i = 0;
    dsum = 0;
    dcnt = 0;
    // adaptive fast path: 2-tick average takes over on real transients
    fast_armed = 0;
    fnv = 0;

    for(;;)
    {
        wait .05; // 20Hz server tick - the max cadence any script number gets

        level.sr_beat2 = gettime(); // watchdog heartbeat

        // script speedo: horizontal displacement per second between server
        // frames. gettime() and the origin BOTH freeze in ESC/menus, so
        // pauses make no spikes; teleports are dropped by the clamp below.
        t = gettime();
        org = self.origin;
        dt = t - pt;
        if(!have_prev || dt <= 0)
        {
            have_prev = 1;
            porg = org;
            pt = t;
            setcvar("rt_spd", "0");
            level.sr_avg = 0;
            continue;
        }
        nv_o = distance((org[0],org[1],0), (porg[0],porg[1],0)) * 1000.0 / dt;
        porg = org;
        pt = t;

        // native bridge (v0.6.5): the patched exe writes the cvar through
        // the ENGINE'S OWN Cvar_Set2 as tenths ("001903" = 190.3 u/s); the
        // int read is identical on every code path -> it is the ONE source.
        // When the bridge EXISTS it OWNS the readout: a 0 read shows 0.0
        // in the HUD even when the origin-delta still reports motion
        // (explicit user request, field-approved v0.6.5->v0.6.6).
        // Chat lines are one-shot per map: first live value + first dead
        // detection with the raw string for diagnosis.
        nv = nv_o;
        if(!isdefined(level.sr_native_has))
            level.sr_native_has = 0;
        if(level.sr_native_has)
        {
            nvi = getcvarint("rt_velx10");
            // v0.11.0: exe v9 publishes THOUSANDTHS (190325 = 190.325 u/s).
            // exe v7/v8 published tenths (1903 = 190.3). Both are supported;
            // sr_velprec says which scale the bridge uses.
            nv = nvi / sr_vel_scale();
            if(nvi > 0)
            {
                if(!isdefined(level.sr_native_ok))
                {
                    level.sr_native_ok = 1; // proven live once per map
                    sr_dbg("NATIVE live: " + nv + " u/s");
                }
            }
            else if(nv_o > 5 && !isdefined(level.sr_dead_said))
            {
                level.sr_dead_said = 1; // said once: bridge frozen/stalling
                sr_dbg("NATIVE DEAD: rt_velx10='" + getcvar("rt_velx10") + "' - engine skipped the cave this frame");
            }
        }


        if(nv > 2000) // teleport/ride snap: drop the sample, keep last readout
            continue;

        if(nv > getcvarfloat("rt_spd_max"))
            setcvar("rt_spd_max", nv); // max keeps the RAW peak

        // rolling 5s average: sampled ALWAYS, even when the speedo elem is
        // hidden, so sr_spd_avg shows a fresh number the moment it is on.
        if(isdefined(ring[ring_i]))
            sum = sum - ring[ring_i];
        ring[ring_i] = nv;
        sum += nv;
        if(sum < 0)
            sum = 0; // float drift guard
        ring_i = (ring_i + 1) % 100;
        if(cnt < 100)
            cnt++;
        // round to 0.1 via the cvar string channel (no int() builtin; cvar
        // int parse truncates == floor, +0.5 = round half up). Values here
        // are <= ~10k, far below the %g-safe 1e6 bound.
        setcvar("rt_dt", (sum / cnt) * 10 + 0.5);
        level.sr_avg = getcvarint("rt_dt") / 10.0;

        // display smoothing: box average over the last 10 raw samples
        // (fixed constant since v0.7.0 - speedo tunables are folded away)
        win = 10;
        if(dcnt > win)
            dcnt = win; // window shrank mid-run: <0.2s transient, self-heals
        if(dring_i >= win)
            dring_i = 0;
        if(isdefined(dring[dring_i]))
            dsum = dsum - dring[dring_i];
        dring[dring_i] = nv;
        dsum += nv;
        if(dsum < 0)
            dsum = 0; // float drift guard
        dring_i = (dring_i + 1) % win;
        if(dcnt < win)
            dcnt++;
        davg = dsum / dcnt;

        // display: native engine values are exact, so in native mode the
        // HUD gets the plain 2-tick average (0.1s window - zero perceived
        // lag, like the CoD4 native meter). Script origin-delta keeps the
        // adaptive slow/fast switch from v0.5.4.
        if(level.sr_native_has)
        {
            // v0.11.0: sr_spd_raw 1 (default) shows the EXACT engine value of
            // this frame. The old 2-tick average smoothed the readout, which
            // is fine for eyeballing speed but destroys the third decimal -
            // and precise skips need the true number, not a blend of two
            // frames. sr_spd_raw 0 restores the smoothed behaviour.
            if(getcvarint("sr_spd_raw"))
                cand = nv;
            else
                cand = (nv + fnv) / 2;
        }
        else
        {
            if(!fast_armed)
            {
                fast_armed = 1;
                cand = nv;
            }
            else
                cand = (nv + fnv) / 2; // 2-tick fast average
            d2 = cand - davg;
            if(d2 < 0)
                d2 = 0 - d2;
            if(d2 <= 15.0) // fixed transient threshold (folded cvar)
                cand = davg; // steady run: long window wins
        }
        fnv = nv;

        if(!getcvarint("sr_speedo"))
            continue;

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
        setcvar("rt_dt", cand * mul + 0.5);
        nvd = getcvarint("rt_dt") / mul; // adaptive candidate
        // deadband: don't repaint the readout for sub-threshold wobble
        // (frame/origin quantization residue) - it must sit STILL straight
        // v0.11.0: was a hardcoded 1.0 - that swallowed everything below a
        // whole unit, so thousandths could never appear. Cvar-driven now.
        hyst = getcvarfloat("sr_spd_hyst");
        diff = nvd - getcvarfloat("rt_spd");
        if(diff < 0)
            diff = 0 - diff; // note: CoD1 GSC has NO unary minus on vars
        if(diff >= hyst)
            setcvar("rt_spd", nvd);
    }
}

// ============================================================================
// HUD - speedo center + run total top-right under the built-in Level Time.
// Only 11 live elems (tankdrive hudelem budget): the total renders
// zero-padded MM:SS.d as single-digit columns, the hours pair appears
// lazily at >=1h. Punctuation via the missing-istring fallback. Watchdog.
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

    // rolling 5s average under the speedo (dimmer, smaller)
    hud_avg = newHudElem();
    hud_avg.x = 320;
    hud_avg.y = 322;
    hud_avg.alignX = "center";
    hud_avg.alignY = "top";
    hud_avg.sort = 10;
    hud_avg.fontscale = 1.1;
    hud_avg.color = (0.85, 0.85, 0.85);
    if(!isdefined(level.sr_avg))
        level.sr_avg = 0;

    // ---- formatted total, ZERO-PADDED digits (spd + avg + 9) ----
    // Right edge pinned at 612 under the built-in Level Time .
    hud_mm1 = newHudElem(); hud_mm1.x = 550; hud_mm1.alignX = "left";
    hud_mm2 = newHudElem(); hud_mm2.x = 560; hud_mm2.alignX = "left";
    hud_c1  = newHudElem(); hud_c1.x  = 571; hud_c1.alignX  = "left";
    hud_ss1 = newHudElem(); hud_ss1.x = 576; hud_ss1.alignX = "left";
    hud_ss2 = newHudElem(); hud_ss2.x = 586; hud_ss2.alignX = "left";
    hud_c2  = newHudElem(); hud_c2.x  = 597; hud_c2.alignX  = "left";
    hud_m1  = newHudElem(); hud_m1.x  = 602; hud_m1.alignX  = "left";
    // v0.12.0: two more digits -> H:MM:SS.mmm, the format Ericg08's PB is
    // titled with (1:28:37.460). Hidden when the ms mode is off.
    hud_m2  = newHudElem(); hud_m2.x  = 612; hud_m2.alignX  = "left";
    hud_m3  = newHudElem(); hud_m3.x  = 622; hud_m3.alignX  = "left";

    tel[0] = hud_mm1; tel[1] = hud_mm2; tel[2] = hud_c1;
    tel[3] = hud_ss1; tel[4] = hud_ss2; tel[5] = hud_c2;
    tel[6] = hud_m1;  tel[7] = hud_m2;  tel[8] = hud_m3;
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


    // LEVEL timer (v0.7.2/0.8.3): 7 elems - dynamic HUD text is flat-out
    // IMPOSSIBLE in this engine (plain runtime strings: cannot cast
    // string to istring at setText; runtime strings starting with & are
    // drawn as NOTHING). Digit columns via setValue, layout mirrors the
    // run row; the label toggles between two STATIC istrings (&L /
    // &L -) for the negative intro phase. Single minute digit (levels
    // are <10 min in practice).
    // v0.8.9: the digit columns moved +20px right (right edge 612, the edge
    // the layout was designed around), so the labels sit clear of the "H:"
    // pair the run row grows past 1h - no more overlap, and the rows read
    // further right as asked.
    hud_llbl = newHudElem(); hud_llbl.x = 506; hud_llbl.alignX = "left";
    hud_llbl.y = 44; hud_llbl.alignY = "top"; hud_llbl.sort = 10;
    hud_llbl.fontscale = 1.0; hud_llbl.color = (0.65, 0.9, 1);
    hud_llbl setText(&"L");

    // v0.8.8: TWO minute digits (MM:SS.m). One digit truncated any level
    // that ran past 9:59 - 10:23.4 used to render as "0:23.4".
    hud_lm1 = newHudElem(); hud_lm1.x = 550; hud_lm1.alignX = "left";
    hud_lm  = newHudElem(); hud_lm.x  = 560; hud_lm.alignX  = "left";
    hud_lc1 = newHudElem(); hud_lc1.x = 571; hud_lc1.alignX = "left";
    hud_ls1 = newHudElem(); hud_ls1.x = 576; hud_ls1.alignX = "left";
    hud_ls2 = newHudElem(); hud_ls2.x = 586; hud_ls2.alignX = "left";
    hud_lc2 = newHudElem(); hud_lc2.x = 597; hud_lc2.alignX = "left";
    hud_ld  = newHudElem(); hud_ld.x  = 602; hud_ld.alignX  = "left";
    hud_ld2 = newHudElem(); hud_ld2.x = 612; hud_ld2.alignX = "left";
    hud_ld3 = newHudElem(); hud_ld3.x = 622; hud_ld3.alignX = "left";

    ltl[0] = hud_lm; ltl[1] = hud_lc1; ltl[2] = hud_ls1;
    ltl[3] = hud_ls2; ltl[4] = hud_lc2; ltl[5] = hud_ld;
    ltl[6] = hud_lm1; ltl[7] = hud_ld2; ltl[8] = hud_ld3;
    for(li = 0; li < ltl.size; li++)
    {
        ltl[li].y = 44;
        ltl[li].alignY = "top";
        ltl[li].sort = 10;
        ltl[li].fontscale = 1.0;
        ltl[li].color = (0.65, 0.9, 1);
    }
    hud_lc1 setText(&":");
    hud_lc2 setText(&".");

    hud_rlbl = newHudElem(); hud_rlbl.x = 506; hud_rlbl.alignX = "left";
    hud_rlbl.y = 63; hud_rlbl.alignY = "top"; hud_rlbl.sort = 10;
    hud_rlbl.fontscale = 1.0; hud_rlbl.color = (1, 1, 0.4);
    hud_rlbl setText(&"FG"); // full game

    // v0.14.5: keep the timer on screen at all times - also over the ESC
    // menu, the death screen and the end-of-level screen. foreground draws
    // above the fullscreen menu layer; hidewheninmenu 0 stops the engine from
    // auto-hiding the elem when a menu opens.
    tall[0] = hud_spd; tall[1] = hud_avg; tall[2] = hud_llbl; tall[3] = hud_rlbl;
    tall[4] = hud_mm1; tall[5] = hud_mm2; tall[6] = hud_c1;  tall[7] = hud_ss1;
    tall[8] = hud_ss2; tall[9] = hud_c2;  tall[10] = hud_m1; tall[11] = hud_m2;
    tall[12] = hud_m3; tall[13] = hud_lm1; tall[14] = hud_lm; tall[15] = hud_lc1;
    tall[16] = hud_ls1; tall[17] = hud_ls2; tall[18] = hud_lc2; tall[19] = hud_ld;
    tall[20] = hud_ld2; tall[21] = hud_ld3;
    for(ai = 0; ai < tall.size; ai++)
    {
        tall[ai].foreground = true;
        tall[ai].hidewheninmenu = false;
    }

    sr_dbg("HUD elems created: spd + 5s avg center, total MM:SS.d (tenths pure-GSC v0.5)");

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
        hud_spd setValue(spd); // script speedo readout
        hud_avg setValue(level.sr_avg); // rolling 5s average
        if(spd >= 275)      hud_spd.color = (1, 0.15, 0.15); // red
        else if(spd >= 230) hud_spd.color = (1, 0.9, 0.1);   // yellow
        else if(spd >= 180) hud_spd.color = (0.25, 1, 0.3);  // green
        else                hud_spd.color = (1, 1, 1);       // idle

        if(isdefined(level.sr_fg_hold))
            total = getcvarint("rt_run_total"); // v0.16.2: stopped after a reset
        else if(getcvarint("rt_end_frozen"))
            total = getcvarint("rt_run_total"); // frozen final
        else if(sr_is_briefmap(getcvar("mapname")))
        {
            // briefing level: show the frozen bank only (its time never counts)
            if(sr_wall_ok())
                total = getcvarint("rt_wtotal");
            else
                total = getcvarint("rt_run_total");
        }
        else if(sr_asl_ms() >= 0 && isdefined(level.sr_aslbase))
            total = sr_quant(getcvarint("rt_wtotal") + sr_map_ms()); // ASL-exact
        // note: rt_wtotal already contains the per-map tail (it is banked with
        // the split), so the live FG row stays consistent with run_show.
        else if(sr_wall_ok() && isdefined(level.sr_wcur))
            total = sr_quant(sr_floor_big(getcvarint("rt_wtotal") + level.sr_wcur)); // RTA
        else
            total = sr_quant(getcvarint("rt_run_total") + gettime() - level.sr_starttime);

        // toggles hide their elems (alpha 0/1; the elems stay alive)
        // v0.17.0: sr_igt is the master switch; sr_show_l / sr_show_fg pick
        // the individual rows. IL mode force-hides the full-game row, because
        // in that mode its number is meaningless (nothing is banked).
        tvis = getcvarint("sr_igt");
        lvis = tvis;
        fvis = tvis;
        if(!getcvarint("sr_show_l"))
            lvis = 0;
        if(!getcvarint("sr_show_fg") || getcvarint("sr_ilmode"))
            fvis = 0;
        for(ti = 0; ti < tel.size; ti++)
            tel[ti].alpha = fvis;
        hud_spd.alpha = getcvarint("sr_speedo");
        hud_avg.alpha = getcvarint("sr_spd_avg");

        // lazy hours pair: exists only from 1h on (hudelem budget)
        if(total >= 3600000 && !isdefined(hud_th))
        {
            hud_th = newHudElem(); hud_th.x = 541; hud_th.alignX = "right";
            hud_c0 = newHudElem(); hud_c0.x = 545; hud_c0.alignX = "left";
            hud_th.y = 62; hud_th.alignY = "top"; hud_th.sort = 10;
            hud_th.fontscale = 1.1; hud_th.color = (1, 1, 0.4);
            hud_c0.y = 62; hud_c0.alignY = "top"; hud_c0.sort = 10;
            hud_c0.fontscale = 1.1; hud_c0.color = (1, 1, 0.4);
            hud_c0 setText(&":");
            // v0.14.5: same always-visible treatment as the rest of the row
            hud_th.foreground = true;  hud_th.hidewheninmenu = false;
            hud_c0.foreground = true;  hud_c0.hidewheninmenu = false;
        }
        if(isdefined(hud_th))
        {
            if(total >= 3600000)
            {
                hud_th.alpha = fvis;
                hud_c0.alpha = fvis;
                hud_th setValue(total / 3600000);
            }
            else
            {
                hud_th.alpha = 0; // run restarted: hide the stale pair
                hud_c0.alpha = 0;
            }
        }

        // MM:SS.d tenths side mode (pure int math)
        hud_mm1 setValue(((total / 60000) % 60) / 10);
        hud_mm2 setValue((total / 60000) % 10);
        hud_ss1 setValue(((total / 1000) % 60) / 10);
        hud_ss2 setValue((total / 1000) % 10);
        // v0.12.0: .mmm when the ms mode is on, otherwise a single tenth
        hud_m1 setValue((total % 1000) / 100);
        if(sr_ms_on())
        {
            hud_m2 setValue((total % 100) / 10);
            hud_m3 setValue(total % 10);
            hud_m2.alpha = fvis;
            hud_m3.alpha = fvis;
        }
        else
        {
            hud_m2.alpha = 0;
            hud_m3.alpha = 0;
        }

        // LEVEL MM:SS.d (v0.8.3): NEGATIVE phase from map start until
        // control is gained (intro shows as a growing negative minus),
        // snaps to +0:00.0 at the control-gain frame, positive after.
        // Digits are setValue-int columns (the run-row way); dynamic
        // setText is unusable in this engine, the label toggles between
        // two STATIC istrings only.
        lneg = 0;
        if(isdefined(level.sr_lvl_ctime))
            lut = level.sr_lvl_ctime; // pinned at the end split
        else if(isdefined(level.sr_lvl_off))
            lut = sr_lvl_now();
        else
        {
            // v0.8.6: intro phase COUNTS DOWN to the autosave frame, so the
            // row reads -2.8 ... -0.1 -> 0.0 and then climbs. (Before it was
            // a growing minus, which ran backwards against the real timer.)
            if(!isdefined(level.sr_lvl_mapstart))
                level.sr_lvl_mapstart = gettime();
            if(!isdefined(level.sr_lvl_zero))
                level.sr_lvl_zero = gettime() + sr_intro_len();
            lut = level.sr_lvl_zero - gettime(); // time LEFT until the save
            lneg = 1;
            if(lut < 0)
                lut = 0; // intro ran long: sit at -0.0 until the save lands
        }
        if(lut < 0)
            lut = 0; // quickload clock-rewind quirk guard
        if(lneg)
            hud_llbl setText(&"L -");
        else
            hud_llbl setText(&"L");
        hud_lm1 setValue(((lut / 60000) % 60) / 10);
        hud_lm  setValue((lut / 60000) % 10);
        hud_ls1 setValue(((lut / 1000) % 60) / 10);
        hud_ls2 setValue((lut / 1000) % 10);
        hud_ld  setValue((lut / 100) % 10);
        if(sr_ms_on())
        {
            hud_ld2 setValue((lut % 100) / 10);
            hud_ld3 setValue(lut % 10);
            hud_ld2.alpha = lvis;
            hud_ld3.alpha = lvis;
        }
        else
        {
            hud_ld2.alpha = 0;
            hud_ld3.alpha = 0;
        }
        hud_llbl.alpha = lvis;
        hud_lm1.alpha = lvis;
        hud_lm.alpha = lvis;
        hud_lc1.alpha = lvis;
        hud_ls1.alpha = lvis;
        hud_ls2.alpha = lvis;
        hud_lc2.alpha = lvis;
        hud_ld.alpha = lvis;
        hud_rlbl.alpha = fvis;

        // .02 still amounts to one server frame (50ms) - script numbers
        // cannot refresh faster than the server tick in this binary.
        wait .02;
    }
}
