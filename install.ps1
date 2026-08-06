# ============================================================================
# install.ps1 - ЕДИНСТВЕННЫЙ установщик Speedrun-мода (1.0) в CoD1 (патч 1.3)
#
#   powershell -ExecutionPolicy Bypass -File install.ps1
#       чистая установка: pk3 в main + autoexec (файлов игры не меняет)
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Patch
#       установка + НАТИВНЫЙ СЛОЙ: бинарный мини-патч gamex86.dll
#       (точный спидометр из ps.velocity; ТРЕНИРОВКИ до вердикта модеров)
#   powershell -ExecutionPolicy Bypass -File install.ps1 -Revert
#       снять только патч (dll из .sr_backup + флаг 0); pk3 остаётся
#
# Если ругается на права (игра в Program Files) - PowerShell от администратора.
# ============================================================================

param([string]$GamePath = "", [switch]$Patch, [switch]$Revert, [switch]$Force)

$ErrorActionPreference = "Stop"
$modRoot = Split-Path -Parent $MyInvocation.MyCommand.Definition

Write-Host "=== CoD1 Speedrun mod installer (1.3, 1.0.3) ===" -ForegroundColor Cyan

# --- путь к игре ---
while($true) {
    if($GamePath -eq "") {
        $GamePath = Read-Host 'Введи путь к папке игры (где CoDSP.exe)'
    }
    $GamePath = $GamePath.Trim('"').Trim("'")
    if(Test-Path (Join-Path $GamePath "CoDSP.exe")) { break }
    Write-Host "CoDSP.exe не найден в '$GamePath'. Попробуй ещё раз." -ForegroundColor Yellow
    $GamePath = ""
}
$mainDir = Join-Path $GamePath "main"
if(-not (Test-Path $mainDir)) { throw "Не найдена папка $mainDir" }
Write-Host "Игра найдена: $GamePath" -ForegroundColor Green

$dll  = Join-Path $GamePath "gamex86.dll"
$bak  = "$dll.sr_backup"
$cfgp = Join-Path $mainDir "autoexec.cfg"
if(-not (Test-Path $dll)){ throw "gamex86.dll не найден в $GamePath" }

# --- флаг нативного слоя в main\autoexec.cfg (ставим ТОЛЬКО мы) ---
function Set-ApiFlag([string]$val){
    $lines = @()
    if(Test-Path $cfgp){
        $lines = @(Get-Content $cfgp | Where-Object { $_ -notmatch 'dll_api' })
    }
    $lines += ("seta rt_dll_api " + $val)
    Set-Content -Path $cfgp -Value $lines -Encoding ASCII
    Write-Host ("main\autoexec.cfg: seta rt_dll_api " + $val)
}

# ============================================================================
# РЕЖИМ -Revert: снять патч, флаг 0, выход (pk3 не трогаем)
# ============================================================================
if($Revert){
    if(Test-Path $bak){
        Copy-Item $bak $dll -Force
        Write-Host "gamex86.dll восстановлена из .sr_backup" -ForegroundColor Green
        Set-ApiFlag "0"
        Write-Host "Мод продолжит работать в чистом GSC-режиме (слой 1)." -ForegroundColor Green
    } else {
        Write-Host "Нет .sr_backup - откатывать нечего"
    }
    Read-Host "Нажми Enter для выхода"
    exit
}

# ============================================================================
# РЕЖИМЫ install / install -Patch: сначала патч (если просили), потом pk3
# ============================================================================

# --- нативный слой: бинарный мини-патч gamex86.dll (PIC, reloc-safe) ---
function Invoke-SrPatch {
    $BODY  = 0x15630   # getfractionstartammo body (0x110 bytes, stock)
    $POFF  = 0x1568C   # reloc-safe 48-byte window inside it
    $CAVEF = 0x86d00   # old experimental cave (zeroed for determinism)
    $TBL1  = 0x8b154; $TBL1S = [uint32]0x2001a380  # setTenthsTimerUp (stock)
    $TBL2  = 0x8b23c; $TBL2S = [uint32]0x20015630  # getfractionstartammo
    $TBL3  = 0x8b244; $TBL3S = [uint32]0x20015740  # getfractionmaxammo
    $BODY2 = 0x15740   # continuity api slot (0x180 bytes, stock)

    # каждое состояние dll, которое могли произвести наши инструменты
    $KNOWN = @(
        "E372B593A2B73C21D6BDDA82C3AD812F",  # stock 1.3
        "21D8B9BE40F838D6FBAC3B7406F8207D",  # v1
        "377488AE0590A2FA377D17EF0609638D",  # cave gclient, hud hook
        "B009DAE8264DE81EBFBAC5B168730F14",  # cave selftest, hud hook
        "978B200DD9F8DEE2847E46C2D012C422",  # cave probe, hud hook
        "D1D981759B6CB8EBDCC3E8150E46D7A8",  # cave gclient, player hook
        "01A119330648B80C2B535447FD419960",  # cave selftest, player hook
        "34816819E5C131B5F0A62E56B72FB185",  # cave probe, player hook
        "6A0B7891B6B63DF6EA8172D75CC0655A",  # cave v4 exe-read, player hook
        "FD0598BE881500912151BC6226FAECDE",  # cave v4 exe-read, hud hook
        "D1D1BC53F4941E4AC4EEEBC044B74A6B",  # v5/v6 in-place real
        "92D5C34F2650EC551B36543272FBEBD0",  # v5/v6 in-place selftest
        "F38036C929D14879F083E2FAD09DEB6B",  # v5/v6 in-place probe
        "BF4FCBAB8F5FA1CF885C4EE5C715B7AE",  # v5/v6 in-place gclient fallback
        "8518B81E412AE6A2B0045430A30BE357",  # v7 PIC real (bad stack cleanup)
        "7258436ED242B4A6600E5F8216033919",  # v7 PIC selftest (bad stack cleanup)
        "32DA4CA3DBBA50D7316E581BF63849FC",  # v7 PIC probe (bad stack cleanup)
        "38362F73EC1319392D55CBE835950073",  # v8 PIC diag (null-slot marker)
        "05DB055F662C37EB30380890B4372144",  # v9 cdecl-fixed real
        "65AA2B437E7223D678148356D47D8FDC",  # v9 cdecl-fixed selftest
        "B90ABBC19C2EDE3A3EB17F8360AA5CDC",  # v9 cdecl-fixed probe
        "01296ED97782B1BF82ACB3B7A835699D",  # real + api
        "8838B4F0AC8A236D72DE1E5BE8D64F14",  # selftest + api
        "50C9AD3C75D2725FF622FEF50ABBE11F",  # probe + api
        "1B47381285FB1754992198EEAA277DD2",  # diag + api
        "AB3FF2DFBF7892E6DBEBC4A23E1615B4"   # speedo + wall-clock (целевое)
    )
    $expect = "AB3FF2DFBF7892E6DBEBC4A23E1615B4"

    $md5 = (Get-FileHash $dll -Algorithm MD5).Hash
    Write-Host "gamex86.dll md5: $md5"
    if(($KNOWN -notcontains $md5) -and -not $Force){
        Write-Host "MD5 не из списка известных состояний 1.3. Отмена (-Force на свой страх)." -ForegroundColor Yellow
        return $false
    }

    # velocity: sqrt(vx^2+vy^2) из CoDSP.exe globals @0x142FE6C/+4; PIC + cdecl
    $hex = "e80000000059d9056cfe4201d8c8d90570fe4201d8c8dec1d9fa51d91c248b81ef420d00ffd083c404c3"
    $pay = New-Object byte[] ($hex.Length / 2)
    for($i = 0; $i -lt $pay.Length; $i++){ $pay[$i] = [Convert]::ToByte($hex.Substring($i*2,2),16) }
    $tramp = [byte[]]@(0xE9,0x57,0x00,0x00,0x00)   # jmp 0x1568C

    # wall-clock: getfractionmaxammo() БЕЗ аргументов -> float(GetTickCount()).
    # Реальный ms-тикер, идущий даже в ESC-меню (учёт паузы делается в GSC).
    # Без чтения аргументов вообще - обходится arg-мистерия старых билдов. Трамплин +
    # payload уложены в те же reloc-чистые окна.
    $api = @(
        @(0x15740, "e8000000005989cee94f000000"),
        @(0x1579C, "8b86bb190700ffd050db0424d91c248b863b420d00ffd083c404c3")
    )

    $b = [System.IO.File]::ReadAllBytes($dll)

    # 1) таблицы методов обратно в сток (снять древние репойнты)
    foreach($t in @(@($TBL1,$TBL1S), @($TBL2,$TBL2S), @($TBL3,$TBL3S))){
        $v = [BitConverter]::ToUInt32($b, $t[0])
        if($v -eq 0x20086d00){
            [BitConverter]::GetBytes([uint32]$t[1]).CopyTo($b, $t[0])
        }elseif($v -ne $t[1]){
            Write-Host ("Чужие байты таблицы 0x{0:x8} по 0x{1:x}. Отмена." -f $v, $t[0]) -ForegroundColor Yellow
            return $false
        }
    }

    # 2) зачистка старой пещеры
    for($i = 0; $i -lt 256; $i++){ $b[$CAVEF + $i] = 0 }

    # 3) гварды тел: сток или наши состояния
    $b0 = $b[$BODY]; $b1 = $b[$BODY+1]
    $ok1 = ($b0 -eq 0x51 -and $b1 -eq 0x8b) -or ($b0 -eq 0xd9 -or $b0 -eq 0x57 -or $b0 -eq 0xe9 -or ($b0 -eq 0x51 -and $b1 -ne 0x8b))
    $c0 = $b[$BODY2]
    $ok2 = ($c0 -eq 0x51) -or ($c0 -eq 0xe8)
    if((-not $ok1 -or -not $ok2) -and -not $Force){
        Write-Host "Неожиданные байты тел методов. Отмена." -ForegroundColor Yellow
        return $false
    }

    if(-not (Test-Path $bak)){
        Copy-Item $dll $bak
        Write-Host "Backup: $bak"
    }

    # 4) velocity: трамплин в начале тела + полезная нагрузка в окне
    for($i = 0; $i -lt 0x110; $i++){ $b[$BODY + $i] = 0 }
    $tramp.CopyTo($b, $BODY)
    $pay.CopyTo($b, $POFF)

    # 5) continuity api: зачистка слота + 5 кусков
    for($i = 0; $i -lt 0x180; $i++){ $b[$BODY2 + $i] = 0 }
    foreach($ck in $api){
        $addr = $ck[0]; $hx = $ck[1]
        for($i = 0; $i -lt ($hx.Length / 2); $i++){
            $b[$addr + $i] = [Convert]::ToByte($hx.Substring($i*2,2),16)
        }
    }

    [System.IO.File]::WriteAllBytes($dll, $b)

    # 6) верификация чтением с диска
    $chk = [System.IO.File]::ReadAllBytes($dll)
    $okT = ([BitConverter]::ToUInt32($chk, $TBL1) -eq $TBL1S) -and ([BitConverter]::ToUInt32($chk, $TBL2) -eq $TBL2S) -and ([BitConverter]::ToUInt32($chk, $TBL3) -eq $TBL3S)
    $okJ = ($chk[$BODY] -eq 0xE9) -and ($chk[$BODY+1] -eq 0x57)
    $okP = $true
    for($i=0; $i -lt $pay.Length; $i++){ if($chk[$POFF+$i] -ne $pay[$i]){ $okP=$false; break } }
    $okA = $true
    foreach($ck in $api){
        $addr = $ck[0]; $hx = $ck[1]
        for($i = 0; $i -lt ($hx.Length / 2); $i++){
            if($chk[$addr + $i] -ne [Convert]::ToByte($hx.Substring($i*2,2),16)){ $okA=$false; break }
        }
    }
    if($okT -and $okJ -and $okP -and $okA){
        $newmd5 = (Get-FileHash $dll -Algorithm MD5).Hash
        if($newmd5 -eq $expect){
            Write-Host "PATCH OK. md5 совпал: $newmd5" -ForegroundColor Green
            return $true
        }
        Write-Host ("Патч записан, но md5 $newmd5 != ожидаемому $expect - сообщи разработчику") -ForegroundColor Yellow
        return $false
    }
    Write-Host "VERIFY FAILED - восстанавливаю бэкап" -ForegroundColor Red
    Copy-Item $bak $dll -Force
    return $false
}

if($Patch){
    if(Invoke-SrPatch){
        Set-ApiFlag "14"
    } else {
        Write-Host "Нативный слой НЕ установлен - продолжаю чистую установку pk3." -ForegroundColor Yellow
        Set-ApiFlag "0" # не даём устаревшему флагу врать про наличие api
    }
}

# ============================================================================
# ЧИСТАЯ УСТАНОВКА: хук в _load.gsc + pk3 + autoexec
# ============================================================================
Add-Type -AssemblyName System.IO.Compression.FileSystem

# --- 1. ищем maps/_load.gsc во ВСЕХ pk3 (важен ПОСЛЕДНИЙ по алфавиту) ---
$paks = Get-ChildItem (Join-Path $mainDir "*.pk3") -ErrorAction SilentlyContinue | Sort-Object Name
$loadGsc = $null
$sourcePak = $null

foreach($pak in $paks) {
    try {
        $z = [System.IO.Compression.ZipFile]::OpenRead($pak.FullName)
        $e = $z.Entries | Where-Object { ($_.FullName -replace '\\','/') -ieq 'maps/_load.gsc' } | Select-Object -First 1
        if($e) {
            $reader = New-Object System.IO.StreamReader($e.Open())
            $loadGsc = $reader.ReadToEnd()
            $reader.Close()
            $sourcePak = $pak.Name
        }
        $z.Dispose()
    } catch {
        Write-Host ("  ! " + $pak.Name + " не открылся (не zip?) - пропускаю") -ForegroundColor Yellow
    }
}

if($null -eq $loadGsc) {
    $loose = Join-Path $mainDir "maps\_load.gsc"
    if(Test-Path $loose) {
        $loadGsc = [System.IO.File]::ReadAllText($loose)
        $sourcePak = "main\maps\_load.gsc (распакован)"
    }
}

if($null -eq $loadGsc) {
    Write-Host ""
    Write-Host "maps/_load.gsc не найден ни в одном pk3, ни в main\maps\" -ForegroundColor Red
    foreach($pak in $paks) {
        try {
            $z = [System.IO.Compression.ZipFile]::OpenRead($pak.FullName)
            $gscCount = ($z.Entries | Where-Object { $_.FullName -like '*.gsc' }).Count
            $z.Dispose()
            Write-Host ("  " + $pak.Name + "  ->  gsc-файлов: " + $gscCount)
        } catch {
            Write-Host ("  " + $pak.Name + "  ->  не открывается как zip")
        }
    }
    throw "Дальше не иду без _load.gsc"
}
Write-Host "_load.gsc найден в: $sourcePak" -ForegroundColor Green

# --- 2. вставляем строку хука (если ещё не вставлена) ---
if($loadGsc -match 'speedrun\\_main::init') {
    Write-Host "Хук уже вставлен - пропускаю"
} else {
    $iMain = $loadGsc.IndexOf("main()")
    if($iMain -lt 0) { throw "main() не найден в _load.gsc" }
    $iBrace = $loadGsc.IndexOf("{", $iMain)
    $hook = "`r`n`tthread maps\speedrun\_main::init();`t// [SR] speedrun mod hook"
    $loadGsc = $loadGsc.Insert($iBrace + 1, $hook)
    Write-Host "Хук вставлен в _load.gsc"
}

$mapsDir = Join-Path $modRoot "src_loctext\maps"
if(-not (Test-Path $mapsDir)) { New-Item -ItemType Directory -Path $mapsDir | Out-Null }
[System.IO.File]::WriteAllText((Join-Path $mapsDir "_load.gsc"), $loadGsc, (New-Object System.Text.UTF8Encoding($false)))

# --- 3. собираем ЕДИНСТВЕННЫЙ pk3 ---
function New-Pk3($outPath, $srcDirs) {
    if(Test-Path $outPath) { Remove-Item $outPath -Force }
    $files = @{}
    foreach($d in $srcDirs) {
        $dd = Join-Path $modRoot $d
        if(-not (Test-Path $dd)) { continue }
        Get-ChildItem $dd -Recurse -File | ForEach-Object {
            $rel = $_.FullName.Substring($dd.Length + 1) -replace '\\','/'
            $files[$rel] = $_.FullName
        }
    }
    $zip = [System.IO.Compression.ZipFile]::Open($outPath, 'Create')
    foreach($rel in $files.Keys) {
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $zip, $files[$rel], $rel, [System.IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
    $zip.Dispose()
}

$pk3 = Join-Path $modRoot "z_sr_speedrun_loctext.pk3"
New-Pk3 $pk3 @("src_loctext")
Write-Host "Собран z_sr_speedrun_loctext.pk3 (включает _load.gsc с хуком)"

# --- 4. main: сносим ВСЕ старые варианты и кладём один ---
foreach($old in @("z_sr_speedrun.pk3","z_sr_speedrun_hudelem.pk3","z_sr_speedrun_colon.pk3","z_sr_speedrun_loctext.pk3")) {
    $p = Join-Path $mainDir $old
    if(Test-Path $p) { Remove-Item $p -Force }
}
Copy-Item $pk3 (Join-Path $mainDir "z_sr_speedrun_loctext.pk3") -Force
Write-Host "В main положен z_sr_speedrun_loctext.pk3; старые pk3 удалены" -ForegroundColor Green

$staleBinds = Join-Path $mainDir "sr_binds.cfg"
if(Test-Path $staleBinds) {
    Remove-Item $staleBinds -Force
    Write-Host "Удалён устаревший main\sr_binds.cfg (бинды упразднены)"
}

# --- 5. autoexec.cfg: обновляем, НО сохраняем флаг нативного слоя ---
$apiFlag = "0"
if(Test-Path $cfgp){
    foreach($l in (Get-Content $cfgp -ErrorAction SilentlyContinue)){
        if($l -match 'dll_api\s+"?(\d+)'){ $apiFlag = $Matches[1] }
    }
}
Copy-Item (Join-Path $modRoot "configs\autoexec.cfg") $cfgp -Force
if([int]$apiFlag -ge 1){
    Set-ApiFlag $apiFlag
    Write-Host ("autoexec.cfg обновлён, флаг rt_dll_api " + $apiFlag + " сохранён (патч активен)") -ForegroundColor Green
} else {
    Write-Host "autoexec.cfg положен в main (флаг rt_dll_api; ставится -Patch)" -ForegroundColor Green
}

# --- 6. финальные подсказки ---
Write-Host ""
Write-Host "=== Готово! ===" -ForegroundColor Cyan
Write-Host '1) Ярлык запуска:  CoDSP.exe +set developer 1'
Write-Host '2) Новая игра или devmap dawnville. По умолчанию мод ТИХИЙ (sr_debug 0):'
Write-Host '   видны только Reset / Map Time / Run End. Диагностика: set sr_debug 1'
Write-Host '   -> тогда жди "Speedrun mod loaded (1.0.3)" + "pause clock ON"'
Write-Host '3) Ручной сброс рана из консоли:'
Write-Host '   set rt_run_total 0; set rt_spd_max 0; set rt_end_frozen 0; set rt_cont_real 0; set rt_cmd_mreset 1'
Write-Host '4) Тоглы: set sr_speedo 0/1, set sr_igt 0/1; знаки после точки: set sr_spd_dec 0..3; шум: set sr_debug 0/1'
if(-not $Patch){
    Write-Host '5) Нативный слой (тренировки):  install.ps1 -Patch    (снять: -Revert)'
}
Read-Host "Нажми Enter для выхода"
