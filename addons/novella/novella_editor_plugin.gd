@tool
extends EditorPlugin

const Compatibility := preload("res://addons/novella/core/compatibility.gd")
const EditorController := preload("res://addons/novella/editor/editor_controller.gd")
const EditorDockScene := preload("res://addons/novella/editor/ui/novella_editor_dock.tscn")

var _dock: Control
var _controller: EditorController

func _enter_tree() -> void:
	var result := Compatibility.check_engine_version()
	if not result["supported"]:
		push_warning(result["message"])
	_controller = EditorController.new()
	_dock = EditorDockScene.instantiate()
	_dock.name = "Novella"
	_dock.analyze_requested.connect(_on_analyze_requested)
	_dock.template_requested.connect(_on_template_requested)
	_dock.apply_templates(_controller.templates.list_templates())
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)


func _exit_tree() -> void:
	if _dock != null:
		remove_control_from_docks(_dock)
		_dock.queue_free()
		_dock = null
	_controller = null


func _on_analyze_requested(path: String) -> void:
	if _dock == null or _controller == null:
		return
	var commands := _known_commands()
	var analysis: Dictionary = _controller.analyze_file(path, commands)
	if not bool(analysis.get("ok", false)) and analysis.has("error"):
		analysis = {
			"file_path": path,
			"outline": {},
			"timeline": {},
			"diagnostics": {
				"issues": [{"severity": "error", "line": 0, "message": analysis["error"], "code": "file"}],
				"counts": {"error": 1, "warning": 0, "info": 0},
				"has_errors": true,
			},
		}
	_dock.apply_analysis(analysis)


func _on_template_requested(template_id: StringName) -> void:
	if _controller == null:
		return
	DisplayServer.clipboard_set(_controller.create_template(template_id))


func _known_commands() -> Array:
	return [
		&"var", &"set", &"flag", &"wait", &"mode", &"if", &"random", &"jump", &"call", &"return",
		&"char", &"char_remove", &"char_move", &"char_emotion", &"char_effect",
		&"bg", &"bg_remove", &"scene", &"env",
		&"play_music", &"stop_music", &"play_se", &"play_voice", &"stop_voice", &"ambience",
		&"camera", &"camera_shake", &"camera_reset",
		&"shake", &"flash", &"fade", &"effect", &"nvl_clear",
		&"save", &"load", &"quick_save", &"quick_load", &"auto_save",
		&"rollback", &"prevent_rollback", &"allow_rollback", &"fix_rollback",
		&"skip", &"prevent_skip", &"allow_skip",
		&"auto", &"prevent_auto", &"allow_auto",
		&"backlog_clear", &"choice_timeout", &"quick_menu", &"input",
		&"locale", &"language", &"translation", &"tr_var",
		&"gallery", &"replay", &"achievement", &"achieve", &"meta_check",
	]
