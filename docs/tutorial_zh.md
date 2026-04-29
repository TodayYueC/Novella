# Novella 1.0 详细使用教程

这篇教程按“从零开始做一个可运行 Demo”的顺序编写。完成后，你会得到一个 Godot 4 项目，能加载 `.nvs` 剧本，执行对话、旁白、菜单、变量、背景、角色、音频状态、存档、设置、本地化、成就和发布校验。

Novella 1.1.0 的主测试环境是 Godot 4.6，兼容目标是 Godot 4.3 及以上的 Godot 4.x。Godot 3.x 不在 1.0 支持范围内。

## 1. 准备环境

先准备这些工具：

- Godot 4.6，推荐使用普通标准版或 console 版。
- Git。
- PowerShell，Windows 下运行测试和打包脚本会用到。
- 一个 Godot 4 项目，或者直接使用 Novella 仓库作为项目。

注意：

- 不要把 Godot 引擎可执行文件放进仓库。
- 不要提交 `.godot/`、`.godot_user/`、`dist/`、导出模板、日志、缓存、本地需求文档或本地进度文档。
- 如果以后加入大型图片或音频资源，再考虑 Git LFS。

## 2. 安装插件

如果你直接打开 Novella 仓库：

1. 打开 Godot。
2. 选择 `Import`。
3. 选中仓库里的 `project.godot`。
4. 打开项目。
5. 确认 `Project > Project Settings > Plugins` 中 `Novella` 已启用。
6. 确认 `Project > Project Settings > Globals > Autoload` 中存在名为 `Novella` 的 autoload，路径为 `res://addons/novella/novella.gd`。

如果你要把 Novella 安装到自己的项目：

1. 把 `addons/novella/` 复制到你的 Godot 项目根目录。
2. 打开 Godot 项目。
3. 进入 `Project > Project Settings > Plugins`。
4. 启用 `Novella`。
5. 进入 `Project > Project Settings > Globals > Autoload`。
6. 添加 autoload：
   - Name: `Novella`
   - Path: `res://addons/novella/novella.gd`
7. 保存项目。

## 3. 创建目录结构

建议先建立这些目录：

```text
res://story/
res://scenes/
res://scripts/
res://art/backgrounds/
res://art/characters/
res://audio/bgm/
res://audio/se/
res://audio/voice/
```

Novella 1.0 的示例表现层会用文本标记和颜色占位展示背景、角色、镜头、音频等状态。真正项目里，你可以把这些状态接到自己的图片、动画、音频和 UI 系统上。

## 4. 编写第一份剧本

新建文件：

```text
res://story/chapter_01.nvs
```

写入下面内容：

```text
# novella_version: 1.0
@var player = "Yue"
@var affinity = 0

label start:
    @locale en
    @translation en line.hello text:"Hello {player}. Welcome to Novella."
    @translation zh line.hello text:"你好，{player}。欢迎使用 Novella。"
    @translation en choice.stay text:"Stay with Ryone"
    @translation zh choice.stay text:"留下来陪 Ryone"
    @bg school_day transition:dissolve time:0.6
    @char Ryone uniform happy pos:left enter:fade
    @play_music main_theme fade:1.0
    Ryone: $line.hello
    @set affinity += 5

    menu:
        "$choice.stay" if affinity >= 5:
            @gallery unlock cg_school type:cg title:School asset:res://art/backgrounds/school_day.png
            @achievement unlock first_memory title:FirstMemory
            Ryone: This memory has been unlocked.
        "Leave":
            jump ending

    @mode nvl
    The afternoon becomes a quiet page in the backlog.
    @nvl_clear
    @mode adv
    jump ending

label ending:
    @stop_music fade:0.5
    Ryone: Demo complete.
```

这份剧本包含：

- `@var` 声明变量。
- `@translation` 添加翻译文本。
- `@locale` 设置语言。
- `@bg` 切换背景状态。
- `@char` 显示角色状态。
- `@play_music` 和 `@stop_music` 改变音频状态。
- `menu:` 创建菜单。
- `@gallery` 解锁画廊条目。
- `@achievement` 解锁成就。
- `@mode nvl` 和 `@mode adv` 切换文本显示模式。

## 5. 先用最小脚本跑通剧本

新建场景：

```text
res://scenes/Main.tscn
```

根节点使用 `Node`，挂载脚本：

```text
res://scripts/main.gd
```

脚本内容：

```gdscript
extends Node

func _ready() -> void:
	var source := FileAccess.get_file_as_string("res://story/chapter_01.nvs")
	var transcript := Novella.run_script(source, "res://story/chapter_01.nvs")
	for entry in transcript:
		print(entry)
```

运行场景后，Godot 输出面板会打印剧本执行记录。这个步骤用于确认插件、autoload、parser、VM 和命令系统已经工作。

## 6. 使用运行时舞台显示结果

Novella 提供了一个基础运行时舞台：

```text
res://addons/novella/presentation/ui/runtime_stage.tscn
```

它能显示背景状态、角色标记、ADV/NVL 文本、屏幕效果、音频状态和镜头状态。它是 1.0 的通用演示舞台，不是最终商业 UI。你可以把它作为调试界面，也可以参考它接入自己的 UI。

创建一个 `Control` 场景作为主场景：

1. 新建 `res://scenes/Playground.tscn`。
2. 根节点使用 `Control`。
3. 把 `res://addons/novella/presentation/ui/runtime_stage.tscn` 实例化为子节点。
4. 子节点命名为 `RuntimeStage`。
5. 给根节点挂载脚本 `res://scripts/playground.gd`。

脚本内容：

```gdscript
extends Control

@onready var runtime_stage = $RuntimeStage

func _ready() -> void:
	runtime_stage.bind_managers({
		"printer_manager": Novella.printer_manager,
		"background_manager": Novella.background_manager,
		"character_manager": Novella.character_manager,
		"effect_manager": Novella.effect_manager,
		"camera_director": Novella.camera_director,
		"audio_manager": Novella.audio_manager,
	})

	var source := FileAccess.get_file_as_string("res://story/chapter_01.nvs")
	var transcript := Novella.run_script(source, "res://story/chapter_01.nvs")
	print("Story finished with %s transcript entries." % transcript.size())
```

运行 `Playground.tscn` 后，你应该能看到运行时舞台根据剧本状态变化。

## 7. 理解菜单选择

Novella 1.0.1 支持两种菜单执行方式。默认情况下 VM 会同步执行。遇到 `menu:` 时：

- 如果没有配置选择策略，会默认选择第一个可用选项。
- 如果你设置了 `Novella.vm.choice_strategy`，VM 会调用它来决定选项。

例如，总是选择第二个可用选项：

```gdscript
extends Node

func _ready() -> void:
	Novella.vm.choice_strategy = Callable(self, "_choose_second_if_possible")
	var source := FileAccess.get_file_as_string("res://story/chapter_01.nvs")
	Novella.run_script(source, "res://story/chapter_01.nvs")

func _choose_second_if_possible(_choices: Array, available: Array) -> int:
	if available.size() >= 2:
		return int(available[1])
	return int(available[0])
```

从 1.0.1 开始，也可以让 VM 停在菜单处，等你的 UI 调用 `choose()` 后再继续：

```gdscript
extends Control

var current_buttons: Array[Button] = []

func _ready() -> void:
	Novella.vm.auto_select_choices = false
	Novella.vm.choice_waiting.connect(_on_choice_waiting)
	var source := FileAccess.get_file_as_string("res://story/chapter_01.nvs")
	Novella.run_script(source, "res://story/chapter_01.nvs")

func _on_choice_waiting(choices: Array, _line: int) -> void:
	_clear_choice_buttons()
	for choice in choices:
		if not bool(choice.get("enabled", true)):
			continue
		var button := Button.new()
		button.text = str(choice["text"])
		var choice_index := int(choice["index"])
		button.pressed.connect(func(): _choose(choice_index))
		add_child(button)
		current_buttons.append(button)

func _choose(choice_index: int) -> void:
	_clear_choice_buttons()
	var result := Novella.vm.choose(choice_index)
	if not bool(result.get("ok", false)):
		push_warning(str(result))

func _clear_choice_buttons() -> void:
	for button in current_buttons:
		button.queue_free()
	current_buttons.clear()
```

如果你只想检查当前等待中的菜单，可以调用：

```gdscript
var pending := Novella.vm.get_pending_choice()
print(pending["choices"])
```

## 7.1 使用默认 RuntimePlayer

从 1.1.0 开始，推荐用 `RuntimePlayer` 快速搭建可玩的默认流程。

1. 新建一个 `Control` 场景。
2. 把 `res://addons/novella/presentation/ui/runtime_player.tscn` 实例化为子节点。
3. 子节点命名为 `RuntimePlayer`。
4. 给根节点挂载脚本。

```gdscript
extends Control

@onready var player = $RuntimePlayer

func _ready() -> void:
	player.bind_runtime(Novella)
	var source := FileAccess.get_file_as_string("res://story/chapter_01.nvs")
	player.start_script(source, "res://story/chapter_01.nvs")
```

`RuntimePlayer` 会自动：

- 绑定运行时舞台。
- 启用对话/旁白点击推进。
- 把菜单选项显示为按钮。
- 派发 quick menu 动作。
- 支持鼠标左键、Enter、Space 推进文本。

如果菜单选项后还要显示可点击推进的台词，推荐让选项 `jump` 到独立 label，再在 label 里写后续对话。

## 8. 使用变量和条件

变量用于控制剧情分支：

```text
@var score = 0
@var has_key = false

label start:
    @set score += 10
    @set has_key = true

    if score >= 10 and has_key:
        Ryone: You can open the locked door.
    else:
        Ryone: The door is still locked.
    endif
```

菜单也能使用条件：

```text
menu:
    "Open the locked door" if has_key:
        jump door_path
    "Wait":
        Ryone: We wait a little longer.
```

文本中可以使用 `{变量名}`：

```text
Ryone: Current score is {score}.
```

## 9. 使用循环、跳转和子流程

Novella 支持 `while`、`break`、`continue`：

```text
@var count = 0

label start:
    while count < 3:
        @set count += 1
        Ryone: Count {count}.
    endwhile
    jump ending

label ending:
    Ryone: Loop finished.
```

也支持 `call` 和 `return`：

```text
label start:
    call intro
    Ryone: Back from intro.
    jump ending

label intro:
    Ryone: This is a reusable scene.
    return

label ending:
    Ryone: End.
```

## 10. 接入存档和读档

Novella 的 `save_manager` 可以写入 `user://novella/saves`，也可以在测试中使用内存存储。

最简单的快速存档：

```gdscript
func quick_save() -> void:
	var result := Novella.save_manager.quick_save(Novella.vm.snapshot_state(), {
		"title": "Chapter 1",
		"summary": "After meeting Ryone",
	})
	print(result)
```

快速读档：

```gdscript
func quick_load() -> void:
	var payload := Novella.save_manager.quick_load()
	if bool(payload.get("ok", false)):
		Novella.vm.restore_state(payload.get("state", {}))
```

普通槽位存档：

```gdscript
func save_to_slot(slot_index: int) -> void:
	var slot := StringName("slot_%s" % slot_index)
	Novella.save_manager.save_game(slot, Novella.vm.snapshot_state(), {
		"title": "Manual Save %s" % slot_index,
		"chapter": "Chapter 1",
	})
```

列出存档槽：

```gdscript
func print_slots() -> void:
	for slot in Novella.save_manager.list_slots():
		print(slot)
```

默认是 64 个槽位，每页 8 个。

## 11. 使用设置系统

设置管理器保存文字速度、自动播放延迟、音量、全屏、语言等配置。

修改设置：

```gdscript
func configure_text() -> void:
	Novella.settings_manager.set_setting(&"text_speed", 48.0)
	Novella.settings_manager.set_setting(&"auto_delay", 2.0)
	Novella.settings_manager.set_setting(&"locale", "zh")
	Novella.settings_manager.save_to_disk()
```

读取设置：

```gdscript
func load_settings() -> void:
	var result := Novella.settings_manager.load_from_disk()
	if bool(result.get("ok", false)):
		Novella.settings_manager.apply_to(Novella.variables, Novella.auto_manager)
```

剧本里也可以修改设置：

```text
@settings set text_speed:48 auto_delay:2.0 fullscreen:false
@config set locale:zh
```

## 12. 使用本地化

在剧本里添加翻译：

```text
@translation en line.greeting text:"Hello {player}."
@translation zh line.greeting text:"你好，{player}。"
@locale zh
Ryone: $line.greeting
```

在 GDScript 中导入 CSV：

```gdscript
func import_translations() -> void:
	var csv := "key,text\nline.greeting,\"你好，{player}。\"\n"
	Novella.localization_manager.import_csv(&"zh", csv, true)
```

导出 CSV：

```gdscript
func export_translations() -> void:
	var csv := Novella.localization_manager.export_csv(&"zh")
	print(csv)
```

CSV 列名是 `key,text`。带引号字段和转义引号已经支持。

## 13. 使用画廊、回放和成就

剧本里解锁画廊：

```text
@gallery unlock cg_school type:cg title:School asset:res://art/backgrounds/school_day.png
```

解锁回放：

```text
@replay unlock intro_replay label:start title:Intro
```

注册并推进成就：

```text
@achievement register collector title:Collector target:3
@achievement progress collector amount:1
@achievement unlock first_memory title:FirstMemory
```

GDScript 中读取状态：

```gdscript
func print_meta() -> void:
	print(Novella.gallery_manager.list_items("", true))
	print(Novella.achievement_manager.list_achievements(false))
```

## 14. 使用编辑器 Dock

启用插件后，Godot 编辑器右侧会出现 `Novella` dock。它可以：

- 分析 `.nvs` 文件。
- 生成 outline。
- 生成 timeline 模型。
- 报告未知命令、缺失 label 等诊断。
- 提供剧本模板。
- 索引可能的角色、背景、音频、脚本和 UI 资源。
- 打开可视化时间线面板基础功能。

建议流程：

1. 在 dock 中选择你的 `.nvs` 文件。
2. 点击分析。
3. 先修复错误级诊断。
4. 再处理警告。
5. 使用 outline 检查 label 和剧情结构。
6. 使用 timeline 检查事件顺序。

## 15. 迁移旧剧本

Novella 1.0 提供迁移器，用来统一脚本版本头和旧命令别名。

```gdscript
func migrate_script(path: String) -> void:
	var source := FileAccess.get_file_as_string(path)
	var result := Novella.script_migration.migrate(source)
	if not bool(result.get("ok", false)):
		push_error(str(result))
		return

	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(result["source"])
```

迁移器会做这些事：

- 添加或更新 `# novella_version: 1.0`。
- 把 `@language` 改为 `@locale`。
- 把 `@achieve` 改为 `@achievement`。
- 返回变更说明和警告列表。

## 16. 检查兼容性

运行时检查：

```gdscript
func print_compatibility() -> void:
	var status := Novella.compatibility_matrix.runtime_status()
	print(status["message"])
```

目标矩阵：

- Godot 4.3：最低兼容目标。
- Godot 4.4：兼容目标。
- Godot 4.5：兼容目标。
- Godot 4.6：主验证版本。
- Godot 4.7+：预期兼容，除非 Godot 改动相关 API。

## 17. 运行测试

在仓库根目录运行：

```powershell
.\scripts\test-godot.ps1
```

如果 Godot 不在默认位置，指定可执行文件：

```powershell
.\scripts\test-godot.ps1 -GodotExe "C:\Path\To\Godot_v4.6-stable_win64_console.exe"
```

正常通过时会看到类似输出：

```text
Novella v1.1.0 tests passed.
```

如果 Windows 输出：

```text
ERROR: Failed to read the root certificate store.
```

但进程退出码为 0 且测试通过，可以先视为 Godot/系统证书读取警告，不是 Novella 测试失败。

## 18. 发布校验

运行：

```powershell
.\scripts\validate-release.ps1
```

它会检查：

- 必需文件是否被 Git 跟踪。
- 插件版本号是否和 `Constants.VERSION` 一致。
- 是否误提交 Godot 引擎、导出模板、缓存、日志、生成包、本地需求文档等禁止路径。
- Godot 测试是否通过。

只做快速发布文件检查，可以跳过 Godot 测试：

```powershell
.\scripts\validate-release.ps1 -SkipGodotTests
```

## 19. 打包插件

运行：

```powershell
.\scripts\package-addon.ps1
```

生成文件：

```text
dist/novella-1.1.0.zip
```

`dist/` 已被忽略，不要提交。打包脚本只归档已跟踪的源码、示例、测试、脚本、公开文档、`README.md`、`LICENSE` 和 `project.godot`。

## 20. 常见问题

### 插件没有出现在 Plugins 列表里

检查：

- `addons/novella/plugin.cfg` 是否存在。
- `plugin.cfg` 里的 `script="novella_editor_plugin.gd"` 是否正确。
- 项目是不是 Godot 4.x。

### Autoload 里没有 Novella

手动添加：

- Name: `Novella`
- Path: `res://addons/novella/novella.gd`

### 剧本运行后没有输出

检查：

- `.nvs` 路径是否正确。
- 文件是否真的写入了内容。
- Godot 输出面板是否过滤了普通 `print`。
- `Novella.run_script(source, path)` 是否被调用。

### 菜单没有等玩家点击

默认情况下 VM 同步执行，菜单默认选第一个可用项。你可以用 `choice_strategy` 控制选择逻辑；也可以把 `Novella.vm.auto_select_choices` 设为 `false`，监听 `choice_waiting`，再用 `choose(index)` 从点击式 UI 恢复执行。

### 存档没有写入

检查：

- 是否有权限写入 `user://novella/saves`。
- 是否使用了内存存储模式。
- 槽位名是否一致。
- `save_game` 或 `quick_save` 返回的 `ok` 是否为 `true`。

### 不小心把引擎或缓存放进仓库

先不要提交。检查 `.gitignore`，确认这些路径被忽略：

- `GodotEngine/`
- `.godot/`
- `.godot_user/`
- `export_templates/`
- `dist/`
- `build/`
- `exports/`

已经被 Git 跟踪的文件，需要从索引中移除，但不要删除本地文件：

```powershell
git rm --cached path/to/file
```

## 21. 推荐开发流程

日常写剧本：

1. 编辑 `.nvs`。
2. 用 Novella dock 分析诊断。
3. 运行主场景测试。
4. 检查变量、菜单、跳转和本地化。
5. 做一次快速存档和读档。

提交前：

1. 运行 `.\scripts\test-godot.ps1`。
2. 运行 `.\scripts\validate-release.ps1`。
3. 检查 `git status --short`。
4. 确认没有 Godot 引擎、缓存、导出模板、本地需求文档或生成包。
5. 提交源码、示例、测试和公开文档。

发布前：

1. 更新版本号。
2. 更新发布文档。
3. 运行完整测试。
4. 运行发布校验。
5. 运行打包脚本。
6. 检查 `dist/novella-<version>.zip`。
7. 提交、打 tag、推送。
