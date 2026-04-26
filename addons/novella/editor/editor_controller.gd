extends RefCounted

class_name NovellaEditorController

const Parser := preload("res://addons/novella/script/parser.gd")
const OutlineBuilder := preload("res://addons/novella/editor/script_outline_builder.gd")
const TimelineModel := preload("res://addons/novella/editor/timeline_model.gd")
const Diagnostics := preload("res://addons/novella/editor/script_diagnostics.gd")
const TemplateLibrary := preload("res://addons/novella/editor/script_template_library.gd")
const AssetIndex := preload("res://addons/novella/editor/asset_index.gd")

var parser := Parser.new()
var outline_builder := OutlineBuilder.new()
var timeline_model := TimelineModel.new()
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
