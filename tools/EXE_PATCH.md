# CoDSP.exe native bridge — patch specification (v18)

What `tools/patch_exe.ps1` writes into a **stock CoD 1.3 SP** `CoDSP.exe`,
byte by byte. The patch is 2,838 bytes total out of a 1,716,224-byte file:
one redirected `call` plus a code cave in the section's zero padding.

- stock MD5: `8E1D57D69705485D8D641CCC636DAE6B`
- patched MD5: `C00B045D5131EB4ACB682FAFAEA439C1`

File offsets below equal VA − 0x400000 (the `.text` section is mapped 1:1,
raw offset = VA − image base).

---

## 1. The hook — the only change to existing code (4 bytes)

One branch of the client-frame switch calls an engine function every frame.
The patch retargets that single near `call`; no other instruction in the
binary is moved or modified:

```
stock:    004ceb98   call 0x4ce730      ; engine routine
patched:  004ceb98   call 0x532148      ; -> code cave entry
```

The cave's trampoline calls the original `0x4ce730` itself, so the engine
still runs exactly the code it expects.

## 2. The code cave — placement

`.text` has `VirtualSize 0x131148` but is file-aligned to `0x132000`: the
last ~3.7 KB of the section are zero padding. All mod code and data live in
that padding (VA `0x532148`–`0x532F36`). Nothing existing is overwritten.

Interaction with the engine goes exclusively through the engine's own
routines:

| Routine | VA | Used for |
|---|---|---|
| `Cvar_Get(name, value, flags)` | `0x4319F0` | declaring cvars (ARCHIVE) |
| `Cvar_Set2(name, value, force)` | `0x431CF0` | publishing values |
| `sprintf` (import) | `[0x53325C]` | number formatting |
| `GetTickCount` (import) | `[0x533164]` | wall clock |

The cave saves and restores all registers and flags (`pushal`/`pushfd` …
`popfd`/`popal`) around every block.

## 3. Blocks

### `0x532148` — entry, trampoline, speedometer
Entry jumps to the dispatcher (`0x532540`); the trampoline at `0x532156`
calls the original engine routine. The speedometer body:

1. loads the player's X/Y velocity from `cl.snap.ps.velocity`
   (`0x142fe6c` / `0x142fe70`);
2. `fsqrt(x² + y²)`, scales ×1000, clamps to 999999;
3. formats `%06d` via the engine's `sprintf`;
4. publishes with `Cvar_Set2("rt_velx10", ...)` — `"190300"` = 190.3 u/s.

A debug branch (off unless `rt_drawspeed` is set) projects a 3D overlay of
the readback value.

### `0x532540` — per-frame dispatcher
Three calls per client frame: run-once block (`0x532900`) → wall clock
(`0x532500`) → ASL timer (`0x532570`), then returns into the trampoline.

### `0x532500` — wall clock
`GetTickCount()` → `Cvar_Set2("rt_wallms", ...)`. The GSC script uses it to
count ESC pauses (RTA).

### `0x532570` — ASL timer
Accumulates `GetTickCount` deltas into a millisecond counter **only while
the byte at `0x1549985` is non-zero** — the engine's "game accepts input"
flag, the very byte the speedrun.com autosplitter (`yf5y2.asl`) reads.
Deltas ≤ 0 or > 5000 ms are discarded (loads, freezes, timer wrap). On the
flag's falling edge the current total is latched into `rt_asllatch`
(end-of-map value); the running total is published as `rt_aslms`.

### `0x532900` — run-once ARCHIVE declarations
Guarded by an in-memory flag (`0x1025ca8`) — the body executes once per
process. Declares all 18 `sr_*` settings via `Cvar_Get(name, default, 1)`
(flag 1 = CVAR_ARCHIVE).

**v18 addition** (`0x532AA5`): where v17 ended in `ret`, a loop now walks a
null-terminated table of 54 pointer pairs at `0x532AD0` and declares every
`pb_<map>` / `pbs_<map>` (26 maps + full run) the same way. `Cvar_Get`
never overwrites an existing value — it only adds the ARCHIVE flag — so
current records are preserved and the engine itself writes them to
`config.cfg` on exit. The run-once early-exit `jne` was retargeted to the
new `ret`.

### Data blocks
- `0x53244a`–`0x5324f0`: format strings (`%06d`, `%d.%d`, …) and cvar names
  (`rt_velx10`, `rt_wallms`, `rt_aslms`, `rt_asllatch`, overlay cvars);
- `0x532740`: `sr_*` setting names + default strings;
- `0x532AD0`: the v18 pointer table (name, default) × 54 + null terminator;
- `0x532C88`: `pb_*`/`pbs_*` name strings.

## 4. Block map

| File offset | Bytes | Content |
|---|---|---|
| `0x0CEB99` | 4 | hook: `call` target |
| `0x132148` | 542 | trampoline + speedometer |
| `0x13244A` | 54 | overlay cvar names, formats |
| `0x132488` | 8 | data |
| `0x132498` | 8 | data |
| `0x1324A8` | 80 | cvar name strings |
| `0x132500` | 94 | wall clock |
| `0x132570` | 232 | ASL timer |
| `0x132700` | 11 | string data |
| `0x132740` | 229 | `sr_*` names + defaults |
| `0x132900` | 456 | run-once: 18 × `Cvar_Get(sr_*, ARCHIVE)` |
| `0x132AD0` | 431 | v18: PB loop + pointer table |
| `0x132C88` | 685 | v18: `pb_*`/`pbs_*` strings |

## 5. Why it is safe

- one entry point: a single redirected `call`; remove the hook and the cave
  is dead bytes;
- no memory scanning, no DLL injection, no thread creation, no imports
  added — the import table is untouched;
- all engine interaction through the engine's own cvar API;
- registers/flags fully preserved around the cave;
- offset-based, therefore **stock-1.3-only**: `patch_exe.ps1` verifies the
  MD5 before writing and refuses anything else, backs the file up, and
  verifies the result (fail-closed).

## 6. Reproducing / verifying

```powershell
# apply to a stock exe
powershell -ExecutionPolicy Bypass -File tools\patch_exe.ps1 -GamePath "C:\path\to\game"

# verify
Get-FileHash "C:\path\to\game\CoDSP.exe" -Algorithm MD5
# -> C00B045D5131EB4ACB682FAFAEA439C1

# undo
powershell -ExecutionPolicy Bypass -File tools\patch_exe.ps1 -GamePath "..." -Revert
```

The patch bytes are plain base64 blocks inside `patch_exe.ps1` — any hex
editor or disassembler can confirm the blocks against this document.
