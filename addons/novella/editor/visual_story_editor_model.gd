extends RefCounted

class_name NovellaVisualStoryEditorModel

const Parser := preload("res://addons/novella/script/parser.gd")
const TimelineEditorModel := preload("res://addons/novella/editor/timeline_editor_model.gd")
const Diagnostics := preload("res://addons/novella/editor/script_diagnostics.gd")

var parser := Parser.new()
var timeline := TimelineEditorModel.new()
var diagnostics := Diagnostics.new()
var file_path: String = ""
var dirty: bool = false

func load_source(source: String, next_file_path: String = "", known_commands: Array = []) -> Dictionary:
	file_path = next_file_path
	var ast = parser.parse(source, file_path)
	timeline.load_events(_events_from_nodes(ast.children))
	timeline.undo_stack.clear()
	timeline.redo_stack.clear()
	dirty = false
	return validate_current(known_commands)


func load_file(path: String, known_commands: Array = []) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _error_state("Script file '%s' was not found." % path)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _error_state("Could not open script file '%s'." % path)
	return load_source(file.get_as_text(), path, known_commands)


func new_script(next_file_path: String = "") -> Dictionary:
	var starter := "label start:\n    Narrator: New Novella scene."
	return load_source(starter, next_file_path)


func add_event(event_type: StringName, form: Dictionary = {}, index: int = -1) -> Dictionary:
	var event := event_from_form(event_type, form)
	timeline.add_event(StringName(str(event.get("type", event_type))), event, index)
	dirty = true
	return editor_state()


func update_event(index: int, form: Dictionary) -> Dictionary:
	if index < 0 or index >= timeline.get_events().size():
		return _error_state("Event index out of range.")
	var events := timeline.get_events()
	var current: Dictionary = events[index]
	var event_type := StringName(str(form.get("type", current.get("type", "dialogue"))))
	var patch := event_from_form(event_type, form)
	patch["line"] = int(current.get("line", 0))
	var result := timeline.update_event(index, patch)
	dirty = dirty or bool(result.get("ok", false))
	return editor_state()


func move_event(from_index: int, to_index: int) -> Dictionary:
	var result := timeline.move_event(from_index, to_index)
	dirty = dirty or bool(result.get("moved", false))
	return editor_state()


func duplicate_event(index: int) -> Dictionary:
	var result := timeline.duplicate_event(index)
	dirty = dirty or bool(result.get("ok", false))
	return editor_state()


func delete_event(index: int) -> Dictionary:
	var result := timeline.delete_event(index)
	dirty = dirty or bool(result.get("ok", false))
	return editor_state()


func copy_events(indices: Array) -> Dictionary:
	var result := timeline.copy_events(indices)
	var state := editor_state()
	state["clipboard"] = result
	return state


func paste_events(index: int = -1) -> Dictionary:
	var result := timeline.paste_events(index)
	dirty = dirty or bool(result.get("ok", false))
	return editor_state()


func undo() -> Dictionary:
	var result := timeline.undo()
	dirty = dirty or bool(result.get("ok", false))
	return editor_state()


func redo() -> Dictionary:
	var result := timeline.redo()
	dirty = dirty or bool(result.get("ok", false))
	return editor_state()


func validate_current(known_commands: Array = []) -> Dictionary:
	var script := preview_script()
	var ast = parser.parse(script, file_path)
	var report := diagnostics.analyze(ast, parser.errors, known_commands)
	return editor_state(report)


func preview_script() -> String:
	return timeline.to_script()


func save_to_file(path: String = "") -> Dictionary:
	var target := _project_path(path if not path.strip_edges().is_empty() else file_path)
	if target.is_empty():
		return _error_state("Choose a .nvs file path before saving.")
	var directory_error := _ensure_parent_dir(target)
	if directory_error != OK:
		return _error_state("Could not create script directory for '%s'." % target)
	var file := FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		return _error_state("Could not write script file '%s'." % target)
	var script := preview_script()
	file.store_string(script)
	file.close()
	file_path = target
	dirty = false
	var state := validate_current()
	state["save"] = {"ok": true, "path": target}
	return state


func editor_state(report: Dictionary = {}) -> Dictionary:
	var diagnostics_report := report if not report.is_empty() else _empty_diagnostics()
	var script := preview_script()
	return {
		"ok": not bool(diagnostics_report.get("has_errors", false)),
		"file_path": file_path,
		"script": script,
		"source": script,
		"events": timeline.get_events(),
		"dirty": dirty,
		"diagnostics": diagnostics_report,
		"schemas": form_schemas(),
	}


func form_schemas() -> Dictionary:
	return {
		&"label": event_form_schema(&"label"),
		&"dialogue": event_form_schema(&"dialogue"),
		&"narration": event_form_schema(&"narration"),
		&"command": event_form_schema(&"command"),
		&"background": event_form_schema(&"background"),
		&"character": event_form_schema(&"character"),
		&"audio": event_form_schema(&"audio"),
		&"flow": event_form_schema(&"flow"),
		&"menu": event_form_schema(&"menu"),
	}


func event_form_schema(event_type: StringName) -> Dictionary:
	match event_type:
		&"label":
			return {"type": "label", "fields": ["label"]}
		&"dialogue":
			return {"type": "dialogue", "fields": ["speaker", "text"]}
		&"narration":
			return {"type": "narration", "fields": ["text"]}
		&"command":
			return {"type": "command", "fields": ["command", "arguments"]}
		&"background":
			return {"type": "background", "fields": ["command", "id", "arguments"]}
		&"character":
			return {"type": "character", "fields": ["command", "id", "arguments"]}
		&"audio":
			return {"type": "audio", "fields": ["command", "id", "arguments"]}
		&"flow":
			return {"type": "flow", "fields": ["kind", "target", "arguments"]}
		&"menu":
			return {"type": "menu", "fields": ["choices_text"]}
	return {"type": String(event_type), "fields": ["text"]}


func event_from_form(event_type: StringName, form: Dictionary = {}) -> Dictionary:
	match event_type:
		&"label":
			return {"type": "label", "label": _value(form, "label", _value(form, "id", "start"))}
		&"dialogue":
			return {
				"type": "dialogue",
				"speaker": _value(form, "speaker", "Narrator"),
				"text": _value(form, "text", "New line."),
			}
		&"narration":
			return {"type": "narration", "text": _value(form, "text", "New narration.")}
		&"command":
			return {
				"type": "command",
				"command": _value(form, "command", "wait"),
				"arguments": _value(form, "arguments", "0.5"),
			}
		&"background":
			return _command_form("background", "bg", form)
		&"character":
			return _command_form("character", "char", form)
		&"audio":
			return _command_form("audio", "play_music", form)
		&"flow":
			return {
				"type": "flow",
				"kind": _value(form, "kind", "jump"),
				"target": _value(form, "target", "start"),
				"arguments": _value(form, "arguments", ""),
			}
		&"menu":
			return {"type": "menu", "choices": _choices_from_form(form)}
	return {"type": String(event_type), "text": _value(form, "text", "")}


func _command_form(type_name: String, default_command: String, form: Dictionary) -> Dictionary:
	var command := _value(form, "command", default_command)
	var arguments := _value(form, "arguments", "")
	var id := _value(form, "id", "")
	if arguments.is_empty():
		arguments = id
	elif not id.is_empty() and not arguments.begins_with(id):
		arguments = "%s %s" % [id, arguments]
	return {"type": type_name, "command": command, "id": id, "arguments": arguments.strip_edges()}


func _choices_from_form(form: Dictionary) -> Array:
	var choices: Array = []
	var raw_choices = form.get("choices", [])
	if raw_choices is Array and not raw_choices.is_empty():
		for choice in raw_choices:
			if choice is Dictionary:
				choices.append(choice.duplicate(true))
	if choices.is_empty():
		choices = _parse_choices_text(_value(form, "choices_text", "Continue |  | next"))
	if choices.is_empty():
		choices.append({
			"type": "choice",
			"text": _value(form, "text", "Continue"),
			"condition": _value(form, "condition", ""),
			"actions": [{"type": "flow", "kind": "jump", "target": _value(form, "target", "next")}],
		})
	return choices


func _parse_choices_text(choices_text: String) -> Array:
	var choices: Array = []
	for raw_line in choices_text.replace("\r\n", "\n").replace("\r", "\n").split("\n", false):
		var line := str(raw_line).strip_edges()
		if line.is_empty():
			continue
		var parts := line.split("|", false)
		var choice_text := str(parts[0]).strip_edges()
		var condition := str(parts[1]).strip_edges() if parts.size() > 1 else ""
		var target := str(parts[2]).strip_edges() if parts.size() > 2 else ""
		var actions: Array = []
		if not target.is_empty():
			actions.append({"type": "flow", "kind": "jump", "target": target})
		choices.append({"type": "choice", "text": choice_text, "condition": condition, "actions": actions})
	return choices


func _events_from_nodes(nodes: Array) -> Array:
	var events: Array = []
	for node in nodes:
		events.append(_event_from_node(node))
	return events


func _event_from_node(node) -> Dictionary:
	match node.kind:
		&"label":
			return {"type": "label", "label": String(node.label_name), "line": node.line}
		&"dialogue":
			return {
				"type": "dialogue",
				"speaker": node.speaker,
				"text": node.text,
				"inline_commands": _inline_commands_from(node.inline_commands),
				"line": node.line,
			}
		&"narration":
			return {
				"type": "narration",
				"text": node.text,
				"inline_commands": _inline_commands_from(node.inline_commands),
				"line": node.line,
			}
		&"command":
			return _command_event(node.command_name, node.raw_arguments, node.line)
		&"jump":
			return {"type": "flow", "kind": "jump", "target": String(node.target_label), "line": node.line}
		&"call":
			return {
				"type": "flow",
				"kind": "call",
				"target": String(node.target_label),
				"arguments": _call_arguments_to_text(node.arguments),
				"line": node.line,
			}
		&"return":
			return {"type": "flow", "kind": "return", "line": node.line}
		&"break":
			return {"type": "break", "line": node.line}
		&"continue":
			return {"type": "continue", "line": node.line}
		&"menu":
			var choices: Array = []
			for choice in node.choices:
				choices.append({
					"type": "choice",
					"text": choice.text,
					"condition": choice.condition,
					"actions": _events_from_nodes(choice.actions),
					"line": choice.line,
				})
			return {"type": "menu", "choices": choices, "line": node.line}
		&"if":
			var branches: Array = []
			for branch in node.branches:
				branches.append({
					"condition": str(branch.get("condition", "")),
					"actions": _events_from_nodes(branch.get("actions", [])),
					"line": int(branch.get("line", node.line)),
				})
			return {"type": "if", "branches": branches, "line": node.line}
		&"while":
			return {
				"type": "while",
				"condition": node.condition,
				"actions": _events_from_nodes(node.actions),
				"line": node.line,
			}
	return {"type": String(node.kind), "line": node.line}


func _command_event(command_name: StringName, arguments: String, line: int) -> Dictionary:
	return {
		"type": String(_category_for_command(command_name)),
		"command": String(command_name),
		"arguments": arguments,
		"line": line,
	}


func _inline_commands_from(commands: Array) -> Array:
	var result: Array = []
	for command_node in commands:
		result.append({
			"command": String(command_node.command_name),
			"arguments": command_node.raw_arguments,
		})
	return result


func _call_arguments_to_text(arguments: Dictionary) -> String:
	var parts: Array[String] = []
	for key in arguments:
		parts.append("%s=%s" % [str(key), str(arguments[key])])
	return ", ".join(parts)


func _category_for_command(command_name: StringName) -> StringName:
	if [&"bg", &"bg_remove", &"scene", &"env"].has(command_name):
		return &"background"
	if [&"char", &"char_remove", &"char_move", &"char_emotion", &"char_effect"].has(command_name):
		return &"character"
	if [&"play_music", &"stop_music", &"play_se", &"play_voice", &"stop_voice", &"ambience"].has(command_name):
		return &"audio"
	if [&"camera", &"camera_shake", &"camera_reset"].has(command_name):
		return &"camera"
	if [&"shake", &"flash", &"fade", &"effect"].has(command_name):
		return &"effect"
	if [&"mode", &"nvl_clear"].has(command_name):
		return &"printer"
	if [&"locale", &"language", &"translation", &"tr_var", &"gallery", &"replay", &"achievement", &"achieve", &"meta_check"].has(command_name):
		return &"meta"
	if String(command_name).contains("save") or [&"load", &"quick_load", &"rollback", &"skip", &"auto", &"quick_menu", &"input"].has(command_name):
		return &"interaction"
	return &"command"


func _value(form: Dictionary, key: String, fallback: String) -> String:
	var value := str(form.get(key, fallback)).strip_edges()
	if value.is_empty() and not fallback.is_empty():
		return fallback
	return value


func _error_state(message: String) -> Dictionary:
	var report := {
		"issues": [{"severity": "error", "line": 0, "message": message, "code": "visual_editor"}],
		"counts": {"error": 1, "warning": 0, "info": 0},
		"has_errors": true,
	}
	var state := editor_state(report)
	state["error"] = message
	return state


func _empty_diagnostics() -> Dictionary:
	return {
		"issues": [],
		"counts": {"error": 0, "warning": 0, "info": 0},
		"has_errors": false,
	}


func _project_path(path: String) -> String:
	var normalized := path.strip_edges().replace("\\", "/")
	if normalized.is_empty() or normalized.contains("://") or normalized.is_absolute_path():
		return normalized
	return "res://%s" % normalized


func _ensure_parent_dir(path: String) -> Error:
	var base_dir := ProjectSettings.globalize_path(path).get_base_dir()
	if base_dir.is_empty() or DirAccess.dir_exists_absolute(base_dir):
		return OK
	return DirAccess.make_dir_recursive_absolute(base_dir)
