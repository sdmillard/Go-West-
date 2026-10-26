param([Parameter(Mandatory=$true)][ValidateSet('old','new','fodder')][string]$Worker, [string]$ManifestFile = '.tools/dairy-balance-manifest-01.json')
$ErrorActionPreference = 'Stop'
$studyRoot = Split-Path -Parent $PSScriptRoot
$manifestPath = Join-Path $studyRoot $ManifestFile
$manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
$godotPath = Join-Path $studyRoot '.tools/godot/Godot_v4.5.1-stable_win64_console.exe'
$env:APPDATA = Join-Path $studyRoot ('.tools/dairy-balance-' + $Worker + '-userdata')
foreach ($entry in @($manifest.entries | Where-Object worker -EQ $Worker)) {
    $checkout = Join-Path $studyRoot ($manifest.trees.PSObject.Properties[$entry.runtime].Value)
    $origin = Join-Path $checkout ('.tools/' + $entry.filename)
    $copy = Join-Path $studyRoot ('.tools/' + $entry.filename)
    $log = Join-Path $studyRoot ('.tools/' + $entry.label + '.log')
    $receipt = Join-Path $studyRoot ('.tools/receipt-' + $entry.label + '.json')
    if ((Test-Path -LiteralPath $origin) -or (Test-Path -LiteralPath $copy) -or (Test-Path -LiteralPath $receipt)) { throw "Refusing to overwrite $($entry.label)" }
    $godotArgs = @('--headless','--path',$checkout,'--script','tests/dairy_balance_campaign.gd','--',
        "--label=$($entry.label)","--seed-start=$($entry.seed_start)","--seeds=$($entry.seeds)",
        '--months=5,7','--professions=farmer','--equipment=shared','--methods=foot','--pace=1',
        '--accuracy=0.65','--reserve-meals=2',"--outfit=$($entry.outfit)",'--motion=mobile',
        '--camp-work=support','--fishing=support',"--livestock=$($entry.arm)",'--stock-policy=aware',
        "--feeding-policy=$($entry.feeding_policy)","--runtime-label=$($entry.runtime)")
    & $godotPath @godotArgs *> $log
    $resultCode = $LASTEXITCODE
    if ($resultCode -ne 0 -or (Select-String -LiteralPath $log -Pattern 'SCRIPT ERROR:|ERROR:|FAIL:|FAIL UI:')) { Get-Content -LiteralPath $log -Tail 20; throw "Failed $($entry.label)" }
    $report = Get-Content -Raw -LiteralPath $origin | ConvertFrom-Json
    if ($report.errors.Count -ne 0 -or $report.runs.Count -ne 12) { throw "Incomplete report $($entry.label)" }
    Copy-Item -LiteralPath $origin -Destination $copy
    $hash = (Get-FileHash -LiteralPath $origin -Algorithm SHA256).Hash
    if ($hash -ne (Get-FileHash -LiteralPath $copy -Algorithm SHA256).Hash) { throw 'Archive copy hash mismatch' }
    @{label=$entry.label; origin=$origin; copy=$copy; sha256=$hash.ToLower(); log=$log} | ConvertTo-Json | Set-Content -LiteralPath $receipt
    Write-Output "$($entry.label): 12 journeys archived; zero errors"
}
