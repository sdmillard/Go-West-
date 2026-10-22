param([string]$Destination = "$PSScriptRoot/local/history")
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $Destination | Out-Null
New-Item -ItemType File -Force -Path (Join-Path $PSScriptRoot 'local/.gdignore') | Out-Null
$sources = @(
    @{ id='palmer-1847'; file='palmer-1847-reprint-1906.html'; url='https://www.gutenberg.org/cache/epub/46906/pg46906-images.html' },
    @{ id='nps-kaw'; file='nps-kaw-ferry.html'; url='https://www.nps.gov/places/kansas-river-crossing-and-pappins-ferry.htm' },
    @{ id='nps-marshall'; file='nps-marshalls-ferry.html'; url='https://www.nps.gov/places/000/historic-trails-park-marshalls-ferry.htm' },
    @{ id='nebraska-kearny'; file='nebraska-fort-kearny.html'; url='https://history.nebraska.gov/fort-kearny-as-a-sort-of-one-horse-affair/' },
    @{ id='nps-fort-john'; file='nps-fort-john.html'; url='https://www.nps.gov/fola/faqs.htm?fullweb=1' }
)
$results = @()
foreach ($source in $sources) {
    $path = Join-Path $Destination $source.file
    & curl.exe -L --fail --silent --show-error --connect-timeout 20 --max-time 60 $source.url -o $path
    $entry = [ordered]@{ id=$source.id; file="local/history/$($source.file)"; url=$source.url; retrieved_utc=[DateTime]::UtcNow.ToString('o') }
    if ($LASTEXITCODE -ne 0) {
        $entry.status = 'download_failed'
        Write-Output "No local snapshot: $($source.id). Consult the cited page separately."
    } else {
        $entry.status = 'downloaded'
        $entry.bytes = (Get-Item -LiteralPath $path).Length
        $entry.sha256 = (Get-FileHash -LiteralPath $path).Hash.ToLowerInvariant()
    }
    $results += [pscustomobject]$entry
}
$results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'HISTORY_SOURCES.json') -Encoding utf8
Write-Output "Recorded $($results.Count) historical reference retrieval results."
