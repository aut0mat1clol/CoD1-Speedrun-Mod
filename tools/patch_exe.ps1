# ============================================================================
# patch_exe.ps1 - CoD1 Speedrun Mod, native bridge v18 (part of release 1.2.2)
#
# Patches YOUR OWN stock CoDSP.exe (CoD 1.3 SP) in place - no game binary is
# distributed with this script. The patch data below is only the mod's own
# code cave (13 blocks, 2834 bytes) applied on top of the stock exe:
#
#   * rt_velx10  - exact engine speed x1000, written every client frame
#                  (0.001 u/s speedometer);
#   * rt_wallms  - GetTickCount wall clock (pause counting);
#   * rt_aslms / rt_asllatch - a timer that only advances while the game
#                  accepts input, i.e. the same rule the speedrun.com
#                  autosplitter (yf5y2.asl) applies;
#   * run-once ARCHIVE declarations for every sr_* setting and every
#                  pb_*/pbs_* record, so settings and PBs persist in
#                  config.cfg without any exec.
#
# The script verifies the exe's MD5 before touching anything, creates a
# backup (CoDSP.exe.sr_backup) and verifies the result. Fail-closed: any
# mismatch aborts with the original file intact.
#
# USAGE:
#   powershell -ExecutionPolicy Bypass -File .\patch_exe.ps1 -GamePath "C:\Games\Call of Duty"
#   powershell -ExecutionPolicy Bypass -File .\patch_exe.ps1 -GamePath "..." -Revert
# ============================================================================

param(
    [switch]$Revert,
    [string]$GamePath = ""
)
$ErrorActionPreference = "Stop"

$stockMd5 = "8E1D57D69705485D8D641CCC636DAE6B"   # CoDSP.exe, stock 1.3
$v18Md5   = "C00B045D5131EB4ACB682FAFAEA439C1"   # after this patch
# older builds of the mod's patch - safe to re-patch from a fresh stock copy,
# but this script only ever patches a VERIFIED STOCK exe (fail-closed).
$knownOldPatched = @(
    "40E38FDF5C214E18E221511A9CB33B47", "F4B7E3AE0111AB04AF5A71B976B5306F",
    "D906CEDC0310163541D3BBD741A9764F", "64736FF616A3840F7507CCFD2FA333C6",
    "0884EFC04FEE348C4CD6E9EDD24F93D1", "868F32F724CBE7AE3E95ACACAA5FA303",
    "45CECD8C066711E2D04F701D3B822834", "6C7A3991FC46DDB5087E508B2D279366",
    "4C4DD836AA9A0A895E8CB7BA166DC78D", "74E136D4BA4C570F436B4392FEB97D70",
    "F8DD95A24DF98DDBE1367F144C389803", "4B259A623664FA398E4E5B1FAC7DA1B8",
    "6BB529507D3593A7D0A445181BED1CF3"
)

# ---- patch data: raw byte blocks written over the stock exe --------------
# offset = position in the file, data = base64 of the bytes to write there.
$patch = @(
    @{ Offset = 846745; Data = "qzUGAA==" },
    @{ Offset = 1253704; Data = "6fMDAACQkJCQkHQK6wC4MOdMAP/Qw2Ccg+xg2QVs/kIB2MjZBXD+QgHYyN7B2frZVCRM2A1cJFMA21wkPItUJDyB+j9CDwB+Bbo/Qg8AiVQkPI00JP90JDxouiRTAFb/FVwyUwCDxAxWaMAkUwC4AQAAALnwHEMA/9GDxAhqAGjMJFMAaMAkUwC48BlDAP/Qg8QMhcAPhHkBAACLQCCJRCQ8agBorCRTAGhoJFMAuPAZQwD/0IPEDIXAD4RUAQAAg3ggAA+ESgEAAItEJDwx0rkKAAAA9/GJ4VJQaLQkUwBR/xVcMlMAg8QQagBosCRTAGiYJFMAuPAZQwD/0IPEDIXAD4QMAQAAi0AciUQkQGoAaKwkUwBoeCRTALjwGUMA/9CDxAyFwA+E5wAAANlAHNgNYCRTANhMJEDZXCREagBorCRTAGiIJFMAuPAZQwD/0IPEDIXAD4S4AAAA2UAc2A1gJFMA2EwkQNlcJEjZBTBgUwHZBTxgUwHYTCRA3sHZBUhgUwHYTCRE3sHZBVRgUwHYTCRI3sHZXCQw2QU0YFMB2QVAYFMB2EwkQN7B2QVMYFMB2EwkRN7B2QVYYFMB2EwkSN7B2VwkNNkFOGBTAdkFRGBTAdhMJEDewdkFUGBTAdhMJETewdkFXGBTAdhMJEjewdlcJDiNXCQwjT1IJFMAieFR/zVYJFMAuGDYSgD/0IPECIPEYJ1h6fD9//8=" },
    @{ Offset = 1254474; Data = "gD8AAIA/AACAPwAAgD8AAIA/AAB6RMNkKjsAAAAAcnRfZHJhd3NwZWVkAAAAAHJ0X292bF94" },
    @{ Offset = 1254536; Data = "cnRfb3ZsX3k=" },
    @{ Offset = 1254552; Data = "cnRfb3ZsX3o=" },
    @{ Offset = 1254568; Data = "MQAAADAAAAA5MAAAJWQuJWQAJTA2ZAAAcnRfdmVseDEwAAAAMDAwMDAwAAAAAAAAcnRfd2FsbG1zAAAAJXUAADAAAAAAAAAAcnRfYXNsbXM=" },
    @{ Offset = 1254656; Data = "YJyD7CD/FWQxUwBQaOQkUwCNTCQIUf8VXDJTAIPEDI0MJFFo2CRTALgBAAAAufAcQwD/0YPECIPEIJ1hwwAAAOi7AwAA6Lb////oIQAAAIE9jJVUAQAQAADp9Pv//w==" },
    @{ Offset = 1254768; Data = "YJyD7CD/FWQxUwCLHZRcAgGjlFwCAYM9mFwCAQB1D8cFmFwCAQEAAADpLAAAAInBKdmD+QAPjh8AAACB+YgTAAAPjxMAAACAPYWZVAEAD4QGAAAAAQ2QXAIBD7YFhZlUAYsVpFwCAaOkXAIBhcB1EIXSdAyLDZBcAgGJDaBcAgH/NZBcAgFo5CRTAI1MJAhR/xVcMlMAg8QMjQwkUWjwJFMAuAEAAAC58BxDAP/Rg8QI/zWgXAIBaOQkUwCNTCQIUf8VXDJTAIPEDI0MJFFoACdTALgBAAAAufAcQwD/0YPECIPEIJ1hww==" },
    @{ Offset = 1255168; Data = "cnRfYXNsbGF0Y2g=" },
    @{ Offset = 1255232; Data = "c3Jfc3BlZWRvADEAc3Jfc3BkX2F2ZwAxAHNyX2lndAAxAHNyX3Nob3dfbAAxAHNyX3Nob3dfZmcAMQBzcl9pbG1vZGUAMABzcl90bXJfZGVjADMAc3Jfc3BkX2RlYwAzAHNyX2x2bF9zdGFydAAxAHNyX3RhaWwAMzYwAHNyX2RlYnVnADAAc3JfZmlyc3RtYXAAdHJhaW5pbmcAc3Jfc3BkX3JhdwAxAHNyX3ZlbHByZWMAMABzcl9zcGRfaHlzdAAwAHNyX2x2bF9wcmUAMABydF9ydGEAMQBydF9jZmdfb2sAMQ==" },
    @{ Offset = 1255680; Data = "gz2oXAIBAA+FugEAAMcFqFwCAQEAAABgnGoBaEonUwBoQCdTALjwGUMA/9CDxAxqAWhXJ1MAaEwnUwC48BlDAP/Qg8QMagFoYCdTAGhZJ1MAuPAZQwD/0IPEDGoBaGwnUwBoYidTALjwGUMA/9CDxAxqAWh5J1MAaG4nUwC48BlDAP/Qg8QMagFohSdTAGh7J1MAuPAZQwD/0IPEDGoBaJInUwBohydTALjwGUMA/9CDxAxqAWifJ1MAaJQnUwC48BlDAP/Qg8QMagForidTAGihJ1MAuPAZQwD/0IPEDGoBaLgnUwBosCdTALjwGUMA/9CDxAxqAWjFJ1MAaLwnUwC48BlDAP/Qg8QMagFo0ydTAGjHJ1MAuPAZQwD/0IPEDGoBaOcnUwBo3CdTALjwGUMA/9CDxAxqAWj0J1MAaOknUwC48BlDAP/Qg8QMagFoAihTAGj2J1MAuPAZQwD/0IPEDGoBaA8oUwBoBChTALjwGUMA/9CDxAxqAWgYKFMAaBEoUwC48BlDAP/Qg8QMagFoJChTAGgaKFMAuPAZQwD/0IPEDL7QKlMAiwaFwHQVagH/dgRQuPAZQwD/0IPEDIPGCOvlnWHD" },
    @{ Offset = 1256144; Data = "iyxTAIgsUwCXLFMAiixTAKQsUwCILFMAsixTAIosUwDBLFMAiCxTAM4sUwCKLFMA3CxTAIgsUwDpLFMAiixTAPcsUwCILFMAAi1TAIosUwAOLVMAiCxTAB8tUwCKLFMAMS1TAIgsUwBFLVMAiixTAFotUwCILFMAai1TAIosUwB7LVMAiCxTAIktUwCKLFMAmC1TAIgsUwCfLVMAiixTAKctUwCILFMAtC1TAIosUwDCLVMAiCxTAM0tUwCKLFMA2S1TAIgsUwDhLVMAiixTAOotUwCILFMA9S1TAIosUwABLlMAiCxTAA0uUwCKLFMAGi5TAIgsUwAlLlMAiixTADEuUwCILFMAOy5TAIosUwBGLlMAiCxTAFAuUwCKLFMAWy5TAIgsUwBpLlMAiixTAHguUwCILFMAiC5TAIosUwCZLlMAiCxTAKUuUwCKLFMAsi5TAIgsUwC9LlMAiixTAMkuUwCILFMA1i5TAIosUwDkLlMAiCxTAO4uUwCKLFMA+S5TAIgsUwACL1MAiixTAAwvUwCILFMAGC9TAIosUwAlL1MAiCxTAC0vUwCKLFM=" },
    @{ Offset = 1256584; Data = "MAAAcGJfdHJhaW5pbmcAcGJzX3RyYWluaW5nAHBiX3BhdGhmaW5kZXIAcGJzX3BhdGhmaW5kZXIAcGJfYnVybnZpbGxlAHBic19idXJudmlsbGUAcGJfZGF3bnZpbGxlAHBic19kYXdudmlsbGUAcGJfY2FycmlkZQBwYnNfY2FycmlkZQBwYl90YW5rZHJpdmV0b3duAHBic190YW5rZHJpdmV0b3duAHBiX3Rhbmtkcml2ZWNvdW50cnkAcGJzX3Rhbmtkcml2ZWNvdW50cnkAcGJfcGVnYXN1c25pZ2h0AHBic19wZWdhc3VzbmlnaHQAcGJfcGVnYXN1c2RheQBwYnNfcGVnYXN1c2RheQBwYl9kYW0AcGJzX2RhbQBwYl90cnVja3JpZGUAcGJzX3RydWNrcmlkZQBwYl9wb3djYW1wAHBic19wb3djYW1wAHBiX3NoaXAAcGJzX3NoaXAAcGJfY2hhdGVhdQBwYnNfY2hhdGVhdQBwYl9haXJmaWVsZABwYnNfYWlyZmllbGQAcGJfaHVydGdlbgBwYnNfaHVydGdlbgBwYl9yb2NrZXQAcGJzX3JvY2tldABwYl9iZXJsaW4AcGJzX2JlcmxpbgBwYl9zdGFsaW5ncmFkAHBic19zdGFsaW5ncmFkAHBiX3RyYWluc3RhdGlvbgBwYnNfdHJhaW5zdGF0aW9uAHBiX3JhaWx5YXJkAHBic19yYWlseWFyZABwYl9mYWN0b3J5AHBic19mYWN0b3J5AHBiX3JlZHNxdWFyZQBwYnNfcmVkc3F1YXJlAHBiX3BhdmxvdgBwYnNfcGF2bG92AHBiX3Nld2VyAHBic19zZXdlcgBwYl9icmVjb3VydABwYnNfYnJlY291cnQAcGJfZnVsbABwYnNfZnVsbA==" }
)

function Get-Md5U([string]$p) { (Get-FileHash -Algorithm MD5 -Path $p).Hash.ToUpper() }

# ---- locate the game ------------------------------------------------------
while ($true) {
    if ($GamePath -ne "") {
        $GamePath = $GamePath.Trim('"').Trim("'")
        if (Test-Path (Join-Path $GamePath "CoDSP.exe")) { break }
        Write-Host "CoDSP.exe not found in '$GamePath'." -ForegroundColor Yellow
    }
    $GamePath = Read-Host "Enter your game folder (the one with CoDSP.exe)"
}
$exe    = Join-Path $GamePath "CoDSP.exe"
$backup = "$exe.sr_backup"

# ---- revert ----------------------------------------------------------------
if ($Revert) {
    if (!(Test-Path $backup)) { Write-Host "REVERT: no backup found ($backup)."; exit 1 }
    Copy-Item $backup $exe -Force
    Remove-Item $backup
    if ((Get-Md5U $exe) -eq $stockMd5) { Write-Host "OK: CoDSP.exe restored to stock 1.3." -ForegroundColor Green }
    else { Write-Host "WARNING: restored file is not stock 1.3 - check it manually." -ForegroundColor Yellow }
    exit 0
}

# ---- pre-flight checks ------------------------------------------------------
$cur = Get-Md5U $exe
if ($cur -eq $v18Md5) { Write-Host "Already patched (v18). Nothing to do." -ForegroundColor Green; exit 0 }
if ($knownOldPatched -contains $cur) {
    Write-Host "STOP: this CoDSP.exe carries an OLDER build of this patch (md5 $cur)." -ForegroundColor Yellow
    if (Test-Path $backup) {
        Write-Host "A backup exists - restoring stock first, then patching." -ForegroundColor Yellow
        Copy-Item $backup $exe -Force
        $cur = Get-Md5U $exe
    } else {
        Write-Host "No backup found. Restore a stock 1.3 CoDSP.exe first, then re-run." 
        exit 1
    }
}
if ($cur -ne $stockMd5) {
    Write-Host "STOP: CoDSP.exe is not stock 1.3 (md5 $cur)." -ForegroundColor Red
    Write-Host "This patch is offset-based and is only safe on the stock binary"
    Write-Host "(expected md5 $stockMd5). No-CD or otherwise modified"
    Write-Host "exes would get corrupted, so nothing was touched."
    exit 1
}

# ---- backup + patch ---------------------------------------------------------
if (!(Test-Path $backup)) {
    Copy-Item $exe $backup
    Write-Host "Backup created: CoDSP.exe.sr_backup"
}

$bytes = [IO.File]::ReadAllBytes($exe)
$written = 0
foreach ($blk in $patch) {
    $data = [Convert]::FromBase64String($blk.Data)
    [Array]::Copy($data, 0, $bytes, [int]$blk.Offset, $data.Length)
    $written += $data.Length
}
[IO.File]::WriteAllBytes($exe, $bytes)

# ---- verify -----------------------------------------------------------------
if ((Get-Md5U $exe) -eq $v18Md5) {
    Write-Host "OK: CoDSP.exe patched to v18 ($written bytes in $($patch.Count) blocks)." -ForegroundColor Green
    Write-Host "Bridges live: rt_velx10 (speed) / rt_wallms (wall clock) / rt_aslms (ASL time)."
    Write-Host "Settings and PB records now save to config.cfg automatically."
    Write-Host "Revert any time:  patch_exe.ps1 -Revert -GamePath `"$GamePath`""
} else {
    Write-Host "ERROR: md5 mismatch after writing - restoring the backup." -ForegroundColor Red
    Copy-Item $backup $exe -Force
    exit 1
}
