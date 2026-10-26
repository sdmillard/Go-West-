param([ValidateSet(1,2)][int]$Version=1)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$manifest=Get-Content -LiteralPath (Join-Path $root ('docs/income-comparison-manifest-{0:d2}.json' -f $Version)) -Raw | ConvertFrom-Json
$godot=Join-Path $root '.tools/godot/Godot_v4.5.1-stable_win64_console.exe'
$env:APPDATA=Join-Path $root '.tools/income-comparison-userdata'
$archive=Join-Path $root '.tools/income-comparison-archives'
New-Item -ItemType Directory -Force -Path $archive | Out-Null
foreach($entry in $manifest.entries){
 $origin=Join-Path $root ('.tools/'+$entry.filename)
 $copy=Join-Path $archive $entry.filename
 $log=Join-Path $root ('.tools/'+$entry.label+'.log')
 $receipt=Join-Path $root ('.tools/receipt-'+$entry.label+'.json')
 if((Test-Path -LiteralPath $origin) -or (Test-Path -LiteralPath $copy) -or (Test-Path -LiteralPath $receipt)){throw 'Refusing to overwrite a cohort'}
 $script=if($Version -eq 1){'tests/income_balance_campaign.gd'}else{'tests/income_followup_campaign.gd'}
 $arguments=@('--headless','--path',$root,'--script',$script,'--',"--label=$($entry.label)","--seed-start=$($manifest.seed_start)","--seeds=$($manifest.seeds)","--months=$($manifest.months -join ',')",'--professions=farmer','--equipment=shared','--methods=foot','--pace=1','--accuracy=0.65','--reserve-meals=2','--outfit=standard','--motion=mobile','--camp-work=support','--fishing=support',"--livestock=$($entry.stock)",'--stock-policy=aware','--feeding-policy=fodder','--runtime-label=new','--mastery=skilled',"--income=$($entry.arm)")
 & $godot @arguments *> $log
 if($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|ERROR:|FAIL:')){Get-Content -LiteralPath $log -Tail 20;throw 'Income cohort failed'}
 $report=Get-Content -LiteralPath $origin -Raw | ConvertFrom-Json
 if($report.errors.Count -ne 0 -or $report.runs.Count -ne 8){throw 'Incomplete or invalid cohort'}
 Copy-Item -LiteralPath $origin -Destination $copy
 $hash=(Get-FileHash -LiteralPath $origin).Hash.ToLower()
 if($hash -ne (Get-FileHash -LiteralPath $copy).Hash.ToLower()){throw 'Archive mismatch'}
 @{label=$entry.label;origin=$origin;copy=$copy;sha256=$hash;log=$log;source_commit=(git -C $root rev-parse HEAD)} | ConvertTo-Json | Set-Content -LiteralPath $receipt -Encoding utf8
 Write-Output "$($entry.label): eight journeys archived, zero errors"
}
