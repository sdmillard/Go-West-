$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$origin=Join-Path $root '.tools/fixed-hide-01.json'
$archive=Join-Path $root '.tools/fixed-hide-archives'
$copy=Join-Path $archive 'fixed-hide-01.json'
$receipt=Join-Path $archive 'receipt-01.json'
if((Test-Path -LiteralPath $origin) -or (Test-Path -LiteralPath $copy) -or (Test-Path -LiteralPath $receipt)){throw 'Refusing to overwrite fixed-hide cohort'}
New-Item -ItemType Directory -Force -Path $archive | Out-Null
$env:APPDATA=Join-Path $root '.tools/fixed-hide-userdata'
$log=Join-Path $root '.tools/fixed-hide-confirmation-01.log'
& (Join-Path $root '.tools/godot/Godot_v4.5.1-stable_win64_console.exe') --headless --path $root --script tests/fixed_hide_campaign.gd -- --confirmation *> $log
if($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|ERROR:|FAIL:')){Get-Content -LiteralPath $log -Tail 20;throw 'Fixed-hide campaign failed'}
$report=Get-Content -LiteralPath $origin -Raw | ConvertFrom-Json
if($report.errors.Count -ne 0 -or $report.rows.Count -ne 32){throw 'Invalid or incomplete campaign'}
Copy-Item -LiteralPath $origin -Destination $copy
$hash=(Get-FileHash -LiteralPath $origin).Hash.ToLower()
if($hash -ne (Get-FileHash -LiteralPath $copy).Hash.ToLower()){throw 'Archive mismatch'}
@{file='fixed-hide-01.json';sha256=$hash;source_commit=(git -C $root rev-parse HEAD)} | ConvertTo-Json | Set-Content -LiteralPath $receipt -Encoding utf8
Write-Output '32 roots completed and archived; zero errors'
