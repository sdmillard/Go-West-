param([string]$Installer = "$PSScriptRoot/../local/user-windows-repack.exe")
$ErrorActionPreference = 'Stop'
$docker = (Get-Command docker -ErrorAction Stop).Source
$project = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$context = Join-Path $project '.tools/reference-container-context'
New-Item -ItemType Directory -Force -Path $context | Out-Null
Copy-Item -LiteralPath (Resolve-Path -LiteralPath $Installer).Path -Destination (Join-Path $context 'installer.exe') -Force
Copy-Item -LiteralPath "$PSScriptRoot/Dockerfile","$PSScriptRoot/start.sh" -Destination $context -Force
& $docker build -t oregon-reference-wine:local $context
if ($LASTEXITCODE -ne 0) { throw 'Wine image build failed' }
& $docker build -f "$PSScriptRoot/relay.Dockerfile" -t oregon-reference-desktop:local $PSScriptRoot
if ($LASTEXITCODE -ne 0) { throw 'Desktop relay image build failed' }
