param([string]$Destination = "$PSScriptRoot/local")
$ErrorActionPreference = 'Stop'
New-Item -ItemType Directory -Force -Path $Destination | Out-Null
New-Item -ItemType File -Force -Path (Join-Path $Destination '.gdignore') | Out-Null
$sources = @(
    @{ id='basic-1975'; file='oregon-trail-1975.bas'; url='https://raw.githubusercontent.com/fortran-gaming/oregon-trail-1975/master/oregon-trail-1975.bas' },
    @{ id='basic-1978'; file='oregon-trail-1978.bas'; url='https://raw.githubusercontent.com/fortran-gaming/oregon-trail-1975/master/oregon-trail-1978.bas' },
    @{ id='basic-readme'; file='basic-repository-README.md'; url='https://raw.githubusercontent.com/fortran-gaming/oregon-trail-1975/master/README.md' },
    @{ id='basic-license'; file='basic-repository-LICENSE'; url='https://raw.githubusercontent.com/fortran-gaming/oregon-trail-1975/master/LICENSE' },
    @{ id='manual-1985'; file='mecc-1985-apple-ii-manual.pdf'; url='https://mirrors.apple2.org.za/ftp.apple.asimov.net/images/educational/mecc/documentation/oregon_trail/The%20Oregon%20Trail.pdf' },
    @{ id='bouchard-design'; file='bouchard-imagining-design.html'; url='https://www.philipbouchard.com/oregon-trail/imagining-design.html' },
    @{ id='bouchard-rivers'; file='bouchard-crossing-rivers.html'; url='https://www.philipbouchard.com/oregon-trail/crossing-rivers.html' },
    @{ id='bouchard-geography'; file='bouchard-geography.html'; url='https://www.philipbouchard.com/oregon-trail/real-geography.html' },
    @{ id='mecc-history'; file='mecc-history.html'; url='https://mecc.co/history/' },
    @{ id='windows-1993-reference'; file='windows-1993-reference.html'; url='https://oregontrail.ws/games/the-oregon-trail-cd-rom' },
    @{ id='creative-computing-1978'; file='creative-computing-1978-05.pdf'; url='https://archive.org/download/creativecomputing-1978-05/Creative_Computing_v04_n03_1978_May-June.pdf' }
)
$results = @()
foreach ($source in $sources) {
    $path = Join-Path $Destination $source.file
    & curl.exe -L --fail --silent --show-error --connect-timeout 20 --max-time 180 $source.url -o $path
    $entry = [ordered]@{ id=$source.id; file=$source.file; url=$source.url; retrieved_utc=[DateTime]::UtcNow.ToString('o') }
    if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $path)) {
        $entry.status = 'downloaded'
        $entry.sha256 = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
        $entry.bytes = (Get-Item -LiteralPath $path).Length
        Write-Output "Downloaded $($source.id): $($entry.bytes) bytes"
    } else {
        $entry.status = 'failed'
        Write-Output "Unavailable: $($source.id)"
    }
    $results += [pscustomobject]$entry
}
$results | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $Destination 'manifest.json') -Encoding utf8
