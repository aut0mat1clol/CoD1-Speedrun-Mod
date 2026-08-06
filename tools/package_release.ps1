# ============================================================================
# package_release.ps1 - собрать ПОЛНЫЙ раздаточный архив мода из твоей игры
#
# Берёт из игры готовые файлы (main\z_sr_speedrun_loctext.pk3 с уже вставленным
# хуком + configs\autoexec.cfg проекта (флаг ставится 14) + пропатченную
# пропатченная gamex86.dll из корня игры) и собирает ОДИН zip в .\release\ :
#   cod1_speedrun_1_0_2_full.zip - мод + спидометр + учёт паузы (RTA):
#     main\       -> кинуть в main игры (pk3 + autoexec.cfg)
#     game_root\  -> gamex86.dll кинуть в корень игры (с заменой, свой бэкап!)
# Предусловие: install.ps1 -Patch уже отработал из СВЕЖЕЙ копии проекта
# (dll-патч, md5 AB3FF2DF...; pk3 содержит 1.0.1 - скрипт это ПРОВЕРЯЕТ).
# Чистый GSC-вариант не собирается - нужен точный спидометр + паузы.
# ============================================================================

$ErrorActionPreference = "Stop"
$modRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Definition)
$wantVer = "1.0.2"   # свежесть pk3 проверяется по этой строке в _main.gsc
$wantDll = "AB3FF2DFBF7892E6DBEBC4A23E1615B4"

Write-Host "=== package_release: полный архив (мод + спидометр + паузы RTA, $wantVer) ===" -ForegroundColor Cyan

# --- путь к игре ---
$GamePath = ""
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

# --- pk3 из игры + проверка свежести (не старый ли билд стоит) ---
$pk3InGame = Join-Path $mainDir "z_sr_speedrun_loctext.pk3"
if(-not (Test-Path $pk3InGame)) {
    throw "В main нет z_sr_speedrun_loctext.pk3 - сначала запусти install.ps1 -Patch"
}
Add-Type -AssemblyName System.IO.Compression.FileSystem
$za = [IO.Compression.ZipFile]::OpenRead($pk3InGame)
try {
    $ent = $za.GetEntry("maps/speedrun/_main.gsc")
    if(-not $ent) { throw "В pk3 нет maps/speedrun/_main.gsc - это не наш пакет?!" }
    $rd = New-Object IO.StreamReader($ent.Open())
    $gsc = $rd.ReadToEnd(); $rd.Close()
} finally { $za.Dispose() }
if(-not $gsc.Contains("Speedrun mod loaded ($wantVer)")) {
    throw "pk3 в игре НЕ версии $wantVer (старая сборка!). Обнови проект, запусти install.ps1 -Patch заново и повтори упаковку."
}
Write-Host "pk3 свежий: $pk3InGame ($($gsc.Length) байт gsc, версия $wantVer)" -ForegroundColor Green

# --- пропатченная dll (точный спидометр + wall-clock пауз) ---
$dllPatched = Join-Path $GamePath "gamex86.dll"
if(-not (Test-Path $dllPatched)) { throw "gamex86.dll не найден в корне игры?" }
$h = (Get-FileHash $dllPatched -Algorithm MD5).Hash
if($h -ne $wantDll) {
    throw "gamex86.dll не пропатчена ожидаемо (md5 $h). Сначала: powershell -ExecutionPolicy Bypass -File install.ps1 -Patch"
}
Write-Host "gamex86.dll пропатчена (md5 AB3FF2DF...) - беру" -ForegroundColor Green

# --- autoexec: флаг rt_dll_api принудительно 14 ---
$autoSrc = Join-Path $modRoot "configs\autoexec.cfg"
if(-not (Test-Path $autoSrc)) { throw "Нет $autoSrc" }
$autoTxt = [IO.File]::ReadAllText($autoSrc)
if($autoTxt -match '(?m)^seta rt_dll_api "\d+"') {
    $autoTxt = [regex]::Replace($autoTxt, '(?m)^seta rt_dll_api "\d+"', 'seta rt_dll_api "14"')
} else {
    $autoTxt += "`r`nseta rt_dll_api `"14`"`r`n"
}

# --- staging ---
$stage = Join-Path $env:TEMP ("sr_release_" + [Guid]::NewGuid().ToString("N"))
$bMain = Join-Path $stage "full\main"
$bRoot = Join-Path $stage "full\game_root"
New-Item -ItemType Directory -Path $bMain -Force | Out-Null
New-Item -ItemType Directory -Path $bRoot -Force | Out-Null

Copy-Item $pk3InGame (Join-Path $bMain "z_sr_speedrun_loctext.pk3") -Force
$utf8bom = New-Object System.Text.UTF8Encoding($true)
[IO.File]::WriteAllText((Join-Path $bMain "autoexec.cfg"), $autoTxt, $utf8bom)
Copy-Item $dllPatched (Join-Path $bRoot "gamex86.dll") -Force

$installTxt = @"
УСТАНОВКА (Call of Duty 2003, одиночная кампания, патч 1.3):

1. Скопируй файлы из папки "main" этого архива в папку "main" СВОЕЙ игры
   (она лежит рядом с CoDSP.exe, в ней же pak0.pk3).
2. Точный спидометр + учёт паузы: сохрани свой оригинальный gamex86.dll из
   КОРНЯ игры (куда-нибудь рядом, вдруг откатывать), затем скопируй
   gamex86.dll из папки "game_root" этого архива в КОРЕНЬ игры (с заменой).
3. Запусти игру, загрузи любую карту. Мод МОЛЧИТ по умолчанию (sr_debug 0):
   видны только важные строки Reset / Map Time / Run End. Для проверки
   набери в консоли (~):  set sr_debug 1  - и при новой загрузке карты жди:
     "Speedrun mod loaded (1.0.2)"
     "pause clock ON"
   Спидометр - в центре экрана, общее время справа вверху под Level Time.
   Формат тотала H:MM:SS.mmm с нулями; цвет спидометра по скорости:
     190+ зелёный, 250+ жёлтый, 300+ красный (ниже - белый).

ПРОВЕРКА:
- ESC-пауза ~5 секунд -> "[SR] PAUSE: +5.048s counted (menu time runs)"
  и общее время выросло на ~5 c (время в меню СЧИТАЕТСЯ, RTA).
- F5/F9 -> "[SR] LOAD: total continued from ... s" - загрузки НЕ считаются.
- Экран брифинга перед миссией -> "[SR] PRE-MISSION: +...s screen time
  skipped (not counted)" - тоже НЕ считается.
- Новая игра (training) сбрасывает ран сама.

ОТКАТ: верни свой gamex86.dll на место; удали z_sr_speedrun_loctext.pk3 и
autoexec.cfg из main игры.

ЧТО ВНУТРИ: точный спидометр (скорость из ps.velocity движка), таймер рана
(переживает F9: архивный канал), пауза по wall-clock (RTA), автосплиты в
лог, финальный сплит на Берлине, заморозка на титрах.
Управление - через консоль (~):
  set sr_speedo 0|1   - спидометр вкл/выкл
  set sr_igt 0|1      - таймеры вкл/выкл
  set sr_spd_dec 0..3 - знаков после точки у спидометра
  set sr_maxwin 30    - окно авто-сброса макс. скорости, сек (0 = выкл)
  set sr_debug 0|1    - подробные строки [SR] (LOAD/PAUSE/HUD...); 0 = тихо
  set com_maxfps 125  - фикс fps (физика зависит от fps!)
Полный сброс рана: set rt_run_total 0; set rt_ms_cur 0; set rt_spd_max 0; set rt_end_frozen 0; set rt_cont_real 0; set rt_cont_wall 0; set rt_cmd_mreset 1

ВНИМАНИЕ:
- только версия 1.3, одиночная игра;
- pk3 содержит хук в стоковый maps\_load.gsc версии 1.3 (с нестандартным
  набором pak/русификатором может перекрыть их _load.gsc - обычно безвредно);
- замена gamex86.dll - на стороне получателя: оригинал пусть сохранит.
"@
[IO.File]::WriteAllText((Join-Path $stage "full\INSTALL.txt"), $installTxt, $utf8bom)

$release = Join-Path $modRoot "release"
if(-not (Test-Path $release)) { New-Item -ItemType Directory -Path $release | Out-Null }
$zip = Join-Path $release "cod1_speedrun_1_0_2_full.zip"
if(Test-Path $zip) { Remove-Item $zip -Force }
Compress-Archive -Path (Join-Path $stage "full\*") -DestinationPath $zip
Remove-Item $stage -Recurse -Force

Write-Host ""
Write-Host "=== Готово: $zip ===" -ForegroundColor Green
Write-Host "Получателю: распаковать, main\ -> в main игры, game_root\gamex86.dll -> в корень игры (свой забэкапить)."
Write-Host "Только 1.3, одиночная."
Read-Host "Нажми Enter для выхода"
