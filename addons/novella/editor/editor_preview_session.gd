extends RefCounted

class_name NovellaEditorPreviewSession

const Parser := preload("res://addons/novella/script/parser.gd")
const VM := preload("res://addons/novella/script/novella_vm.gd")
const VariableManager := preload("res://addons/novella/script/variable_manager.gd")
const CommandRegistry := preload("res://addons/novella/script/command_registry.gd")
const BasicCommands := preload("res://addons/novella/script/commands/basic_commands.gd")
const PresentationCommands := preload("res://addons/novella/script/commands/presentation_commands.gd")
const InteractionCommands := preload("res://addons/novella/script/commands/interaction_commands.gd")
const MetaCommands := preload("res://addons/novella/script/commands/meta_commands.gd")
const PrinterManager := preload("res://addons/novella/presentation/printer_manager.gd")
const CharacterManager := preload("res://addons/novella/presentation/characters/character_manager.gd")
const BackgroundManager := preload("res://addons/novella/presentation/backgrounds/background_manager.gd")
const EffectManager := preload("res://addons/novella/presentation/effects/effect_manager.gd")
const AudioManager := preload("res://addons/novella/presentation/audio/audio_manager.gd")
const CameraDirector := preload("res://addons/novella/presentation/camera/camera_director.gd")
const ChoiceManager := preload("res://addons/novella/interaction/choice_manager.gd")
const SaveManager := preload("res://addons/novella/state/save_manager.gd")
const SettingsManager := preload("res://addons/novella/state/settings_manager.gd")
const RollbackManager := preload("res://addons/novella/state/rollback_manager.gd")
const SkipManager := preload("res://addons/novella/interaction/skip_manager.gd")
const AutoManager := preload("res://addons/novella/interaction/auto_manager.gd")
const BacklogManager := preload("res://addons/novella/state/backlog_manager.gd")
const QuickMenuManager := preload("res://addons/novella/interaction/quick_menu_manager.gd")
const LocalizationManager := preload("res://addons/novella/meta/localization_manager.gd")
const GalleryManager := preload("res://addons/novella/meta/gallery_manager.gd")
const AchievementManager := preload("res://addons/novella/meta/achievement_manager.gd")
const DeveloperTools := preload("res://addons/novella/debug/developer_tools.gd")

var parser := Parser.new()
var vm: Variant = null
var registry: Variant = null
var managers: Dictionary = {}
var command_sets: Array = []
var developer_tools := DeveloperTools.new()
var source: String = ""
var file_path: String = ""
var ast = null

func _init() -> void:
	_build_runtime()


func start(next_source: String, next_file_path: String = "", max_steps: int = 10000) -> Dictionary:
	source = next_source
	file_path = next_file_path
	_build_runtime()
	ast = parser.parse(source, file_path)
	if not parser.errors.is_empty():
		return _preview_with_status(false, {"errors": parser.errors.duplicate()})
	vm.load_script(ast)
	vm.run(max_steps)
	return _preview_with_status(not _has_runtime_errors(), {"errors": parser.errors.duplicate()})


func advance(max_steps: int = 10000) -> Dictionary:
	if vm == null:
		return {"ok": false, "error": "Preview session has not been started."}
	var result: Dictionary = vm.advance(max_steps)
	return _preview_with_status(bool(result.get("ok", false)), {"action": "advance", "result": result})


func choose(choice_index: int, max_steps: int = 10000) -> Dictionary:
	if vm == null:
		return {"ok": false, "error": "Preview session has not been started."}
	var result: Dictionary = vm.choose(choice_index, max_steps)
	return _preview_with_status(bool(result.get("ok", false)), {"action": "choose", "choice_index": choice_index, "result": result})


func jump_to_label(label_name: Variant, max_steps: int = 10000) -> Dictionary:
	if vm == null or ast == null:
		return {"ok": false, "error": "Preview session has not been started."}
	var label := StringName(str(label_name))
	var index: int = vm.label_manager.get_index(label)
	if index < 0:
		return _preview_with_status(false, {"error": "Unknown label '%s'." % String(label)})
	vm.waiting_for_advance = false
	vm.waiting_for_choice = false
	vm.pending_choices.clear()
	vm.pending_available_indices.clear()
	vm.current_index = index
	vm.continue_run(max_steps)
	return _preview_with_status(not _has_runtime_errors(), {"action": "jump_to_label", "label": String(label)})


func preview_state() -> Dictionary:
	var trace := developer_tools.trace_vm(vm)
	var variables := developer_tools.variable_watch(managers.get("variable_manager"))
	var current_line := _current_line()
	return {
		"ok": trace.get("ok", false),
		"file_path": file_path,
		"current_line": current_line,
		"current_source": _source_line(current_line),
		"trace": trace,
		"variables": variables,
		"pending_advance": vm.get_pending_advance() if vm != null and vm.has_method("get_pending_advance") else {},
		"pending_choice": vm.get_pending_choice() if vm != null and vm.has_method("get_pending_choice") else {},
		"transcript": vm.transcript.duplicate(true) if vm != null else [],
		"stage": _stage_state(),
	}


func _build_runtime() -> void:
	var variables := VariableManager.new()
	registry = CommandRegistry.new()
	managers = {
		"variable_manager": variables,
		"printer_manager": PrinterManager.new(),
		"character_manager": CharacterManager.new(),
		"background_manager": BackgroundManager.new(),
		"effect_manager": EffectManager.new(),
		"audio_manager": AudioManager.new(),
		"camera_director": CameraDirector.new(),
		"choice_manager": ChoiceManager.new(),
		"save_manager": SaveManager.new(),
		"settings_manager": SettingsManager.new(),
		"rollback_manager": RollbackManager.new(),
		"skip_manager": SkipManager.new(),
		"auto_manager": AutoManager.new(),
		"backlog_manager": BacklogManager.new(),
		"quick_menu_manager": QuickMenuManager.new(),
		"localization_manager": LocalizationManager.new(),
		"gallery_manager": GalleryManager.new(),
		"achievement_manager": AchievementManager.new(),
	}
	var save_manager = managers["save_manager"]
	if save_manager.has_method("enable_memory_storage"):
		save_manager.enable_memory_storage(true)
	managers["choice_manager"].variable_manager = variables
	managers["choice_manager"].localization_manager = managers["localization_manager"]
	command_sets = [BasicCommands.new(), PresentationCommands.new(), InteractionCommands.new(), MetaCommands.new()]
	command_sets[0].register_all(registry, variables)
	command_sets[1].register_all(registry, managers)
	command_sets[2].register_all(registry, managers)
	command_sets[3].register_all(registry, managers)
	vm = VM.new()
	vm.variable_manager = variables
	vm.command_registry = registry
	vm.printer_manager = managers["printer_manager"]
	vm.choice_manager = managers["choice_manager"]
	vm.save_manager = managers["save_manager"]
	vm.rollback_manager = managers["rollback_manager"]
	vm.skip_manager = managers["skip_manager"]
	vm.auto_manager = managers["auto_manager"]
	vm.backlog_manager = managers["backlog_manager"]
	vm.quick_menu_manager = managers["quick_menu_manager"]
	vm.localization_manager = managers["localization_manager"]
	vm.gallery_manager = managers["gallery_manager"]
	vm.achievement_manager = managers["achievement_manager"]
	vm.state_providers = _state_providers()
	vm.pause_on_text = true
	vm.auto_select_choices = false


func _state_providers() -> Dictionary:
	return {
		&"printer": managers["printer_manager"],
		&"characters": managers["character_manager"],
		&"background": managers["background_manager"],
		&"effects": managers["effect_manager"],
		&"audio": managers["audio_manager"],
		&"camera": managers["camera_director"],
		&"choices": managers["choice_manager"],
		&"settings": managers["settings_manager"],
		&"skip": managers["skip_manager"],
		&"auto": managers["auto_manager"],
		&"backlog": managers["backlog_manager"],
		&"quick_menu": managers["quick_menu_manager"],
		&"localization": managers["localization_manager"],
		&"gallery": managers["gallery_manager"],
		&"achievements": managers["achievement_manager"],
	}


func _preview_with_status(ok: bool, extra: Dictionary = {}) -> Dictionary:
	var state := preview_state()
	state["ok"] = ok
	for key in extra:
		state[key] = extra[key]
	return state


func _stage_state() -> Dictionary:
	var result := {}
	for key in ["printer_manager", "character_manager", "background_manager", "effect_manager", "audio_manager", "camera_director", "choice_manager", "quick_menu_manager"]:
		var manager = managers.get(key)
		if manager != null and manager.has_method("get_state"):
			result[key.trim_suffix("_manager")] = manager.get_state()
	return result


func _current_line() -> int:
	if vm == null or vm.ast == null:
		return 0
	if vm.current_index < 0 or vm.current_index >= vm.ast.children.size():
		if not vm.transcript.is_empty():
			return int(vm.transcript.back().get("line", 0))
		return 0
	return int(vm.ast.children[vm.current_index].line)


func _source_line(line: int) -> String:
	if line <= 0:
		return ""
	var lines := source.split("\n", true)
	if line > lines.size():
		return ""
	return str(lines[line - 1])


func _has_runtime_errors() -> bool:
	return vm != null and vm.transcript.any(func(entry): return entry.get("type", "") == "error")
