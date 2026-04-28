# Novella

Novella is a Godot 4 visual novel / GalGame plugin. The current release candidate is `1.0.0-rc.2`, with Godot 4.6 as the primary development runtime and Godot 4.3+ as the compatibility target for the Godot 4 line.

Novella is implemented in GDScript so projects can install, inspect, extend, and package it like a normal Godot addon. Godot engine binaries, export templates, editor caches, local requirement documents, local progress documents, and generated packages are intentionally excluded from version control.

## English Guide

### 1. Requirements

- Godot 4.6 is recommended for development and testing.
- Godot 4.3, 4.4, and 4.5 are compatibility targets, but must still be verified with those local runtimes before claiming full matrix coverage.
- Git is required if you want to use the release validation and package scripts.
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

The repository includes a fuller example at `examples/scripts/v1_0_showcase.nvs`.

### 4. Run A Script From GDScript

If the `Novella` autoload is enabled, you can load and run a script with a small scene script:

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

### 7. Common Commands

Runtime and flow:

- `@var name = value`
- `@set name += value`
- `@flag set|clear|toggle|check name`
- `@if condition then action`
- `@random label_a:70 label_b:30`
- `@jump label`, `@call label`, `@return`
- `@wait seconds`

Presentation:

- `@mode adv|nvl`
- `@bg id transition:dissolve time:1.0`
- `@char id outfit emotion pos:left enter:fade`
- `@char_move id pos:right time:0.5`
- `@char_emotion id happy`
- `@shake intensity:0.4 duration:0.2`
- `@camera pos:10,20 zoom:1.2 time:0.5`
- `@camera_reset`
- `@play_music id fade:1.0`
- `@play_se id`
- `@play_voice id wait:true`
- `@stop_music`, `@stop_voice`

Interaction and state:

- `@save slot`
- `@load slot`
- `@quick_save`
- `@quick_load`
- `@auto on delay:0.5`
- `@skip read|all|off`
- `@rollback`
- `@quick_menu show|hide`
- `@backlog_clear`

Meta systems:

- `@locale en`
- `@translation en key text:"Translated text"`
- `@gallery unlock id type:cg title:Title asset:res://path.png`
- `@replay unlock id label:start title:Intro`
- `@achievement register id title:Title target:3`
- `@achievement progress id amount:1`
- `@achievement unlock id title:Title`

### 8. Localization CSV Workflow

`NovellaLocalizationManager` can export and import translation catalogs as CSV strings.

```gdscript
var csv := Novella.localization_manager.export_csv(&"en")
Novella.localization_manager.import_csv(&"ja", "key,text\nline.hello,\"こんにちは {player}.\"\n", true)
```

CSV columns are `key,text`. Quoted fields and escaped quotes are supported.

### 9. Editor Tools

After enabling the plugin, Godot shows a `Novella` editor dock. The current dock can:

- Analyze `.nvs` files.
- Build a script outline.
- Build a timeline model.
- Report diagnostics such as missing labels and unknown commands.
- Provide starter script templates.
- Index likely character, background, audio, script, and UI assets.

The visual editor is still a foundation layer, not a complete drag-and-drop node editor.

### 10. Runtime Managers

The `Novella` autoload exposes the main runtime services:

- `Novella.variables`
- `Novella.commands`
- `Novella.parser`
- `Novella.vm`
- `Novella.printer_manager`
- `Novella.choice_manager`
- `Novella.save_manager`
- `Novella.rollback_manager`
- `Novella.backlog_manager`
- `Novella.localization_manager`
- `Novella.gallery_manager`
- `Novella.achievement_manager`

You can register custom commands:

```gdscript
func _ready() -> void:
	Novella.register_command(&"screen_tint", Callable(self, "_screen_tint"))

func _screen_tint(raw_arguments: String, context: Dictionary) -> Dictionary:
	return {"ok": true, "raw": raw_arguments}
```

### 11. Run Tests

Use the wrapper script so Godot writes local data inside ignored folders:

```powershell
.\scripts\test-godot.ps1
```

To use a different Godot executable:

```powershell
.\scripts\test-godot.ps1 -GodotExe "C:\Path\To\Godot_v4.6-stable_win64_console.exe"
```

### 12. Validate And Package

Run release validation:

```powershell
.\scripts\validate-release.ps1
```

Create a package in the ignored `dist/` directory:

```powershell
.\scripts\package-addon.ps1
```

The package script archives only tracked source, examples, tests, scripts, docs, `README.md`, `LICENSE`, and `project.godot`.

### 13. Repository Hygiene

Do not commit:

- Godot engine executables.
- Godot export templates.
- `.godot/` or `.godot_user/`.
- Build output, exported games, logs, temporary files, or `dist/`.
- Local requirement documents or local progress documents.

Commit source code, addon files, examples, tests, public docs, and small placeholder assets only. Use Git LFS later if large art/audio assets become necessary.

### 14. Current Status

Implemented:

- v0.1 runtime core: lexer, parser, AST, VM, variables, command registry, and basic flow commands.
- v0.2 presentation core: typewriter timing, rich text conversion, ADV/NVL printer state, character/background/effect/audio/camera managers, and presentation commands.
- v0.3 interaction and state: choices, save/load, quick save/load, autosave, rollback, skip, auto, backlog, quick menu, and basic UI scenes.
- v0.4 editor foundation: dock, outline, timeline, diagnostics, templates, and asset index.
- v0.5 meta systems: localization, gallery, replay, achievements, meta commands, and basic meta UI scenes.
- v1.0 RC.1 hardening: release validation, package script, GitHub Actions tracked-file check, showcase script, while/break/continue, inline commands, conditional/random commands, localization CSV import/export, and version-aligned save payloads.
- v1.0 RC.2 save UI foundation: paged save slot summaries, a reusable save/load panel scene, overwrite/delete confirmation flow, and headless UI tests.

Still pending for a full commercial-grade v1.0:

- Full visual drag-and-drop authoring.
- Richer production UI for settings, gallery, achievements, and final save/load styling.
- More complete scene presentation/rendering integration.
- Asset Library submission assets.
- Verified Godot 4.3, 4.4, and 4.5 test matrix.

## 中文教程

### 1. 环境要求

- 推荐使用 Godot 4.6 进行开发和测试。
- 兼容目标是 Godot 4.3、4.4、4.5、4.6+ 的 Godot 4 系列，但 4.3 到 4.5 还需要安装对应运行时后再做矩阵验证。
- 如果要使用发布校验和打包脚本，需要安装 Git。
- 仓库内的辅助脚本使用 PowerShell。

### 2. 安装插件

你可以直接把本仓库当作 Godot 项目打开，也可以把插件复制到其他 Godot 4 项目中。

用于新项目时：

1. 把 `addons/novella/` 复制到你的 Godot 项目。
2. 打开 Godot 项目。
3. 在 `Project > Project Settings > Plugins` 中启用 `Novella`。
4. 添加名为 `Novella` 的 Autoload，路径指向 `res://addons/novella/novella.gd`。

本仓库的 `project.godot` 已经配置好了插件和 Autoload，所以开发本插件时可以直接打开。

### 3. 创建脚本

Novella 剧本使用 `.nvs` 扩展名。你可以把剧本放在项目内任意位置，例如 `res://story/chapter_01.nvs`。

```text
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

启用 `Novella` Autoload 后，可以在场景脚本中这样运行：

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
- `@random label_a:70 label_b:30`
- `@jump label`、`@call label`、`@return`
- `@wait seconds`

表现层：

- `@mode adv|nvl`
- `@bg id transition:dissolve time:1.0`
- `@char id outfit emotion pos:left enter:fade`
- `@char_move id pos:right time:0.5`
- `@char_emotion id happy`
- `@shake intensity:0.4 duration:0.2`
- `@camera pos:10,20 zoom:1.2 time:0.5`
- `@camera_reset`
- `@play_music id fade:1.0`
- `@play_se id`
- `@play_voice id wait:true`
- `@stop_music`、`@stop_voice`

交互和状态：

- `@save slot`
- `@load slot`
- `@quick_save`
- `@quick_load`
- `@auto on delay:0.5`
- `@skip read|all|off`
- `@rollback`
- `@quick_menu show|hide`
- `@backlog_clear`

元系统：

- `@locale en`
- `@translation en key text:"Translated text"`
- `@gallery unlock id type:cg title:Title asset:res://path.png`
- `@replay unlock id label:start title:Intro`
- `@achievement register id title:Title target:3`
- `@achievement progress id amount:1`
- `@achievement unlock id title:Title`

### 8. 本地化 CSV 工作流

`NovellaLocalizationManager` 支持把翻译表导出/导入为 CSV 字符串。

```gdscript
var csv := Novella.localization_manager.export_csv(&"en")
Novella.localization_manager.import_csv(&"ja", "key,text\nline.hello,\"こんにちは {player}.\"\n", true)
```

CSV 列为 `key,text`。已支持带引号字段和转义引号。

### 9. 编辑器工具

启用插件后，Godot 编辑器会出现 `Novella` dock。当前 dock 可以：

- 分析 `.nvs` 文件。
- 生成剧本 outline。
- 生成 timeline 模型。
- 报告缺失 label、未知命令等诊断信息。
- 提供入门剧本模板。
- 索引可能的角色、背景、音频、剧本和 UI 资源。

当前编辑器工具仍是基础层，还不是完整的拖拽式节点编辑器。

### 10. 运行时管理器

`Novella` Autoload 暴露了主要运行时服务：

- `Novella.variables`
- `Novella.commands`
- `Novella.parser`
- `Novella.vm`
- `Novella.printer_manager`
- `Novella.choice_manager`
- `Novella.save_manager`
- `Novella.rollback_manager`
- `Novella.backlog_manager`
- `Novella.localization_manager`
- `Novella.gallery_manager`
- `Novella.achievement_manager`

可以注册自定义命令：

```gdscript
func _ready() -> void:
	Novella.register_command(&"screen_tint", Callable(self, "_screen_tint"))

func _screen_tint(raw_arguments: String, context: Dictionary) -> Dictionary:
	return {"ok": true, "raw": raw_arguments}
```

### 11. 运行测试

使用包装脚本运行测试，Godot 的本地数据会写到已忽略的目录：

```powershell
.\scripts\test-godot.ps1
```

如果要指定另一个 Godot 可执行文件：

```powershell
.\scripts\test-godot.ps1 -GodotExe "C:\Path\To\Godot_v4.6-stable_win64_console.exe"
```

### 12. 发布校验和打包

运行发布校验：

```powershell
.\scripts\validate-release.ps1
```

在已忽略的 `dist/` 目录生成插件包：

```powershell
.\scripts\package-addon.ps1
```

打包脚本只会归档已跟踪的源码、示例、测试、脚本、文档、`README.md`、`LICENSE` 和 `project.godot`。

### 13. 仓库管理注意事项

不要提交：

- Godot 引擎可执行文件。
- Godot 导出模板。
- `.godot/` 或 `.godot_user/`。
- 构建产物、导出游戏、日志、临时文件或 `dist/`。
- 本地需求文档或本地进度文档。

可以提交源码、插件文件、示例、测试、公开文档和小型占位资源。如果后续需要大型图片或音频资源，再考虑 Git LFS。

### 14. 当前完成情况

已完成：

- v0.1 运行时核心：Lexer、Parser、AST、VM、变量、命令注册和基础流程命令。
- v0.2 表现层核心：打字机、富文本、ADV/NVL printer 状态、角色/背景/特效/音频/镜头管理器和表现层命令。
- v0.3 交互与状态：选项、存档/读档、快速存档/读档、自动存档、回滚、跳过、自动播放、backlog、quick menu 和基础 UI 场景。
- v0.4 编辑器基础：dock、outline、timeline、diagnostics、模板和资源索引。
- v0.5 元系统：本地化、画廊、回放、成就、元命令和基础元系统 UI。
- v1.0 RC.1 加固：发布校验、打包脚本、GitHub Actions 跟踪文件检查、showcase 剧本、while/break/continue、行内命令、条件/随机命令、本地化 CSV 导入导出、存档版本对齐。
- v1.0 RC.2 存档 UI 基础：分页存档槽摘要、可复用存档/读档面板场景、覆盖/删除确认流程和 headless UI 测试。

距离完整商业级 v1.0 仍待完成：

- 完整拖拽式可视化编辑器。
- 更完整的设置、画廊、成就和最终存档/读档样式。
- 更完整的场景表现和渲染集成。
- Godot Asset Library 发布素材。
- Godot 4.3、4.4、4.5 的实机测试矩阵。

## License

Novella is released under the MIT License. See [LICENSE](LICENSE).
