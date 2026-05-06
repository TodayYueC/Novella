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
	_dock.new_script_requested.connect(_on_new_script_requested)
	_dock.save_requested.connect(_on_save_requested)
	_dock.visual_event_added.connect(_on_visual_event_added)
	_dock.visual_event_updated.connect(_on_visual_event_updated)
	_dock.visual_event_moved.connect(_on_visual_event_moved)
	_dock.visual_event_duplicated.connect(_on_visual_event_duplicated)
	_dock.visual_event_deleted.connect(_on_visual_event_deleted)
	_dock.visual_events_copied.connect(_on_visual_events_copied)
	_dock.visual_events_pasted.connect(_on_visual_events_pasted)
	_dock.visual_undo_requested.connect(_on_visual_undo_requested)
	_dock.visual_redo_requested.connect(_on_visual_redo_requested)
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
	if bool(analysis.get("ok", false)):
		_dock.apply_visual_state(_controller.open_visual_file(path, commands))


func _on_template_requested(template_id: StringName) -> void:
	if _controller == null:
		return
	DisplayServer.clipboard_set(_controller.create_template(template_id))


func _on_new_script_requested(path: String) -> void:
	if _dock == null or _controller == null:
		return
	_dock.apply_visual_state(_controller.new_visual_script(path))


func _on_save_requested(path: String) -> void:
	if _dock == null or _controller == null:
		return
	_dock.apply_visual_state(_controller.visual_save(path, _known_commands()))


func _on_visual_event_added(event_type: StringName, form: Dictionary) -> void:
	if _dock == null or _controller == null:
		return
	_dock.apply_visual_state(_controller.visual_add_event(event_type, form, -1, _known_commands()))


func _on_visual_event_updated(index: int, form: Dictionary) -> void:
	if _dock == null or _controller == null:
		return
	_dock.apply_visual_state(_controller.visual_update_event(index, form, _known_commands()))


func _on_visual_event_moved(from_index: int, to_index: int) -> void:
	if _dock == null or _controller == null:
		return
	_dock.apply_visual_state(_controller.visual_move_event(from_index, to_index, _known_commands()))


func _on_visual_event_duplicated(index: int) -> void:
	if _dock == null or _controller == null:
		return
	_dock.apply_visual_state(_controller.visual_duplicate_event(index, _known_commands()))


func _on_visual_event_deleted(index: int) -> void:
	if _dock == null or _controller == null:
		return
	_dock.apply_visual_state(_controller.visual_delete_event(index, _known_commands()))


func _on_visual_events_copied(indices: Array) -> void:
	if _dock == null or _controller == null:
		return
	_dock.apply_visual_state(_controller.visual_copy_events(indices))


func _on_visual_events_pasted(index: int) -> void:
	if _dock == null or _controller == null:
		return
	_dock.apply_visual_state(_controller.visual_paste_events(index, _known_commands()))


func _on_visual_undo_requested() -> void:
	if _dock == null or _controller == null:
		return
	_dock.apply_visual_state(_controller.visual_undo(_known_commands()))


func _on_visual_redo_requested() -> void:
	if _dock == null or _controller == null:
		return
	_dock.apply_visual_state(_controller.visual_redo(_known_commands()))


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
		&"backlog_clear", &"choice_timeout", &"quick_menu", &"settings", &"config", &"input",
		&"locale", &"language", &"translation", &"tr_var",
		&"gallery", &"replay", &"achievement", &"achieve", &"meta_check",
	]
