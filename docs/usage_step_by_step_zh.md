# Novella v2.0.0 详细使用教程

这是一份面向第一次使用 Novella 的手把手教程。你可以按顺序从第 1 步做到最后，也可以把它当作项目接入检查清单。

本文默认你使用的是 Godot 4.6。Novella 的兼容目标是 Godot 4.3+ 的 Godot 4.x 系列，但如果你要做正式项目，建议先用 Godot 4.6 跑通流程，再按需要补测 4.3、4.4、4.5。

重要原则：

- 不要把 Godot 引擎可执行文件提交到 Git。
- 不要把 Godot export templates 提交到 Git。
- 不要提交 `.godot/`、`.godot_user/`、`dist/`、导出的游戏包、本地需求文档、本地进度文档。
- 只提交 `addons/novella/`、脚本、示例、测试、公开文档、项目配置和你自己的小型源码资源。

## 目录

1. 准备环境
2. 获取 Novella
3. 在新 Godot 项目里安装插件
4. 在本仓库里直接运行
5. 启用插件和 Autoload
6. 创建推荐目录结构
7. 写第一个 `.nvs` 剧本
8. 用最短 GDScript 跑脚本
9. 接入默认 RuntimePlayer UI
10. 添加背景、角色和音频资源
11. 使用变量、条件、菜单和跳转
12. 使用 ADV/NVL 文本模式
13. 使用本地化
14. 使用存档、读档、自动存档、回滚和已读状态
15. 使用快捷菜单、确认框、toast 和隐藏对话框
16. 使用编辑器预览、时间线和资源工作台
17. 使用调试工具
18. 运行测试
19. 打包插件
20. Git 和 GitHub 管理注意事项
21. 常见问题排查
22. 从空项目到可玩 Demo 的完整流程

## 1. 准备环境

### 1.1 安装 Godot

1. 打开 Godot 官网下载页。
2. 下载 Godot 4.6 的标准版或 Mono 版。
3. 解压到你电脑上的任意本地目录，例如：

```text
D:\Tools\Godot\Godot_v4.6-stable_win64.exe
```

4. 不要把 Godot 可执行文件放进你的项目仓库。
5. 不要把 Godot export templates 放进你的项目仓库。

如果你使用本仓库提供的测试脚本，可以设置环境变量 `GODOT_EXE`：

```powershell
$env:GODOT_EXE = "D:\Tools\Godot\Godot_v4.6-stable_win64_console.exe"
```

如果你已经把 Godot 放在本仓库的 `GodotEngine/` 目录里，也没关系；这个目录已被 `.gitignore` 忽略，不会被提交。

### 1.2 安装 Git

1. 安装 Git for Windows。
2. 打开 PowerShell。
3. 输入：

```powershell
git --version
```

4. 如果能看到版本号，说明 Git 可用。

### 1.3 准备一个项目目录

推荐把项目放在一个没有中文乱码风险、路径较短的位置，例如：

```text
R:\Projects\MyVisualNovel
```

路径里可以有中文，但如果你要跑自动化脚本，英文路径会省心一些。

## 2. 获取 Novella

你有两种方式。

### 2.1 方式 A：从 GitHub Release 下载

适合只想在自己的 Godot 项目里使用插件的人。

1. 打开 Novella Release 页面：

```text
https://github.com/TodayYueC/Novella/releases
```

2. 找到最新版本，例如 `v2.0.0`。
3. 下载 `novella-2.0.0.zip`。
4. 解压 zip。
5. 你会看到类似这些内容：

```text
addons/novella/
docs/
examples/
scripts/
tests/
README.md
LICENSE
project.godot
```

6. 后续只需要把 `addons/novella/` 复制到你自己的 Godot 项目里。

### 2.2 方式 B：克隆 GitHub 仓库

适合想研究源码、参与开发或直接运行示例的人。

```powershell
git clone https://github.com/TodayYueC/Novella.git
cd Novella
```

克隆后不要把 Godot 引擎放进仓库里提交。仓库已经配置 `.gitignore`，但你仍然要养成先看 `git status` 的习惯。

## 3. 在新 Godot 项目里安装插件

如果你已经有一个 Godot 项目，按下面做。

### 3.1 复制插件目录

假设你的 Godot 项目结构是：

```text
MyVisualNovel/
  project.godot
```

把 Novella 的插件目录复制进去，变成：

```text
MyVisualNovel/
  project.godot
  addons/
    novella/
      plugin.cfg
      novella.gd
      novella_editor_plugin.gd
      ...
```

注意：

- 必须是 `addons/novella/`。
- 不要改成 `addons/Novella/`。
- 不要只复制一部分文件。

### 3.2 打开 Godot 项目

1. 启动 Godot。
2. 点击 `Import`。
3. 选择你的 `MyVisualNovel/project.godot`。
4. 打开项目。

### 3.3 启用插件

1. 在 Godot 顶部菜单点击 `Project`。
2. 点击 `Project Settings...`。
3. 切到 `Plugins` 标签。
4. 找到 `Novella`。
5. 勾选 `Enable`。

启用后，Godot 编辑器里会出现 Novella 的编辑器扩展能力，例如 dock、脚本分析、时间线和资源工具。

## 4. 在本仓库里直接运行

如果你克隆的是 Novella 仓库本身：

1. 启动 Godot。
2. 点击 `Import`。
3. 选择仓库根目录的 `project.godot`。
4. 打开项目。
5. 插件和 Autoload 已经在这个项目里配置好。

本仓库更适合做插件开发和测试；正式游戏建议新建你自己的 Godot 项目，然后复制 `addons/novella/`。

## 5. 启用插件和 Autoload

Novella 的运行时默认入口是：

```text
res://addons/novella/novella.gd
```

你需要把它注册成 Autoload。

### 5.1 添加 Autoload

1. 打开 `Project > Project Settings...`。
2. 点击 `Globals > Autoload`。
3. 在 `Path` 里选择：

```text
res://addons/novella/novella.gd
```

4. 在 `Node Name` 里输入：

```text
Novella
```

5. 点击 `Add`。

完成后，你可以在任何 GDScript 里直接访问：

```gdscript
Novella.run_script(...)
Novella.vm
Novella.save_manager
Novella.localization_manager
```

### 5.2 检查 Autoload 是否生效

新建一个测试脚本：

```gdscript
extends Node

func _ready() -> void:
	print(Novella)
```

运行场景。如果输出不是 `null`，说明 Autoload 可用。

## 6. 创建推荐目录结构

在你的项目根目录下创建这些文件夹：

```text
res://story/
res://story/scripts/
res://art/
res://art/backgrounds/
res://art/characters/
res://art/characters/ryone/
res://art/characters/ryone/side/
res://audio/
res://audio/bgm/
res://audio/se/
res://audio/voice/
res://audio/voice/ryone/
res://gallery/
res://ui/
res://scenes/
```

每个目录的用途：

- `story/scripts/`：放 `.nvs` 剧本。
- `art/backgrounds/`：放背景图。
- `art/characters/`：放角色立绘。
- `art/characters/<角色>/side/`：放对话框侧边头像。
- `audio/bgm/`：放背景音乐。
- `audio/se/`：放音效。
- `audio/voice/`：放语音。
- `gallery/`：放 CG 或鉴赏资源。
- `ui/`：放你自己的 UI 资源。
- `scenes/`：放 Godot 场景。

## 7. 写第一个 `.nvs` 剧本

创建文件：

```text
res://story/scripts/chapter_01.nvs
```

写入：

```text
# novella_version: 2.0
@var player = "Yue"
@var affinity = 0

label start:
    @bg school_day transition:dissolve time:0.6
    @char ryone uniform_happy pos:left enter:fade
    @play_music main_theme fade:1.0
    Ryone: Hello {player}. Welcome to Novella.
    @set affinity += 5
    menu:
        "Stay" if affinity >= 5:
            Ryone: I am glad you stayed.
            jump stay_path
        "Leave":
            jump leave_path

label stay_path:
    Ryone: This is the stay route.
    jump ending

label leave_path:
    Ryone: This is the leave route.
    jump ending

label ending:
    @stop_music fade:0.5
    Ryone: Demo finished.
```

### 7.1 语法解释

`@var player = "Yue"` 声明变量。

`label start:` 定义入口标签。

`@bg school_day` 切换背景。

`@char ryone uniform_happy` 显示角色。

`Ryone: ...` 是角色对话。

`@set affinity += 5` 修改变量。

`menu:` 创建选项菜单。

`"Stay" if affinity >= 5:` 表示选项有条件。

`jump stay_path` 跳转到标签。

`@stop_music` 停止音乐。

## 8. 用最短 GDScript 跑脚本

创建一个场景：

1. 新建 `Node` 场景。
2. 保存为：

```text
res://scenes/main.tscn
```

3. 给根节点挂脚本：

```text
res://scenes/main.gd
```

写入：

```gdscript
extends Node

func _ready() -> void:
	var path := "res://story/scripts/chapter_01.nvs"
	var source := FileAccess.get_file_as_string(path)
	var transcript := Novella.run_script(source, path)
	for entry in transcript:
		print(entry)
```

运行场景后，你会在 Output 面板看到执行结果。

这种方式适合做脚本引擎测试，但它不会自动显示完整 UI。真正游戏里建议用 RuntimePlayer。

## 9. 接入默认 RuntimePlayer UI

Novella 提供默认运行时场景：

```text
res://addons/novella/presentation/ui/runtime_player.tscn
```

### 9.1 创建主场景

1. 打开你的 `res://scenes/main.tscn`。
2. 根节点用 `Control` 或 `Node` 都可以。
3. 把 `runtime_player.tscn` 拖到场景里。
4. 节点名建议改成：

```text
RuntimePlayer
```

场景结构类似：

```text
Main
  RuntimePlayer
```

### 9.2 编写主场景脚本

如果根节点是 `Control` 或 `Node`，脚本都可以这样写：

```gdscript
extends Node

@onready var player = $RuntimePlayer

func _ready() -> void:
	player.bind_runtime(Novella)
	var path := "res://story/scripts/chapter_01.nvs"
	var source := FileAccess.get_file_as_string(path)
	player.start_script(source, path)
```

运行后：

- 左键或空格推进文本。
- 遇到 `menu:` 会显示选项按钮。
- 点击选项后继续执行对应分支。
- `H` 或 `Esc` 可以隐藏/恢复对话 UI。

### 9.3 设置主场景

1. 打开 `Project > Project Settings...`。
2. 找到 `Application > Run > Main Scene`。
3. 选择：

```text
res://scenes/main.tscn
```

4. 点击运行按钮。

## 10. 添加背景、角色和音频资源

Novella 的脚本里使用资源 ID，例如：

```text
@bg school_day
@char ryone uniform_happy
@play_music main_theme
```

这些 ID 通常来自文件名或你自己的资源注册。

### 10.1 背景图

把背景图放到：

```text
res://art/backgrounds/school_day.png
```

脚本写：

```text
@bg school_day transition:dissolve time:0.6
```

### 10.2 角色立绘

把角色立绘放到：

```text
res://art/characters/ryone/uniform_happy.png
```

脚本写：

```text
@char ryone uniform_happy pos:left enter:fade
```

### 10.3 侧边头像

把头像放到：

```text
res://art/characters/ryone/side/default.png
```

资源工作台可以把它识别为角色侧边头像。

### 10.4 BGM

把音乐放到：

```text
res://audio/bgm/main_theme.ogg
```

脚本写：

```text
@play_music main_theme fade:1.0
```

停止：

```text
@stop_music fade:0.5
```

### 10.5 音效

把音效放到：

```text
res://audio/se/door_open.ogg
```

脚本写：

```text
@play_se door_open volume:0.8
```

### 10.6 语音

把语音放到：

```text
res://audio/voice/ryone/ryone_002.ogg
```

在代码里注册语音行：

```gdscript
Novella.audio_manager.register_voice_line(
	&"Ryone",
	2,
	&"ryone_002",
	"res://audio/voice/ryone/ryone_002.ogg"
)
```

当 VM 执行第 2 行 `Ryone` 的对话时，会自动查找并播放对应语音。

## 11. 使用变量、条件、菜单和跳转

### 11.1 声明变量

```text
@var affinity = 0
@var route = ""
@var has_key = false
```

### 11.2 修改变量

```text
@set affinity += 1
@set route = "stay"
@set has_key = true
```

### 11.3 在文本里显示变量

```text
Ryone: Affinity is {affinity}.
```

### 11.4 条件选项

```text
menu:
    "Open the door" if has_key:
        jump door_path
    "Wait":
        Ryone: We wait a little longer.
```

### 11.5 if/else

```text
if affinity >= 5:
    Ryone: You unlocked this line.
else:
    Ryone: Not enough affinity.
endif
```

### 11.6 while 循环

```text
while affinity < 10:
    @set affinity += 1
    Ryone: Affinity is {affinity}.
    @if affinity >= 8 then break
endwhile
```

### 11.7 子流程

```text
label start:
    call intro
    jump ending

label intro:
    Ryone: This is a subroutine.
    return

label ending:
    Ryone: End.
```

## 12. 使用 ADV/NVL 文本模式

ADV 是常见底部对话框模式。

```text
@mode adv
Ryone: This is ADV mode.
```

NVL 是全屏文本页模式。

```text
@mode nvl
The classroom is quiet.
The wind passes through the window.
@nvl_clear
@mode adv
```

建议：

- 普通角色对话用 ADV。
- 长段心理描写、旁白、回忆用 NVL。
- 用完 NVL 后切回 ADV，避免后续对话显示到错误模式。

## 13. 使用本地化

### 13.1 在脚本里写翻译

```text
@locale en
@translation en line.hello text:"Hello {player}."
@translation zh line.hello text:"你好，{player}。"
Ryone: $line.hello
```

`$line.hello` 会按当前语言显示对应文本。

### 13.2 切换语言

```text
@locale zh
```

或在代码里：

```gdscript
Novella.localization_manager.set_locale(&"zh")
```

### 13.3 导出 CSV

```gdscript
var csv := Novella.localization_manager.export_csv(&"en")
print(csv)
```

### 13.4 导入 CSV

```gdscript
var csv := "key,text\nline.hello,你好。\n"
Novella.localization_manager.import_csv(&"zh", csv, false)
```

### 13.5 语言包

```gdscript
Novella.localization_manager.register_language_pack(&"ja_pack", &"ja", {
	"entries": {
		"line.hello": "こんにちは。",
	},
	"assets": {
		"school_day": "res://art/backgrounds/school_day_ja.png",
	},
	"typography": {
		"font": "Noto Sans JP",
		"line_break": "strict",
	},
})

Novella.localization_manager.load_language_pack(&"ja_pack")
```

## 14. 使用存档、读档、自动存档、回滚和已读状态

### 14.1 普通存档

脚本里：

```text
@save slot_1 title:"Chapter 1"
```

代码里：

```gdscript
var state := Novella.vm.snapshot_state()
Novella.save_manager.save_game(&"slot_1", state, {"title": "Chapter 1"})
```

### 14.2 读档

脚本里：

```text
@load slot_1
```

代码里：

```gdscript
var payload := Novella.save_manager.load_game(&"slot_1")
if payload["ok"]:
	Novella.vm.restore_state(payload["state"])
```

### 14.3 快速存档和快速读档

```text
@quick_save
@quick_load
```

或：

```gdscript
Novella.save_manager.quick_save(Novella.vm.snapshot_state())
var payload := Novella.save_manager.quick_load()
```

### 14.4 自动存档

```text
@auto_save
```

或：

```gdscript
Novella.save_manager.autosave_if(&"choice", Novella.vm.snapshot_state())
```

### 14.5 导出存档

```gdscript
var exported := Novella.save_manager.export_save(&"slot_1")
print(exported["text"])
```

### 14.6 加密导出存档

```gdscript
var exported := Novella.save_manager.export_save(&"slot_1", true, "my_passphrase")
```

### 14.7 导入存档

```gdscript
Novella.save_manager.import_save(exported["text"], &"slot_2", "my_passphrase")
```

### 14.8 回滚

回滚一步：

```text
@rollback
```

代码里：

```gdscript
var payload := Novella.rollback_manager.rollback()
if payload["ok"]:
	Novella.vm.restore_state(payload["state"])
```

回滚到某一行：

```gdscript
var payload := Novella.rollback_manager.rollback_to_line(20)
```

查看可回滚目标：

```gdscript
var targets := Novella.rollback_manager.list_targets()
```

### 14.9 已读状态

导出已读状态：

```gdscript
var text := Novella.skip_manager.export_read_state()
```

导入已读状态：

```gdscript
Novella.skip_manager.import_read_state(text)
```

## 15. 使用快捷菜单、确认框、toast 和隐藏对话框

### 15.1 显示或隐藏快捷菜单

```text
@quick_menu show
@quick_menu hide
```

### 15.2 配置快捷菜单按钮顺序

```gdscript
Novella.quick_menu_manager.move_action(&"config", 0)
```

### 15.3 隐藏某个按钮

```gdscript
Novella.quick_menu_manager.set_action_visible(&"gallery", false)
```

### 15.4 给危险操作加确认提示

```gdscript
Novella.quick_menu_manager.configure_action(&"title", {
	"confirm_message": "Return to title?"
})
```

调用：

```gdscript
var result := Novella.quick_menu_manager.dispatch_action(&"title")
if result.get("confirmation_required", false):
	print(result["message"])
```

确认后再执行：

```gdscript
Novella.quick_menu_manager.dispatch_action(&"title", {"confirmed": true})
```

### 15.5 toast 提示

```gdscript
var feedback := NovellaUIFeedbackManager.new()
feedback.push_toast("Saved", &"success", 2.0)
```

### 15.6 隐藏对话框

使用 RuntimePlayer 时：

- 按 `H`。
- 或按 `Esc`。
- 或调用 RuntimeStage 的 `set_ui_hidden(true)`。

## 16. 使用编辑器预览、时间线和资源工作台

### 16.1 创建生产工作流对象

```gdscript
var workflow := NovellaProductionWorkflow.new()
```

### 16.2 分析脚本

```gdscript
var source := FileAccess.get_file_as_string("res://story/scripts/chapter_01.nvs")
var report := workflow.analyze_script(source, "chapter_01.nvs", [], [
	"res://art/backgrounds/school_day.png",
	"res://art/characters/ryone/uniform_happy.png",
	"res://audio/bgm/main_theme.ogg",
])

print(report["ok"])
print(report["diagnostics"])
print(report["assets"])
```

### 16.3 实时预览

```gdscript
var session := workflow.create_preview_session(source, "chapter_01.nvs")
print(session.preview_state())
```

推进一句：

```gdscript
session.advance()
```

选择选项：

```gdscript
session.choose(0)
```

跳转标签：

```gdscript
session.jump_to_label(&"ending")
```

### 16.4 时间线编辑

```gdscript
var timeline := NovellaTimelineEditorModel.new()
var edit_session := workflow.create_timeline_session(source, "chapter_01.nvs")
timeline.load_events(edit_session["events"])
timeline.copy_events([0])
timeline.paste_events(1)
timeline.set_event_collapsed(0, true)
var script := timeline.to_script()
```

### 16.5 资源工作台

```gdscript
var workbench := NovellaResourceWorkbench.new()
var catalog := workbench.build_asset_catalog([
	"res://art/backgrounds/school_day.png",
	"res://art/characters/ryone/uniform_happy.png",
	"res://art/characters/ryone/side/default.png",
	"res://audio/bgm/main_theme.ogg",
])

print(catalog["summary"])
```

自动生成角色资源：

```gdscript
workbench.auto_character_from_assets(&"ryone", [
	"res://art/characters/ryone/uniform_happy.png",
	"res://art/characters/ryone/side/default.png",
])
```

预览角色：

```gdscript
var preview := workbench.preview_character(&"ryone", ["uniform_happy"])
print(preview)
```

## 17. 使用调试工具

### 17.1 查看变量

```gdscript
var tools := NovellaDeveloperTools.new()
var watch := tools.variable_watch(Novella.variables)
print(watch)
```

### 17.2 修改变量

```gdscript
tools.set_variable(Novella.variables, &"affinity", 10)
```

### 17.3 执行控制台命令

```gdscript
tools.execute_console("@set affinity += 1", Novella.commands, {
	"variables": Novella.variables,
})
```

### 17.4 查看 VM 状态

```gdscript
var trace := tools.trace_vm(Novella.vm)
print(trace)
```

### 17.5 生成调试面板数据

```gdscript
var panel := NovellaDebugPanelModel.new()
var data := panel.build_panels(
	Novella.vm,
	Novella.variables,
	Novella.commands,
	get_tree().root,
	Novella.vm.ast
)
print(data)
```

### 17.6 性能基线

```gdscript
var budget := NovellaPerformanceBudget.new()
var baseline := budget.capture(get_tree().root)
budget.set_baseline(&"default", baseline)

var current := budget.capture(get_tree().root)
var result := budget.compare(&"default", current, {
	"node_count": 1000,
	"resource_count": 500,
})

print(result)
```

## 18. 运行测试

在 Novella 仓库根目录执行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-godot.ps1
```

如果 Godot 不在默认路径，指定 Godot：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-godot.ps1 -GodotExe "D:\Tools\Godot\Godot_v4.6-stable_win64_console.exe"
```

看到类似输出表示通过：

```text
Novella v2.0.0 tests passed.
```

如果出现：

```text
ERROR: Failed to read the root certificate store.
```

但脚本退出码是 0，而且测试显示 passed，可以先视为 Godot 在当前 Windows 环境下的证书读取警告，不是 Novella 测试失败。

## 19. 打包插件

### 19.1 发布校验

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\validate-release.ps1
```

通过时会看到：

```text
Novella release validation passed for 2.0.0.
```

### 19.2 生成 zip

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\package-addon.ps1
```

生成：

```text
dist/novella-2.0.0.zip
```

`dist/` 是忽略目录，不要提交。

### 19.3 检查 zip 内容

```powershell
tar -tf .\dist\novella-2.0.0.zip
```

确认里面应该有：

```text
addons/novella/
docs/
examples/
scripts/
tests/
README.md
LICENSE
project.godot
```

确认里面不应该有：

```text
GodotEngine/
.godot/
.godot_user/
dist/
Novella_项目需求文档.md
Novella_项目进度文档.md
*.exe
*.pck
*.apk
*.aab
```

## 20. Git 和 GitHub 管理注意事项

### 20.1 查看状态

每次提交前先看：

```powershell
git status --short
```

### 20.2 不应该出现在 Git 状态里的内容

如果你看到这些，先停下来：

```text
GodotEngine/
.godot/
.godot_user/
dist/
Novella_项目需求文档.md
Novella_项目进度文档.md
```

这些文件应该被 `.gitignore` 忽略。

### 20.3 提交源码

示例：

```powershell
git add addons docs examples tests README.md project.godot LICENSE
git commit -m "feat: add my visual novel content"
git push origin main
```

### 20.4 不要提交大型资源

如果后续要放大量图片、语音、视频：

1. 先评估文件大小。
2. 小型占位资源可以直接提交。
3. 大型资源建议使用 Git LFS。
4. 引擎可执行文件和导出模板永远不要提交。

## 21. 常见问题排查

### 21.1 Godot 找不到 Novella

检查：

1. `addons/novella/plugin.cfg` 是否存在。
2. 插件是否在 `Project Settings > Plugins` 启用。
3. Autoload 是否有 `Novella`。
4. Autoload 路径是否是：

```text
res://addons/novella/novella.gd
```

### 21.2 运行时报 `Novella` 是 null

说明 Autoload 没配置或名字不对。

正确名字必须是：

```text
Novella
```

大小写要一致。

### 21.3 脚本不执行

检查：

1. `.nvs` 文件路径是否正确。
2. `FileAccess.get_file_as_string(path)` 是否读到了内容。
3. 是否有 `label start:`。
4. 缩进是否正确。
5. `menu:` 下面的选项是否缩进。
6. `jump` 的目标 label 是否存在。

### 21.4 菜单不显示

如果你用 `Novella.run_script()`，它只返回 transcript，不会自动显示 UI。

要显示菜单按钮，请使用：

```text
res://addons/novella/presentation/ui/runtime_player.tscn
```

并调用：

```gdscript
player.bind_runtime(Novella)
player.start_script(source, path)
```

### 21.5 背景或角色没有真实图片

默认 RuntimeStage 会显示状态标记，不一定直接渲染你的真实图片。你可以：

1. 先用它验证脚本流程。
2. 再用 `NovellaSceneRenderer` 的 render plan 接入自己的 Sprite、TextureRect、AnimationPlayer、Shader。
3. 或替换默认 RuntimeStage。

### 21.6 语音没有播放

检查：

1. 是否注册了语音行。
2. speaker 是否完全一致。
3. line id 是否一致。
4. 音频路径是否正确。
5. 文件扩展名是否是 `ogg`、`wav` 或 `mp3`。

### 21.7 存档找不到

检查：

1. 是否调用过 `save_game`。
2. slot 名字是否一致。
3. 如果使用内存存档，重启游戏后会丢失。
4. 如果使用磁盘存档，检查 `user://novella/saves`。

### 21.8 测试时弹 Windows 崩溃框

优先使用：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\test-godot.ps1
```

不要用会启动完整编辑器导入流程的命令去跑自动测试。完整编辑器启动可能会访问用户目录、证书、编辑器缓存，在受限环境下可能触发 Godot 自身崩溃。

## 22. 从空项目到可玩 Demo 的完整流程

下面是一条完整路线。按顺序做，做完你会得到一个能运行、能选择分支、能显示基本 UI 的 Demo。

### 22.1 新建项目

1. 打开 Godot。
2. 点击 `New Project`。
3. 项目名输入：

```text
MyNovellaDemo
```

4. 选择空目录。
5. Renderer 用默认设置。
6. 点击 `Create & Edit`。

### 22.2 安装插件

1. 从 Novella Release 下载 zip。
2. 解压。
3. 复制 `addons/novella/` 到你的项目。
4. 回到 Godot。
5. 打开 `Project > Project Settings > Plugins`。
6. 启用 `Novella`。

### 22.3 添加 Autoload

1. 打开 `Project > Project Settings > Globals > Autoload`。
2. Path 选择：

```text
res://addons/novella/novella.gd
```

3. Node Name 输入：

```text
Novella
```

4. 点击 `Add`。

### 22.4 创建目录

在 FileSystem 面板创建：

```text
story/scripts/
scenes/
art/backgrounds/
art/characters/ryone/
audio/bgm/
```

### 22.5 创建剧本

创建：

```text
res://story/scripts/chapter_01.nvs
```

写入：

```text
@var route = ""

label start:
    @bg school_day transition:dissolve
    @char ryone uniform_happy pos:left
    Ryone: Welcome. Pick a route.
    menu:
        "Stay":
            @set route = "stay"
            jump stay
        "Leave":
            @set route = "leave"
            jump leave

label stay:
    Ryone: You stayed.
    jump end

label leave:
    Ryone: You left.
    jump end

label end:
    Ryone: Route is {route}.
```

### 22.6 创建主场景

1. 新建 `Control` 场景。
2. 保存为：

```text
res://scenes/main.tscn
```

3. 把这个场景设为 Main Scene。

### 22.7 添加 RuntimePlayer

1. 在 FileSystem 找到：

```text
res://addons/novella/presentation/ui/runtime_player.tscn
```

2. 拖到 `main.tscn` 的根节点下面。
3. 节点名改为：

```text
RuntimePlayer
```

### 22.8 添加主脚本

给根节点挂脚本：

```gdscript
extends Control

@onready var player = $RuntimePlayer

func _ready() -> void:
	player.bind_runtime(Novella)
	var path := "res://story/scripts/chapter_01.nvs"
	var source := FileAccess.get_file_as_string(path)
	player.start_script(source, path)
```

### 22.9 运行

1. 点击 Godot 右上角运行按钮。
2. 第一行对话出现。
3. 按空格或左键推进。
4. 出现选项后点击一个选项。
5. 确认路线变量 `{route}` 被插入到最后一句。

### 22.10 下一步

当这个 Demo 跑通后，再逐步加：

1. 真实背景图。
2. 真实角色立绘。
3. BGM。
4. 语音绑定。
5. 存档界面。
6. 本地化 CSV。
7. 画廊和成就。
8. 自定义 UI 皮肤。
9. 发布打包流程。

这样做比一开始就堆完整项目更稳。每加一个系统，就跑一次 Demo，确认没有破坏前面的流程。

## 23. 使用 v2.1.0 可视化剧情编辑器

这一节适合不想直接手写 `.nvs` 的作者。可视化编辑器不会替代脚本语法，但可以把最常见的剧情结构变成表单和事件卡片。

### 23.1 打开 Novella Dock

1. 打开 Godot 4.6。
2. 打开项目。
3. 进入 `Project > Project Settings > Plugins`。
4. 确认 `Novella` 插件已经启用。
5. 在编辑器右侧找到 `Novella` Dock。

### 23.2 新建剧情文件

1. 在 Dock 顶部路径栏输入：

```text
res://story/chapter_01.nvs
```

2. 点击 `New`。
3. 切到 `Inspector` 页。
4. 在 `ScriptPreview` 里确认已经出现 starter 剧本。
5. 点击 `Save`，把 starter 剧本写入这个路径。

### 23.3 添加对白

1. 切到 `Inspector` 页。
2. 在 `Type` 里选择 `Dialogue`。
3. 在 `Speaker` 输入角色名，例如：

```text
Ryone
```

4. 在 `Text / Args` 输入对白：

```text
Welcome to the visual editor.
```

5. 点击 `Add`。
6. 切到 `Visual` 页，确认新增了一张对白事件卡。
7. 回到 `Inspector` 页，确认 `ScriptPreview` 里出现：

```text
Ryone: Welcome to the visual editor.
```

### 23.4 添加背景、角色和音乐

背景事件：

1. `Type` 选择 `Background`。
2. `Name` 输入背景 ID，例如 `school_day`。
3. `Command` 保持 `bg`，或者留空后由默认值补全。
4. `Text / Args` 可以输入参数，例如：

```text
transition:dissolve time:0.6
```

5. 点击 `Add`。

角色事件：

1. `Type` 选择 `Character`。
2. `Name` 输入角色 ID，例如 `ryone`。
3. `Command` 输入 `char`。
4. `Text / Args` 输入：

```text
uniform happy pos:left enter:fade
```

5. 点击 `Add`。

音乐事件：

1. `Type` 选择 `Audio`。
2. `Name` 输入音乐 ID，例如 `main_theme`。
3. `Command` 输入 `play_music`。
4. `Text / Args` 输入：

```text
fade:1.0 volume:0.8
```

5. 点击 `Add`。

### 23.5 添加菜单选项

1. `Type` 选择 `Menu`。
2. 在 `Choices` 中每行写一个选项。
3. 每行格式是：

```text
选项文本 | 条件 | 跳转目标
```

示例：

```text
Stay | affinity >= 5 | stay_path
Leave |  | leave_path
```

4. 点击 `Add`。
5. 再添加两个 `Label` 事件，`Name` 分别写 `stay_path` 和 `leave_path`。
6. 在两个 label 后面分别添加对应剧情。

生成的脚本会接近：

```text
menu:
    "Stay" if affinity >= 5:
        jump stay_path
    "Leave":
        jump leave_path
```

### 23.6 修改已有事件

1. 切到 `Visual` 页。
2. 点击一张事件卡。
3. 切回 `Inspector` 页。
4. 表单会填入选中事件的内容。
5. 修改字段。
6. 点击 `Update`。
7. 查看 `ScriptPreview`，确认脚本已经更新。

### 23.7 调整顺序、复制和撤销

在 `Visual` 页：

1. 选中事件卡。
2. 点击 `Up` 或 `Down` 调整顺序。
3. 点击 `Duplicate` 复制一份到后面。
4. 点击 `Copy` 后再点 `Paste`，把事件复制到当前位置后面。
5. 点击 `Delete` 删除选中事件。

在 `Inspector` 页：

1. 点击 `Undo` 撤销最近一次编辑。
2. 点击 `Redo` 重做刚撤销的编辑。

### 23.8 保存和重新载入

1. 每次完成一组编辑后，点击 Dock 顶部的 `Save`。
2. 关闭再打开项目后，在路径栏输入同一个 `.nvs` 路径。
3. 点击 `Analyze`。
4. `Visual` 页会重新显示事件卡片。
5. `Diagnostics` 页如果显示 `Errors: 0`，说明当前脚本没有结构性错误。

### 23.9 当前边界

`v2.1.0` 的可视化编辑器优先覆盖常见剧情写作流程。复杂的嵌套条件、循环、大规模资源批处理和完整拖拽式节点图仍建议配合 `.nvs` 文本编辑或后续版本继续增强。实际发布前仍应运行：

```powershell
.\scripts\test-godot.ps1
.\scripts\validate-release.ps1
```
