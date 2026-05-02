# Novella

Novella is a Godot 4 visual novel / GalGame plugin. The current stable release is `1.7.0`. Godot 4.6 is the primary development and validation runtime, and Godot 4.3+ is the compatibility target for the Godot 4 line.

Novella is implemented in GDScript so projects can install, inspect, extend, and package it like a normal Godot addon. Godot also supports C++ / GDExtension plugins, but Novella keeps the 1.0 runtime script-first for portability, editor integration, and easier community contribution. Native modules can be added later behind the same public APIs if profiling shows a real bottleneck.

Godot engine binaries, export templates, editor caches, generated packages, logs, local requirement documents, and local progress documents are intentionally excluded from version control. Novella is released under the MIT License.

Detailed Chinese step-by-step tutorial: [`docs/tutorial_zh.md`](docs/tutorial_zh.md).

## English Guide

### 1. Requirements

- Godot 4.6 is recommended for development and testing.
- Godot 4.3, 4.4, and 4.5 are compatibility targets, pending local matrix verification with those runtimes.
- Godot 3.x is not supported by Novella 1.0.
- Git is required for release validation and packaging scripts.
- PowerShell is used by the included Windows helper scripts.

### 2. Install The Addon

Use this repository directly as a Godot project, or copy the addon into another Godot 4 project.

For a new project:

1. Copy `addons/novella/` into your Godot project.
2. Open the project in Godot.
3. Enable `Novella` in `Project > Project Settings > Plugins`.
4. Add an autoload named `Novella` that points to `res://addons/novella/novella.gd`.

This repository already includes the plugin and autoload in `project.godot`, so you can open it directly for development.

### 3. Create A Script

Novella scripts use the `.nvs` extension. Save story scripts anywhere inside your project, for example `res://story/chapter_01.nvs`.

```text
# novella_version: 1.0
@var player = "Yue"
@var affinity = 0

label start:
    @locale en
    @translation en line.hello text:"Hello {player}. Welcome to Novella."
    @bg school_day transition:dissolve time:0.6
    @char Ryone uniform happy pos:left enter:fade
    @play_music main_theme fade:1.0
    Ryone: $line.hello
    @set affinity += 5
    menu:
        "Stay with Ryone" if affinity >= 5:
            Ryone: I am glad you stayed.
        "Leave":
            jump ending
    @mode nvl
    The day slowly turns into a memory.
    @mode adv
    jump ending

label ending:
    @stop_music fade:0.5
    Ryone: See you next time.
```

A fuller showcase script is available at `examples/scripts/v1_0_showcase.nvs`.

### 4. Run A Script From GDScript

```gdscript
extends Node

func _ready() -> void:
	var source := FileAccess.get_file_as_string("res://story/chapter_01.nvs")
	var transcript := Novella.run_script(source, "res://story/chapter_01.nvs")
	for entry in transcript:
		print(entry)
```

For custom UI integration, connect to VM signals:

```gdscript
func _ready() -> void:
	Novella.vm.dialogue_requested.connect(_on_dialogue_requested)
	Novella.vm.narration_requested.connect(_on_narration_requested)
	Novella.vm.choice_requested.connect(_on_choice_requested)

func _on_dialogue_requested(speaker: String, text: String, line: int) -> void:
	print("%s: %s" % [speaker, text])

func _on_narration_requested(text: String, line: int) -> void:
	print(text)

func _on_choice_requested(choices: Array, selected_index: int, line: int) -> void:
	print(choices)
```

For click-driven menu UI, disable automatic menu selection and resolve the pending choice later:

```gdscript
func _ready() -> void:
	Novella.vm.auto_select_choices = false
	Novella.vm.choice_waiting.connect(_on_choice_waiting)
	Novella.run_script(source, "res://story/chapter_01.nvs")

func _on_choice_waiting(choices: Array, _line: int) -> void:
	print(choices)

func _on_choice_button_pressed(choice_index: int) -> void:
	Novella.vm.choose(choice_index)
```

For the default playable flow, instance `res://addons/novella/presentation/ui/runtime_player.tscn`, bind the runtime, and start a script:

```gdscript
@onready var player = $RuntimePlayer

func _ready() -> void:
	player.bind_runtime(Novella)
	var source := FileAccess.get_file_as_string("res://story/chapter_01.nvs")
	player.start_script(source, "res://story/chapter_01.nvs")
```

### 5. Script Syntax

Dialogue uses `Speaker: Text`.

```text
Ryone: Welcome back.
```

Narration is plain text without a speaker prefix.

```text
The classroom is quiet.
```

Labels, jumps, calls, and returns control story flow.

```text
label start:
    call intro
    jump ending

label intro:
    Ryone: This is a subroutine.
    return

label ending:
    Ryone: Finished.
```

Menus define choices. Each choice may include an `if` condition.

```text
menu:
    "Open the door" if has_key:
        jump door_path
    "Wait":
        Ryone: We wait a little longer.
```

Blocks support `if`, `elif`, `else`, `endif`, `while`, `endwhile`, `break`, and `continue`.

```text
while affinity < 10:
    @set affinity += 1
    @if affinity == 5 then continue
    Ryone: Affinity is {affinity}.
    @if affinity >= 8 then break
endwhile
```

Inline commands can run after dialogue or narration on the same line.

```text
Ryone: This line also changes a variable. @set affinity += 1
The wind rises. @shake intensity:0.3 duration:0.2
```

### 6. Variables And Expressions

Use `@var` to declare variables and `@set` to change them.

```text
@var score = 0
@var met_ryone = false
@set score += 5
@set met_ryone = true
```

Text interpolation uses `{name}`.

```text
Ryone: Your score is {score}.
```

Expressions are available in menu conditions, `if` blocks, `while` loops, `@set ... if ...`, and `@if`.

```text
if score >= 10 and met_ryone:
    Ryone: You unlocked this scene.
else:
    Ryone: Not yet.
endif
```

### 7. Command Overview

Runtime and flow:

- `@var name = value`
- `@set name += value`
- `@flag set|clear|toggle|check name`
- `@if condition then action`
- `@random label_a:70 label_b:30 seed:1`
- `@jump label`, `@call label`, `@return`
- `@wait seconds`

Presentation:

- `@mode adv|nvl`
- `@bg id transition:dissolve time:1.0`
- `@char id outfit emotion pos:left enter:fade`
- `@char_move id pos:right time:0.5`
- `@char_emotion id happy`
- `@char_remove id`
- `@shake intensity:0.4 duration:0.2`
- `@flash color:#ffffff duration:0.2`
- `@camera pos:10,20 zoom:1.2 time:0.5`
- `@camera_reset`
- `@play_music id fade:1.0`
- `@play_se id`
- `@play_voice id wait:true`
- `@stop_music`, `@stop_voice`

Interaction and state:

- `@save slot`, `@load slot`
- `@quick_save`, `@quick_load`
- `@auto_save trigger`
- `@settings set text_speed:40 auto_delay:1.5 fullscreen:false`
- `@config set text_speed:40`
- `@rollback`, `@prevent_rollback`, `@allow_rollback`
- `@skip read|all|off`
- `@auto on|off delay:1.5`
- `@quick_menu show|hide|toggle`
- `@backlog_clear`
- `@choice_timeout seconds:5 target:timeout_label`
- `@input variable prompt:"Name"`

Meta systems:

- `@locale en`
- `@translation en key text:"Translated text"`
- `@tr_var player Yue`
- `@gallery unlock id type:cg title:Title asset:res://path.png`
- `@replay unlock id label:start title:Intro`
- `@achievement register id title:Title target:3`
- `@achievement progress id amount:1`
- `@achievement unlock id title:Title`
- `@meta_check achievement:id`

See `docs/commands.md` for the command reference.

### 8. Runtime Managers

The `Novella` autoload exposes the main runtime services:

- `Novella.variables`
- `Novella.commands`
- `Novella.parser`
- `Novella.vm`
- `Novella.printer_manager`
- `Novella.character_manager`
- `Novella.background_manager`
- `Novella.effect_manager`
- `Novella.audio_manager`
- `Novella.camera_director`
- `Novella.choice_manager`
- `Novella.save_manager`
- `Novella.settings_manager`
- `Novella.rollback_manager`
- `Novella.skip_manager`
- `Novella.auto_manager`
- `Novella.backlog_manager`
- `Novella.quick_menu_manager`
- `Novella.localization_manager`
- `Novella.gallery_manager`
- `Novella.achievement_manager`
- `Novella.script_migration`
- `Novella.compatibility_matrix`

You can register custom commands:

```gdscript
func _ready() -> void:
	Novella.register_command(&"screen_tint", Callable(self, "_screen_tint"))

func _screen_tint(raw_arguments: String, context: Dictionary) -> Dictionary:
	return {"ok": true, "raw": raw_arguments}
```

### 9. Localization CSV Workflow

`NovellaLocalizationManager` can export and import translation catalogs as CSV strings.

```gdscript
var csv := Novella.localization_manager.export_csv(&"en")
Novella.localization_manager.import_csv(&"ja", "key,text\nline.hello,\"こんにちは {player}.\"\n", true)
var template := Novella.localization_manager.export_template([&"line.hello"], &"ja")
var coverage := Novella.localization_manager.coverage_report([&"line.hello"], [&"ja"])
```

CSV columns are `key,text`. Quoted fields and escaped quotes are supported.

### 10. Editor Tools

After enabling the plugin, Godot shows a `Novella` editor dock. The current dock can:

- Analyze `.nvs` files.
- Build a script outline.
- Build a timeline model.
- Report diagnostics such as missing labels and unknown commands.
- Provide starter script templates.
- Index likely character, background, audio, script, and UI assets.
- Open the visual timeline panel foundation.

The visual editor in 1.4 is still model-first, but it now supports production workflow helpers: live preview sessions, timeline copy/paste/collapse styling, nested menu/branch export, asset reference validation, resource workbench cards, UI skin defaults, confirmation requests, toast state, localization template export/import, localized script preview, language-service reports, route flow graphs, and on-demand asset load plans.

```gdscript
var workflow := NovellaProductionWorkflow.new()
var analysis := workflow.analyze_script(source, "chapter_01.nvs", known_commands, asset_paths)
var csv := workflow.export_localization_template([{"source": source, "file_path": "chapter_01.nvs"}], &"zh")
var preview := workflow.preview_localized_source(source, &"zh", "chapter_01.nvs")
var language := workflow.language_report(source, "chapter_01.nvs", known_commands, asset_paths)
var route_graph := workflow.build_flow_graph(source, "chapter_01.nvs")
var load_plan := workflow.build_asset_load_plan(source, asset_paths, "chapter_01.nvs")
var preview_session := workflow.create_preview_session(source, "chapter_01.nvs")
var preview_state := preview_session.preview_state()
var resource_report := workflow.resource_report(asset_paths)
var ui_defaults := workflow.ui_production_defaults()
```

Developer tooling primitives are available for editor panels and debug overlays:

```gdscript
var tools := NovellaDeveloperTools.new()
var variables := tools.variable_watch(Novella.variable_manager)
tools.set_variable(Novella.variable_manager, &"affinity", 10)
var trace := tools.trace_vm(vm)
var console_result := tools.execute_console("@set affinity += 1", registry, {"variables": Novella.variable_manager})
var perf := tools.performance_snapshot(get_tree().root)
```

### 11. Script Migration

Older `.nvs` scripts can be normalized with the migration helper.

```gdscript
var migration := Novella.script_migration.migrate(old_source)
if migration["ok"]:
	var updated_source: String = migration["source"]
```

The migrator adds `# novella_version: 1.0` and rewrites known aliases such as `@language` to `@locale` and `@achieve` to `@achievement`.

### 12. Compatibility

Use the compatibility helper to inspect the current runtime:

```gdscript
var status := Novella.compatibility_matrix.runtime_status()
print(status["message"])
```

Compatibility status:

- Godot 4.6: primary verified runtime.
- Godot 4.3, 4.4, and 4.5: compatibility targets pending local runtime matrix verification.
- Godot 4.7+: expected future-compatible unless Godot changes a required API.
- Godot 3.x: unsupported by Novella 1.0.

### 13. Run Tests

Use the wrapper script so Godot writes local data inside ignored folders:

```powershell
.\scripts\test-godot.ps1
```

To use a different Godot executable:

```powershell
.\scripts\test-godot.ps1 -GodotExe "C:\Path\To\Godot_v4.6-stable_win64_console.exe"
```

### 14. Validate And Package

Run release validation:

```powershell
.\scripts\validate-release.ps1
```

Create a package in the ignored `dist/` directory:

```powershell
.\scripts\package-addon.ps1
```

The package script archives only tracked source, examples, tests, scripts, docs, `README.md`, `LICENSE`, and `project.godot`.

### 15. Repository Hygiene

Do not commit:

- Godot engine executables.
- Godot export templates.
- `.godot/` or `.godot_user/`.
- Build output, exported games, logs, temporary files, or `dist/`.
- Local requirement documents or local progress documents.

Commit source code, addon files, examples, tests, public docs, and small placeholder assets only. Use Git LFS later if large art or audio assets become necessary.

### 16. Release Status

Implemented in `1.7.0`:

- v0.1 runtime core: lexer, parser, AST, VM, variables, command registry, and basic flow commands.
- v0.2 presentation core: typewriter timing, rich text conversion, ADV/NVL printer state, character/background/effect/audio/camera managers, and presentation commands.
- v0.3 interaction and state: choices, save/load, quick save/load, autosave, rollback, skip, auto, backlog, quick menu, and basic UI scenes.
- v0.4 editor foundation: dock, outline, timeline, diagnostics, templates, and asset index.
- v0.5 meta systems: localization, gallery, replay, achievements, meta commands, and basic meta UI scenes.
- v1.0 release line: control-flow hardening, release validation, package script, GitHub Actions release check, showcase script, save/settings UI foundation, runtime stage, visual timeline editor foundation, migration helper, compatibility matrix, and public documentation.
- v1.0.1 interaction polish: VM pending-choice mode for click-driven UI, `choice_waiting`, `get_pending_choice()`, and `choose(index)`.
- v1.1.0 playable runtime: VM text advance mode, `RuntimePlayer` scene, choice buttons, quick menu dispatch, and mouse/keyboard advance input.
- v1.2.0 production workflow: `NovellaProductionWorkflow`, richer asset indexing, reference validation, timeline search/replace/filtering, nested timeline export, localization templates, coverage reports, and localized script preview.
- v1.3.0 full-PRD tooling baseline: script language service, developer tools, command console, VM tracing, route flow graph builder, route unlock overlays, performance snapshots, and on-demand asset load plans.
- v1.4.0 editor/assets/UI production tools: editor preview sessions, production timeline copy/paste/collapse styling, resource workbench, character/background resource assembly, UI skin resources, quick menu ordering/confirmation metadata, toast state, and hide-dialogue behavior.
- v1.5.0 presentation/audio/save completion: scene render plans, camera animation queues, shader/effect metadata, audio stream validation, automatic voice association, backlog voice replay, save import/export, optional encrypted save payloads, arbitrary rollback targets, and persistent read-state export/import.
- v1.6.0 meta/debug/performance/input completion: typography and localized asset overrides, on-demand language packs, plural forms, split/merge localization helpers, music room, route map data, achievement notifications, debug panel models, command console UI data, node/performance/flow graph panel data, windowed on-demand loading, memory/FPS baselines, touch input, and gamepad input.
- v1.7.0 docs/examples/compatibility/audit completion: full source-only VN example, bilingual API and command doc refresh, tutorial refresh, compatibility report APIs, public PRD audit, and targeted audit tests.

Remaining verification:

- Godot 4.3, 4.4, and 4.5 need local runtime matrix verification before they can be marked as fully tested.

## 中文教程

### 1. 环境要求

- 推荐使用 Godot 4.6 进行开发和测试。
- Godot 4.3、4.4、4.5 是兼容目标，但仍需要安装对应版本后跑完整矩阵验证。
- Novella 1.0 不支持 Godot 3.x。
- 如果要使用发布校验和打包脚本，需要安装 Git。
- 仓库内提供的 Windows 辅助脚本使用 PowerShell。

### 2. 安装插件

你可以直接把这个仓库作为 Godot 项目打开，也可以把插件复制到其他 Godot 4 项目里。

用于新项目时：

1. 把 `addons/novella/` 复制到你的 Godot 项目。
2. 打开 Godot 项目。
3. 在 `Project > Project Settings > Plugins` 启用 `Novella`。
4. 添加名为 `Novella` 的 Autoload，路径指向 `res://addons/novella/novella.gd`。

本仓库的 `project.godot` 已经配置好插件和 Autoload，所以开发本插件时可以直接打开。

### 3. 创建脚本

Novella 剧本使用 `.nvs` 扩展名。你可以把剧本放在项目内任意位置，例如 `res://story/chapter_01.nvs`。

```text
# novella_version: 1.0
@var player = "Yue"
@var affinity = 0

label start:
    @locale en
    @translation en line.hello text:"Hello {player}. Welcome to Novella."
    @bg school_day transition:dissolve time:0.6
    @char Ryone uniform happy pos:left enter:fade
    @play_music main_theme fade:1.0
    Ryone: $line.hello
    @set affinity += 5
    menu:
        "Stay with Ryone" if affinity >= 5:
            Ryone: I am glad you stayed.
        "Leave":
            jump ending
    @mode nvl
    The day slowly turns into a memory.
    @mode adv
    jump ending

label ending:
    @stop_music fade:0.5
    Ryone: See you next time.
```

更完整的示例在 `examples/scripts/v1_0_showcase.nvs`。

### 4. 在 GDScript 中运行剧本

```gdscript
extends Node

func _ready() -> void:
	var source := FileAccess.get_file_as_string("res://story/chapter_01.nvs")
	var transcript := Novella.run_script(source, "res://story/chapter_01.nvs")
	for entry in transcript:
		print(entry)
```

如果要接入自己的 UI，可以监听 VM 信号：

```gdscript
func _ready() -> void:
	Novella.vm.dialogue_requested.connect(_on_dialogue_requested)
	Novella.vm.narration_requested.connect(_on_narration_requested)
	Novella.vm.choice_requested.connect(_on_choice_requested)

func _on_dialogue_requested(speaker: String, text: String, line: int) -> void:
	print("%s: %s" % [speaker, text])

func _on_narration_requested(text: String, line: int) -> void:
	print(text)

func _on_choice_requested(choices: Array, selected_index: int, line: int) -> void:
	print(choices)
```

### 5. 剧本语法

对话格式是 `角色名: 文本`。

```text
Ryone: Welcome back.
```

没有角色名前缀的普通文本会作为旁白。

```text
The classroom is quiet.
```

使用 label、jump、call、return 控制流程。

```text
label start:
    call intro
    jump ending

label intro:
    Ryone: This is a subroutine.
    return

label ending:
    Ryone: Finished.
```

菜单使用 `menu:`，每个选项可以带 `if` 条件。

```text
menu:
    "Open the door" if has_key:
        jump door_path
    "Wait":
        Ryone: We wait a little longer.
```

代码块支持 `if`、`elif`、`else`、`endif`、`while`、`endwhile`、`break`、`continue`。

```text
while affinity < 10:
    @set affinity += 1
    @if affinity == 5 then continue
    Ryone: Affinity is {affinity}.
    @if affinity >= 8 then break
endwhile
```

对话或旁白行后面可以接行内命令。

```text
Ryone: This line also changes a variable. @set affinity += 1
The wind rises. @shake intensity:0.3 duration:0.2
```

### 6. 变量和表达式

使用 `@var` 声明变量，使用 `@set` 修改变量。

```text
@var score = 0
@var met_ryone = false
@set score += 5
@set met_ryone = true
```

文本中可以用 `{name}` 插入变量。

```text
Ryone: Your score is {score}.
```

表达式可用于菜单条件、`if` 块、`while` 循环、`@set ... if ...` 和 `@if`。

```text
if score >= 10 and met_ryone:
    Ryone: You unlocked this scene.
else:
    Ryone: Not yet.
endif
```

### 7. 常用命令

运行时和流程：

- `@var name = value`
- `@set name += value`
- `@flag set|clear|toggle|check name`
- `@if condition then action`
- `@random label_a:70 label_b:30 seed:1`
- `@jump label`、`@call label`、`@return`
- `@wait seconds`

表现层：

- `@mode adv|nvl`
- `@bg id transition:dissolve time:1.0`
- `@char id outfit emotion pos:left enter:fade`
- `@char_move id pos:right time:0.5`
- `@char_emotion id happy`
- `@char_remove id`
- `@shake intensity:0.4 duration:0.2`
- `@flash color:#ffffff duration:0.2`
- `@camera pos:10,20 zoom:1.2 time:0.5`
- `@camera_reset`
- `@play_music id fade:1.0`
- `@play_se id`
- `@play_voice id wait:true`
- `@stop_music`、`@stop_voice`

交互和状态：

- `@save slot`、`@load slot`
- `@quick_save`、`@quick_load`
- `@auto_save trigger`
- `@settings set text_speed:40 auto_delay:1.5 fullscreen:false`
- `@config set text_speed:40`
- `@rollback`、`@prevent_rollback`、`@allow_rollback`
- `@skip read|all|off`
- `@auto on|off delay:1.5`
- `@quick_menu show|hide|toggle`
- `@backlog_clear`
- `@choice_timeout seconds:5 target:timeout_label`
- `@input variable prompt:"Name"`

元系统：

- `@locale en`
- `@translation en key text:"Translated text"`
- `@tr_var player Yue`
- `@gallery unlock id type:cg title:Title asset:res://path.png`
- `@replay unlock id label:start title:Intro`
- `@achievement register id title:Title target:3`
- `@achievement progress id amount:1`
- `@achievement unlock id title:Title`
- `@meta_check achievement:id`

完整命令参考见 `docs/commands.md`。

### 8. 运行时管理器

`Novella` Autoload 暴露了主要运行时服务：

- `Novella.variables`
- `Novella.commands`
- `Novella.parser`
- `Novella.vm`
- `Novella.printer_manager`
- `Novella.character_manager`
- `Novella.background_manager`
- `Novella.effect_manager`
- `Novella.audio_manager`
- `Novella.camera_director`
- `Novella.choice_manager`
- `Novella.save_manager`
- `Novella.settings_manager`
- `Novella.rollback_manager`
- `Novella.skip_manager`
- `Novella.auto_manager`
- `Novella.backlog_manager`
- `Novella.quick_menu_manager`
- `Novella.localization_manager`
- `Novella.gallery_manager`
- `Novella.achievement_manager`
- `Novella.script_migration`
- `Novella.compatibility_matrix`

可以注册自定义命令：

```gdscript
func _ready() -> void:
	Novella.register_command(&"screen_tint", Callable(self, "_screen_tint"))

func _screen_tint(raw_arguments: String, context: Dictionary) -> Dictionary:
	return {"ok": true, "raw": raw_arguments}
```

### 9. 本地化 CSV 工作流

`NovellaLocalizationManager` 支持把翻译表导出或导入为 CSV 字符串。

```gdscript
var csv := Novella.localization_manager.export_csv(&"en")
Novella.localization_manager.import_csv(&"ja", "key,text\nline.hello,\"こんにちは {player}.\"\n", true)
```

CSV 列为 `key,text`。已支持带引号字段和转义引号。

### 10. 编辑器工具

启用插件后，Godot 编辑器会出现 `Novella` dock。当前 dock 可以：

- 分析 `.nvs` 文件。
- 生成剧本 outline。
- 生成 timeline 模型。
- 报告缺失 label、未知命令等诊断信息。
- 提供入门剧本模板。
- 索引可能的角色、背景、音频、剧本和 UI 资源。
- 打开可视化时间线面板基础功能。

1.0 的可视化编辑器仍是基础层。它可以建模、编辑、撤销、重做和序列化时间线事件，但还不是完整的生产级拖拽式节点编辑器。

### 11. 剧本迁移

旧 `.nvs` 剧本可以用迁移器规范化。

```gdscript
var migration := Novella.script_migration.migrate(old_source)
if migration["ok"]:
	var updated_source: String = migration["source"]
```

迁移器会添加 `# novella_version: 1.0`，并把已知旧别名改为新命令，例如 `@language` 改为 `@locale`，`@achieve` 改为 `@achievement`。

### 12. 兼容性

使用兼容性助手检查当前运行时：

```gdscript
var status := Novella.compatibility_matrix.runtime_status()
print(status["message"])
```

兼容状态：

- Godot 4.6：主要验证运行时。
- Godot 4.3、4.4、4.5：兼容目标，等待本地矩阵验证。
- Godot 4.7+：预期兼容，除非 Godot 改动了插件依赖的 API。
- Godot 3.x：Novella 1.0 不支持。

### 13. 运行测试

使用包装脚本运行测试，Godot 的本地数据会写入已忽略目录：

```powershell
.\scripts\test-godot.ps1
```

如果要指定另一个 Godot 可执行文件：

```powershell
.\scripts\test-godot.ps1 -GodotExe "C:\Path\To\Godot_v4.6-stable_win64_console.exe"
```

### 14. 发布校验和打包

运行发布校验：

```powershell
.\scripts\validate-release.ps1
```

在已忽略的 `dist/` 目录生成插件包：

```powershell
.\scripts\package-addon.ps1
```

打包脚本只会归档已跟踪的源码、示例、测试、脚本、文档、`README.md`、`LICENSE` 和 `project.godot`。

### 15. 仓库管理注意事项

不要提交：

- Godot 引擎可执行文件。
- Godot 导出模板。
- `.godot/` 或 `.godot_user/`。
- 构建产物、导出的游戏、日志、临时文件或 `dist/`。
- 本地需求文档或本地进度文档。

可以提交源码、插件文件、示例、测试、公开文档和小型占位资源。如果后续需要大型图片或音频资源，再考虑 Git LFS。

### 16. 发布状态

`1.7.0` 已包含：

- v0.1 运行时核心：lexer、parser、AST、VM、变量、命令注册和基础流程命令。
- v0.2 表现层核心：打字机、富文本、ADV/NVL printer 状态、角色/背景/特效/音频/镜头管理器和表现层命令。
- v0.3 交互与状态：选项、存档/读档、快速存档/读档、自动存档、回滚、跳过、自动播放、backlog、quick menu 和基础 UI 场景。
- v0.4 编辑器基础：dock、outline、timeline、diagnostics、模板和资源索引。
- v0.5 元系统：本地化、画廊、回放、成就、元命令和基础元系统 UI。
- v1.0 发布线：流程控制加固、发布校验、打包脚本、GitHub Actions 发布检查、showcase 剧本、存档/设置 UI 基础、运行时舞台、可视化时间线编辑器基础、迁移器、兼容矩阵和公开文档。
- v1.0.1 交互打磨：VM 等待选项模式，支持点击式 UI 通过 `choice_waiting`、`get_pending_choice()` 和 `choose(index)` 接入。
- v1.1.0 可玩运行时：VM 文本等待推进、`RuntimePlayer` 场景、选项按钮、quick menu 派发和鼠标/键盘推进输入。
- v1.2.0 制作工作流：`NovellaProductionWorkflow`、更完整的资源索引、引用完整性检查、时间线搜索/替换/过滤、嵌套时间线导出、本地化模板、覆盖率统计和本地化预览。
- v1.3.0 PRD 全量工具基线：脚本语言服务、开发者工具、控制台命令、VM 追踪、路线流程图、路线解锁覆盖、性能快照和按需资源加载计划。
- v1.4.0 编辑器/资源/UI 生产工具：编辑器预览会话、时间线复制/粘贴/折叠样式、资源工作台、角色/背景资源组装、UI 皮肤资源、快捷菜单排序和确认提示、toast 状态以及隐藏对话框行为。
- v1.5.0 表现/音频/存档补全：场景渲染计划、镜头动画队列、shader/特效元数据、音频流验证、自动语音绑定、backlog 语音回放、存档导入导出、可选加密存档、任意回滚目标和已读状态持久化导入导出。
- v1.6.0 元系统/调试/性能/输入补全：排版与本地化资源覆盖、按需语言包、复数形式、文本拆分合并、本地音乐室、路线图数据、成就通知、调试面板模型、命令控制台 UI 数据、节点/性能/流程图面板数据、窗口化按需加载、内存/FPS 基线、触控输入和手柄输入。
- v1.7.0 文档/示例/兼容性/审计补全：完整源码型 VN 示例、中英 API 和命令文档刷新、教程刷新、兼容性报告 API、公开 PRD 审计和审计测试。

剩余验证：

- Godot 4.3、4.4、4.5 需要安装对应本地运行时后再跑完整测试矩阵，才能标记为已完整测试。

## License

Novella is released under the MIT License. See [LICENSE](LICENSE).
