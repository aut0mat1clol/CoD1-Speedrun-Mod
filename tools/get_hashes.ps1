# Stage 3 (client patch) recon: hashes and dll inventory of the game.
# Changes NOTHING. Paste the whole output back to the chat.
param([string]$GamePath = "")
if($GamePath -eq ""){
    $GamePath = Read-Host "Game folder (e.g. D:\Call of Duty 1.3)"
}
$exe = Join-Path $GamePath "CoDSP.exe"
Write-Host "== exe =="
if(Test-Path $exe){
    $h = Get-FileHash $exe -Algorithm MD5
    $f = Get-Item $exe
    Write-Host ($h.Hash + "  len=" + $f.Length + "  " + $f.Name)
}else{
    Write-Host "CoDSP.exe NOT FOUND in $GamePath"
}
Write-Host ""
Write-Host "== dlls in game root and main\ =="
$main = Join-Path $GamePath "main"
$dirs = @($GamePath)
if(Test-Path $main){ $dirs += $main }
foreach($d in $dirs){
    Get-ChildItem $d -Filter *.dll -ErrorAction SilentlyContinue | ForEach-Object {
        $h = Get-FileHash $_.FullName -Algorithm MD5
        Write-Host ($h.Hash + "  len=" + $_.Length + "  " + $_.Name + "   [" + $d + "]")
    }
}
Write-Host ""
Write-Host "== pk3 inventory in main\ =="
Get-ChildItem (Join-Path $main "*.pk3") -ErrorAction SilentlyContinue | ForEach-Object {
    Write-Host ($_.Length.ToString().PadLeft(12) + "  " + $_.Name)
}
