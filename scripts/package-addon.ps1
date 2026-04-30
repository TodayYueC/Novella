param(
    [string]$Version = "",
    [string]$OutputDir = "dist"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = (Select-String -Path "addons/novella/core/constants.gd" -Pattern '^const VERSION := "(.+)"$').Matches.Groups[1].Value
}

& "$PSScriptRoot\validate-release.ps1" -SkipGodotTests

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
$archivePath = Join-Path $OutputDir "novella-$Version.zip"

$paths = @(
    "addons/novella",
    "docs",
    "examples",
    "scripts",
    "tests",
    "README.md",
    "LICENSE",
    "project.godot"
)

git archive --format=zip --output=$archivePath HEAD @paths

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Created $archivePath"
