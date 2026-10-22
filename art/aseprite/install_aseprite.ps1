# Compiles a headless (no window) Aseprite into .tools/aseprite/bin for the Lua art scripts.
# Aseprite's EULA allows compiling for personal use only: never commit or share the binary.
# The Steam version works too; build.ps1 finds it without this script.
#
# Needs, once: Git, and Visual Studio 2022 (Community or Build Tools) with the
# "Desktop development with C++" workload, which brings MSVC, the Windows SDK, CMake and Ninja.
# Takes roughly 10-20 minutes the first time. Run from the repository root:
#   powershell -ExecutionPolicy Bypass -File art/aseprite/install_aseprite.ps1
param([string]$Tag = 'v1.3.18.6')
$ErrorActionPreference = 'Stop'
$root = Resolve-Path (Join-Path $PSScriptRoot '../..')
$src = Join-Path $root '.tools/aseprite-src'
$dest = Join-Path $root '.tools/aseprite/bin'

# Load the 64-bit MSVC build environment (cl, cmake, ninja) into this session.
$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path -LiteralPath $vswhere)) { throw 'Visual Studio 2022 not found. Install it with the "Desktop development with C++" workload.' }
$vs = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if (-not $vs) { throw 'Visual Studio is missing the "Desktop development with C++" workload.' }
$vcvars = Join-Path $vs 'VC\Auxiliary\Build\vcvars64.bat'
cmd /c "`"$vcvars`" >nul && set" | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') { Set-Item -Path "env:$($Matches[1])" -Value $Matches[2] }
}
foreach ($tool in 'git', 'cmake', 'ninja', 'cl') {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "$tool is not available" }
}

if (-not (Test-Path -LiteralPath (Join-Path $src '.git'))) {
    git clone --recursive --depth 1 --branch $Tag https://github.com/aseprite/aseprite.git $src
    if ($LASTEXITCODE -ne 0) { throw 'git clone failed' }
}
$build = Join-Path $src 'build'
cmake -S $src -B $build -G Ninja -DCMAKE_BUILD_TYPE=Release `
    -DLAF_BACKEND=none -DENABLE_UI=OFF -DENABLE_NEWS=OFF -DENABLE_UPDATER=OFF `
    -DENABLE_WEBSOCKET=OFF -DENABLE_CCACHE=OFF -DLAF_WITH_EXAMPLES=OFF -DLAF_WITH_TESTS=OFF
if ($LASTEXITCODE -ne 0) { throw 'cmake configure failed' }
cmake --build $build --target aseprite
if ($LASTEXITCODE -ne 0) { throw 'Aseprite build failed' }
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Copy-Item -Path (Join-Path $build 'bin/*') -Destination $dest -Recurse -Force
& (Join-Path $dest 'aseprite.exe') --version
