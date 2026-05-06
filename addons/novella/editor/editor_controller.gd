extends RefCounted

class_name NovellaEditorController

const Parser := preload("res://addons/novella/script/parser.gd")
const OutlineBuilder := preload("res://addons/novella/editor/script_outline_builder.gd")
const TimelineModel := preload("res://addons/novella/editor/timeline_model.gd")
const TimelineEditorModel := preload("res://addons/novella/editor/timeline_editor_model.gd")
const VisualStoryEditorModel := preload("res://addons/novella/editor/visual_story_editor_model.gd")
const Diagnostics := preload("res://addons/novella/editor/script_diagnostics.gd")
const TemplateLibrary := preload("res://addons/novella/editor/script_template_library.gd")
const AssetIndex := preload("res://addons/novella/editor/asset_index.gd")

var parser := Parser.new()
var outline_builder := OutlineBuilder.new()
var timeline_model := TimelineModel.new()
var timeline_editor_model := TimelineEditorModel.new()
var visual_story_editor := VisualStoryEditorModel.new()
var diagnostics := Diagnostics.new()
var templates := TemplateLibrary.new()
var asset_index := AssetIndex.new()

func analyze_source(source: String, file_path: String = "", known_commands: Array = []) -> Dictionary:
	var ast = parser.parse(source, file_path)
	var outline := outline_builder.build(ast)
	var timeline := timeline_model.build(ast)
	var diagnostic_report := diagnostics.analyze(ast, parser.errors, known_commands)
	return {
		"ok": not bool(diagnostic_report.get("has_errors", false)),
		"file_path": file_path,
		"ast": ast,
		"outline": outline,
		"timeline": timeline,
		"diagnostics": diagnostic_report,
	}


func analyze_file(path: String, known_commands: Array = []) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "Script file '%s' was not found." % path}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not open script file '%s'." % path, "code": FileAccess.get_open_error()}
	return analyze_source(file.get_as_text(), path, known_commands)


func create_template(template_id: StringName, replacements: Dictionary = {}) -> String:
	return templates.render(template_id, replacements)


func index_assets(paths: Array) -> Dictionary:
	return asset_index.build(paths)


func open_visual_source(source: String, file_path: String = "", known_commands: Array = []) -> Dictionary:
	return visual_story_editor.load_source(source, file_path, known_commands)


func open_visual_file(path: String, known_commands: Array = []) -> Dictionary:
	return visual_story_editor.load_file(path, known_commands)


func new_visual_script(path: String = "") -> Dictionary:
	return visual_story_editor.new_script(path)


func visual_editor_state(known_commands: Array = []) -> Dictionary:
	return visual_story_editor.validate_current(known_commands)


func visual_add_event(event_type: StringName, form: Dictionary = {}, index: int = -1, known_commands: Array = []) -> Dictionary:
	visual_story_editor.add_event(event_type, form, index)
	return visual_story_editor.validate_current(known_commands)


func visual_update_event(index: int, form: Dictionary, known_commands: Array = []) -> Dictionary:
	visual_story_editor.update_event(index, form)
	return visual_story_editor.validate_current(known_commands)


func visual_move_event(from_index: int, to_index: int, known_commands: Array = []) -> Dictionary:
	visual_story_editor.move_event(from_index, to_index)
	return visual_story_editor.validate_current(known_commands)


func visual_duplicate_event(index: int, known_commands: Array = []) -> Dictionary:
	visual_story_editor.duplicate_event(index)
	return visual_story_editor.validate_current(known_commands)


func visual_delete_event(index: int, known_commands: Array = []) -> Dictionary:
	visual_story_editor.delete_event(index)
	return visual_story_editor.validate_current(known_commands)


func visual_copy_events(indices: Array) -> Dictionary:
	return visual_story_editor.copy_events(indices)


func visual_paste_events(index: int = -1, known_commands: Array = []) -> Dictionary:
	visual_story_editor.paste_events(index)
	return visual_story_editor.validate_current(known_commands)


func visual_undo(known_commands: Array = []) -> Dictionary:
	visual_story_editor.undo()
	return visual_story_editor.validate_current(known_commands)


func visual_redo(known_commands: Array = []) -> Dictionary:
	visual_story_editor.redo()
	return visual_story_editor.validate_current(known_commands)


func visual_save(path: String = "", known_commands: Array = []) -> Dictionary:
	var save_state := visual_story_editor.save_to_file(path)
	if bool(save_state.get("ok", false)):
		var state := visual_story_editor.validate_current(known_commands)
		state["save"] = save_state.get("save", {})
		return state
	return save_state
