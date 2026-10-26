param([Parameter(Mandatory=$true)][ValidateSet('baseline','planning65')][string]$Worker)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$manifest=Get-Content -LiteralPath (Join-Path $root 'docs/bounded-survival-manifest-01.json') -Raw | ConvertFrom-Json
$godot=Join-Path $root '.tools/godot/Godot_v4.5.1-stable_win64_console.exe'
$env:APPDATA=Join-Path $root ('.tools/bounded-survival-'+$Worker+'-userdata')
$archive=Join-Path $root '.tools/bounded-survival-archives'
New-Item -ItemType Directory -Path $archive -Force | Out-Null
foreach($entry in @($manifest.entries | Where-Object variant -EQ $Worker)) {
 $origin=Join-Path $root ('.tools/'+$entry.filename)
 $copy=Join-Path $archive $entry.filename
 $log=Join-Path $root ('.tools/'+$entry.label+'.log')
 $receipt=Join-Path $root ('.tools/receipt-'+$entry.label+'.json')
 if((Test-Path -LiteralPath $origin) -or (Test-Path -LiteralPath $copy) -or (Test-Path -LiteralPath $receipt)){throw 'Refusing to overwrite a cohort'}
 $arguments=@('--headless','--path',$root,'--script','tests/farmer_mastery_campaign.gd','--',"--label=$($entry.label)","--seed-start=$($manifest.seed_start)","--seeds=$($manifest.seeds)","--months=$($manifest.months -join ',')",'--professions=farmer','--equipment=shared','--methods=foot','--pace=1',"--accuracy=$($manifest.accuracy)",'--reserve-meals=2',"--outfit=$($entry.outfit)",'--motion=mobile','--camp-work=support','--fishing=support',"--livestock=$($entry.arm)",'--stock-policy=aware','--feeding-policy=fodder','--runtime-label=new',"--mastery=$($entry.mastery)")
 & $godot @arguments *> $log
 if($LASTEXITCODE -ne 0 -or (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|ERROR:|FAIL:')){Get-Content $log -Tail 15;throw 'Cohort failed'}
 $report=Get-Content -LiteralPath $origin -Raw | ConvertFrom-Json
 if($report.errors.Count -ne 0 -or $report.runs.Count -ne 12){throw 'Incomplete or invalid cohort'}
 Copy-Item -LiteralPath $origin -Destination $copy
 $hash=(Get-FileHash -LiteralPath $origin).Hash.ToLower()
 if($hash -ne (Get-FileHash -LiteralPath $copy).Hash.ToLower()){throw 'Archive mismatch'}
 @{label=$entry.label;origin=$origin;copy=$copy;sha256=$hash;log=$log} | ConvertTo-Json | Set-Content -LiteralPath $receipt -Encoding utf8
 Write-Output "$($entry.label): twelve journeys archived; zero errors"
}
