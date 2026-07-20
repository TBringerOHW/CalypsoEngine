# Build Godot 4.7 with GTS module
# Usage:
#   .\build.ps1                          # Default: editor build for Windows x86_64
#   .\build.ps1 -Target template_release # Build export template
#   .\build.ps1 -Arch arm64              # Build for ARM64
#   .\build.ps1 -Jobs 4                  # Parallel jobs (default: auto-detect)

param(
    [ValidateSet('editor', 'template_release', 'template_debug')]
    [string]$Target = 'editor',

    [ValidateSet('x86_64', 'arm64')]
    [string]$Arch = 'x86_64',

    [int]$Jobs = 0,  # 0 = auto-detect

    [switch]$Verbose
)

$ErrorActionPreference = 'Stop'

# CalypsoEngine is at $PSScriptRoot
# CalypsoProject is parent of CalypsoEngine
$calypsoEngine = $PSScriptRoot
$calypsoProject = Split-Path -Parent $calypsoEngine
$modulesDir = Join-Path $calypsoProject 'modules'
$binDir = Join-Path $calypsoEngine 'bin'

Write-Host "=== Godot 4.7 Build: $Target | $Arch ===" -ForegroundColor Cyan
Write-Host "Engine: $calypsoEngine" -ForegroundColor Gray
Write-Host "Modules: $modulesDir" -ForegroundColor Gray

if (-not (Test-Path $modulesDir)) {
    Write-Error "modules directory not found at $modulesDir"
    exit 1
}

if (-not (Test-Path $binDir)) {
    New-Item -ItemType Directory -Path $binDir | Out-Null
}

# Detect jobs if not specified
if ($Jobs -eq 0) {
    $Jobs = (Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property NumberOfLogicalProcessors -Sum).Sum
    Write-Host "Auto-detected CPU cores: $Jobs"
}

# Build command
$buildCmd = @(
    'scons'
    'platform=windows'
    "target=$Target"
    "arch=$Arch"
    "-j$Jobs"
    "custom_modules=../modules"
    'custom_modules_recursive=yes'
)

if ($Verbose) {
    $buildCmd += 'verbose=yes'
}

Write-Host "Building: $($buildCmd -join ' ')" -ForegroundColor Gray
Write-Host ""

& $buildCmd[0] $buildCmd[1..($buildCmd.Length-1)]

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed with exit code $LASTEXITCODE"
    exit $LASTEXITCODE
}

Write-Host ""
Write-Host "=== Build complete ===" -ForegroundColor Green
Write-Host "Binaries: $binDir" -ForegroundColor Gray

# List built binaries
$exes = Get-ChildItem $binDir -Filter 'godot.windows.*'
if ($exes) {
    Write-Host "Available binaries:"
    $exes | ForEach-Object { Write-Host "  - $($_.Name)" }
}
