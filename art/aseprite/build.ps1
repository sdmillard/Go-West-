# Builds Aseprite scene scripts into art/aseprite/out/ for review, and with -Install copies
# the finished PNGs into art/pixels/ where the game loads them.
#   ./art/aseprite/build.ps1                       # every scene, preview only
#   ./art/aseprite/build.ps1 -Scene independence   # one scene
#   ./art/aseprite/build.ps1 -Scene independence -Install
param(
    [string[]]$Scene = @(),
    [switch]$Install,
    [string]$Aseprite = ''
)
$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '../..')

function Find-Aseprite {
    $candidates = @(
        $Aseprite,
        $env:ASEPRITE,
        (Join-Path $root '.tools/aseprite/bin/aseprite.exe'),
        "${env:ProgramFiles(x86)}\Steam\steamapps\common\Aseprite\Aseprite.exe",
        "$env:ProgramFiles\Steam\steamapps\common\Aseprite\Aseprite.exe",
        "$env:ProgramFiles\Aseprite\Aseprite.exe"
    )
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate)) { return $candidate }
    }
    $onPath = Get-Command aseprite -ErrorAction SilentlyContinue
    if ($onPath) { return $onPath.Source }
    throw 'Aseprite not found. Run art/aseprite/install_aseprite.ps1, install it from Steam, or pass -Aseprite <path to aseprite.exe>.'
}

$exe = Find-Aseprite
$kit = Join-Path $PSScriptRoot 'lib.lua'
$out = Join-Path $PSScriptRoot 'out'
$preview = Join-Path $out 'preview'
New-Item -ItemType Directory -Force -Path $preview | Out-Null
# Keep Godot from importing review copies, and start from a clean output folder.
Set-Content -LiteralPath (Join-Path $out '.gdignore') -Value ''
Get-ChildItem -Path $out, $preview -Filter '*.png' | Remove-Item

$scripts = if ($Scene.Count -gt 0) {
    $Scene | ForEach-Object { Join-Path $PSScriptRoot "scenes/$_.lua" }
} else {
    Get-ChildItem -Path (Join-Path $PSScriptRoot 'scenes') -Filter '*.lua' | ForEach-Object { $_.FullName }
}

foreach ($script in $scripts) {
    if (-not (Test-Path -LiteralPath $script)) { throw "No scene script: $script" }
    $log = & $exe -b --script-param "kit=$kit" --script-param "out=$out" --script $script 2>&1
    $log | Write-Output
    if ($LASTEXITCODE -ne 0 -or ($log -match '\.lua:\d+:')) { throw "Scene failed: $script" }
}

foreach ($png in Get-ChildItem -Path $out -Filter '*.png') {
    # 3x nearest-neighbour copy for looking at the result.
    & $exe -b $png.FullName --scale 3 --save-as (Join-Path $preview ($png.BaseName + '_x3.png')) | Out-Null
    if ($Install) {
        Copy-Item -LiteralPath $png.FullName -Destination (Join-Path $root "art/pixels/$($png.Name)") -Force
        Write-Output "installed art/pixels/$($png.Name)"
    }
}
Write-Output "Review copies: $preview"
if ($Install) { Write-Output 'Next: godot --headless --path . --editor --import, then ./test.ps1' }
