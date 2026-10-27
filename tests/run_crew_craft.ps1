param([string]$Study='01')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$godot=Join-Path $root '.tools/godot/Godot_v4.5.1-stable_win64_console.exe'
$env:APPDATA=Join-Path $root '.tools/crew-craft-userdata'
$archive=Join-Path $root '.tools/crew-craft-archives'
New-Item -ItemType Directory -Force -Path $archive | Out-Null
foreach($contract in @('free','hired')){foreach($stock in @('none','goats')){foreach($arm in @('off','crew','craft')){
 $label="crew-craft-$Study-$contract-$stock-$arm"
 $origin=Join-Path $root ".tools/hunting-$label.json"
 $copy=Join-Path $archive "hunting-$label.json"
 $log=Join-Path $root ".tools/$label.log"
 $receipt=Join-Path $archive "receipt-$label.json"
 if((Test-Path -LiteralPath $origin) -or (Test-Path -LiteralPath $copy) -or (Test-Path -LiteralPath $receipt)){throw 'Refusing to overwrite cohort'}
 & $godot --headless --path $root --script tests/crew_craft_campaign.gd -- "--label=$label" --seed-start=571000 --seeds=4 --months=4,5 --professions=farmer --equipment=shared --methods=foot --pace=1 --accuracy=.65 --reserve-meals=2 --outfit=standard --motion=mobile --camp-work=support --fishing=support "--livestock=$stock" --stock-policy=aware --feeding-policy=fodder --runtime-label=new --mastery=skilled "--income=$arm" "--contract=$contract" *> $log
 if($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|ERROR:|FAIL:')){Get-Content -LiteralPath $log -Tail 20;throw 'Crew/craft cohort failed'}
 $report=Get-Content -LiteralPath $origin -Raw | ConvertFrom-Json
 if($report.errors.Count -ne 0 -or $report.runs.Count -ne 8){throw 'Invalid/incomplete cohort'}
 Copy-Item -LiteralPath $origin -Destination $copy
 $hash=(Get-FileHash -LiteralPath $origin).Hash.ToLower()
 if($hash -ne (Get-FileHash -LiteralPath $copy).Hash.ToLower()){throw 'Archive mismatch'}
 @{label=$label;file="hunting-$label.json";sha256=$hash;source_commit=(git -C $root rev-parse HEAD)} | ConvertTo-Json | Set-Content -LiteralPath $receipt -Encoding utf8
 Write-Output "$label : eight journeys archived, zero errors"
}}}
