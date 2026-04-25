param(
    [string]$GodotExe = ".\GodotEngine\Godot_v4.6.2-stable_mono_win64\Godot_v4.6.2-stable_mono_win64_console.exe"
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$resolvedRoot = Resolve-Path $root
$resolvedGodot = Resolve-Path -Path (Join-Path $root $GodotExe)
$userDir = Join-Path $resolvedRoot ".godot_user"

New-Item -ItemType Directory -Force -Path $userDir | Out-Null

& $resolvedGodot `
    --headless `
    --log-file ".godot_user/godot-tests.log" `
    --path $resolvedRoot `
    -s "tests/run_tests.gd"

exit $LASTEXITCODE
