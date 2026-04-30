param(
    [string]$GodotExe = "",
    [switch]$SkipGodotTests
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$requiredFiles = @(
    "README.md",
    "LICENSE",
    "project.godot",
    "addons/novella/plugin.cfg",
    "addons/novella/novella.gd",
    "addons/novella/novella_editor_plugin.gd",
    "addons/novella/core/constants.gd",
    "addons/novella/debug/developer_tools.gd",
    "addons/novella/debug/flow_graph_builder.gd",
    "addons/novella/editor/production_workflow.gd",
    "addons/novella/editor/script_language_service.gd",
    "addons/novella/editor/timeline_editor_model.gd",
    "addons/novella/performance/on_demand_asset_loader.gd",
    "addons/novella/editor/ui/timeline_editor_panel.tscn",
    "addons/novella/editor/ui/timeline_editor_panel.gd",
    "addons/novella/release/compatibility_matrix.gd",
    "addons/novella/release/release_manifest.gd",
    "addons/novella/release/release_validator.gd",
    "addons/novella/presentation/ui/runtime_player.tscn",
    "addons/novella/presentation/ui/runtime_player.gd",
    "addons/novella/presentation/ui/runtime_stage.tscn",
    "addons/novella/presentation/ui/runtime_stage.gd",
    "addons/novella/script/script_migration.gd",
    "addons/novella/state/save_manager.gd",
    "addons/novella/state/settings_manager.gd",
    "addons/novella/state/ui/save_load_panel.tscn",
    "addons/novella/state/ui/save_load_panel_view.gd",
    "addons/novella/state/ui/settings_panel.tscn",
    "addons/novella/state/ui/settings_panel_view.gd",
    "docs/api.md",
    "docs/commands.md",
    "docs/compatibility.md",
    "docs/development.md",
    "docs/release.md",
    "docs/tutorial_zh.md",
    "docs/v1.0-alpha.md",
    "docs/v1.0-rc.1.md",
    "docs/v1.0-rc.2.md",
    "docs/v1.0-rc.3.md",
    "docs/v1.0-rc.4.md",
    "docs/v1.0-rc.5.md",
    "docs/v1.0-rc.6.md",
    "docs/v1.0.0.md",
    "docs/v1.0.1.md",
    "docs/v1.1.0.md",
    "docs/v1.2.0.md",
    "docs/v1.3.0.md",
    "examples/scripts/v1_0_showcase.nvs",
    ".github/workflows/release-check.yml",
    "scripts/test-godot.ps1",
    "scripts/package-addon.ps1",
    "tests/run_tests.gd"
)

$trackedFiles = git ls-files

foreach ($required in $requiredFiles) {
    if ($trackedFiles -notcontains $required) {
        throw "Required release file is not tracked: $required"
    }
}

$forbiddenPatterns = @(
    '^GodotEngine/',
    '^\.godot/',
    '^\.godot_user/',
    '^export_templates/',
    '^templates/',
    '^build/',
    '^dist/',
    '^exports/',
    '^\.mono/',
    '^\.vs/',
    '^Novella_',
    '_requirements',
    '_progress',
    '_prd',
    '\.tmp$',
    '\.log$',
    '\.pck$',
    '\.apk$',
    '\.aab$',
    '\.ipa$'
)

foreach ($file in $trackedFiles) {
    foreach ($pattern in $forbiddenPatterns) {
        if ($file -cmatch $pattern) {
            throw "Forbidden release path is tracked: $file"
        }
    }
}

$pluginVersion = (Select-String -Path "addons/novella/plugin.cfg" -Pattern '^version="(.+)"$').Matches.Groups[1].Value
$constantVersion = (Select-String -Path "addons/novella/core/constants.gd" -Pattern '^const VERSION := "(.+)"$').Matches.Groups[1].Value
if ($pluginVersion -ne $constantVersion) {
    throw "Version mismatch: plugin.cfg=$pluginVersion constants.gd=$constantVersion"
}

if ($constantVersion -notmatch '^1\.') {
    throw "Expected a v1 release version. Found $constantVersion"
}

if (-not $SkipGodotTests) {
    $testArgs = @()
    if (-not [string]::IsNullOrWhiteSpace($GodotExe)) {
        $testArgs += "-GodotExe"
        $testArgs += $GodotExe
    } elseif (-not [string]::IsNullOrWhiteSpace($env:GODOT_EXE)) {
        $testArgs += "-GodotExe"
        $testArgs += $env:GODOT_EXE
    }
    & "$PSScriptRoot\test-godot.ps1" @testArgs
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
}

Write-Host "Novella release validation passed for $constantVersion."
