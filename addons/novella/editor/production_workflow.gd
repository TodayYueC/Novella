extends RefCounted

class_name NovellaProductionWorkflow

const Parser := preload("res://addons/novella/script/parser.gd")
const CommandParser := preload("res://addons/novella/script/command_parser.gd")
const OutlineBuilder := preload("res://addons/novella/editor/script_outline_builder.gd")
const TimelineModel := preload("res://addons/novella/editor/timeline_model.gd")
const TimelineEditorModel := preload("res://addons/novella/editor/timeline_editor_model.gd")
const ScriptDiagnostics := preload("res://addons/novella/editor/script_diagnostics.gd")
const AssetIndex := preload("res://addons/novella/editor/asset_index.gd")
const ScriptLanguageService := preload("res://addons/novella/editor/script_language_service.gd")
const FlowGraphBuilder := preload("res://addons/novella/debug/flow_graph_builder.gd")
const LocalizationManager := preload("res://addons/novella/meta/localization_manager.gd")
const OnDemandAssetLoader := preload("res://addons/novella/performance/on_demand_asset_loader.gd")

var parser := Parser.new()
var command_parser := CommandParser.new()
var outline_builder := OutlineBuilder.new()
var timeline_model := TimelineModel.new()
var timeline_editor := TimelineEditorModel.new()
var diagnostics := ScriptDiagnostics.new()
var asset_index := AssetIndex.new()
var language_service := ScriptLanguageService.new()
var flow_graph_builder := FlowGraphBuilder.new()
var localization := LocalizationManager.new()
var asset_loader := OnDemandAssetLoader.new()
var current_asset_index: Dictionary = {}

func build_project_index(paths: Array) -> Dictionary:
	current_asset_index = asset_index.build(paths)
	return current_asset_index.duplicate(true)


func analyze_script(source: String, file_path: String = "", known_commands: Array = [], asset_paths: Array = []) -> Dictionary:
	var ast = parser.parse(source, file_path)
	var outline := outline_builder.build(ast)
	var timeline := timeline_model.build(ast)
	var diagnostic_report := diagnostics.analyze(ast, parser.errors, known_commands)
	var production_events := _events_from_ast(ast)
	if not asset_paths.is_empty():
		build_project_index(asset_paths)
	_register_translation_commands(production_events)
	var asset_report := _asset_report_for_events(production_events)
	var localization_report := _localization_report_for_events(production_events, file_path)
	return {
		"ok": not bool(diagnostic_report.get("has_errors", false)) and bool(asset_report.get("ok", true)),
		"file_path": file_path,
		"ast": ast,
		"outline": outline,
		"timeline": timeline,
		"events": production_events,
		"diagnostics": diagnostic_report,
		"assets": asset_report,
		"localization": localization_report,
	}


func create_timeline_session(source: String, file_path: String = "") -> Dictionary:
	var ast = parser.parse(source, file_path)
	var production_events := _events_from_ast(ast)
	timeline_editor.load_events(production_events)
	return {
		"ok": parser.errors.is_empty(),
		"file_path": file_path,
		"events": timeline_editor.get_events(),
		"errors": parser.errors.duplicate(),
		"script": timeline_editor.to_script(),
	}


func export_timeline_script(events: Array = []) -> String:
	return timeline_editor.to_script(events)


func roundtrip_script(source: String, file_path: String = "") -> Dictionary:
	var session := create_timeline_session(source, file_path)
	var exported := str(session.get("script", ""))
	var ast = parser.parse(exported, file_path)
	var diagnostic_report := diagnostics.analyze(ast, parser.errors, [])
	return {
		"ok": parser.errors.is_empty() and not bool(diagnostic_report.get("has_errors", false)),
		"source": source,
		"exported": exported,
		"errors": parser.errors.duplicate(),
		"diagnostics": diagnostic_report,
	}


func export_localization_template(sources: Array, locale: StringName = &"en") -> String:
	var entries: Array = []
	for source_value in sources:
		var source := ""
		var file_path := ""
		if source_value is Dictionary:
			source = str(source_value.get("source", ""))
			file_path = str(source_value.get("file_path", ""))
		else:
			source = str(source_value)
		var ast = parser.parse(source, file_path)
		var events := _events_from_ast(ast)
		_register_translation_commands(events)
		entries.append_array(_extract_localization_entries(events, file_path))
	return _entries_to_csv(entries, locale)


func import_localization_csv(locale: StringName, csv_text: String, replace: bool = false) -> Dictionary:
	return localization.import_csv(locale, csv_text, replace)


func preview_localized_source(source: String, locale: StringName, file_path: String = "") -> Dictionary:
	var ast = parser.parse(source, file_path)
	var events := _events_from_ast(ast)
	_register_translation_commands(events)
	var localized_events := _apply_locale_to_events(events, locale)
	return {
		"ok": parser.errors.is_empty(),
		"locale": String(locale),
		"events": localized_events,
		"script": timeline_editor.to_script(localized_events),
		"errors": parser.errors.duplicate(),
	}


func validate_asset_references(source: String, asset_paths: Array, file_path: String = "") -> Dictionary:
	build_project_index(asset_paths)
	var ast = parser.parse(source, file_path)
	return _asset_report_for_events(_events_from_ast(ast))


func language_report(source: String, file_path: String = "", known_commands: Array = [], asset_paths: Array = []) -> Dictionary:
	if not asset_paths.is_empty():
		build_project_index(asset_paths)
	return language_service.analyze(source, file_path, known_commands, current_asset_index)


func build_flow_graph(source: String, file_path: String = "") -> Dictionary:
	var ast = parser.parse(source, file_path)
	return flow_graph_builder.build(ast)


func build_asset_load_plan(source: String, asset_paths: Array, file_path: String = "", options: Dictionary = {}) -> Dictionary:
	build_project_index(asset_paths)
	var ast = parser.parse(source, file_path)
	var events := _events_from_ast(ast)
	return asset_loader.build_plan(events, current_asset_index, options)


func _events_from_ast(ast: Variant) -> Array:
	if ast == null:
		return []
	return _events_from_nodes(ast.children, "")


func _events_from_nodes(nodes: Array, current_label: String) -> Array:
	var events: Array = []
	var label := current_label
	for node in nodes:
		var event := _event_from_node(node, label)
		if node.kind == &"label":
			label = String(node.label_name)
		if not event.is_empty():
			events.append(event)
	return events


func _event_from_node(node: Variant, current_label: String) -> Dictionary:
	match node.kind:
		&"label":
			return {"type": "label", "line": node.line, "label": String(node.label_name)}
		&"dialogue":
			return {"type": "dialogue", "line": node.line, "label": current_label, "speaker": node.speaker, "text": node.text}
		&"narration":
			return {"type": "narration", "line": node.line, "label": current_label, "text": node.text}
		&"command":
			return _event_from_command(node, current_label)
		&"jump":
			return {"type": "flow", "kind": "jump", "target": String(node.target_label), "line": node.line, "label": current_label}
		&"call":
			return {"type": "flow", "kind": "call", "target": String(node.target_label), "line": node.line, "label": current_label}
		&"return":
			return {"type": "flow", "kind": "return", "line": node.line, "label": current_label}
		&"break":
			return {"type": "flow", "kind": "break", "line": node.line, "label": current_label}
		&"continue":
			return {"type": "flow", "kind": "continue", "line": node.line, "label": current_label}
		&"menu":
			return _event_from_menu(node, current_label)
		&"if":
			return _event_from_if(node, current_label)
		&"while":
			return {
				"type": "while",
				"line": node.line,
				"label": current_label,
				"condition": node.condition,
				"children": _events_from_nodes(node.actions, current_label),
			}
	return {}


func _event_from_menu(node: Variant, current_label: String) -> Dictionary:
	var choices: Array = []
	for choice in node.choices:
		choices.append({
			"type": "choice",
			"line": choice.line,
			"label": current_label,
			"text": choice.text,
			"condition": choice.condition,
			"children": _events_from_nodes(choice.actions, current_label),
		})
	return {"type": "menu", "line": node.line, "label": current_label, "choices": choices}


func _event_from_if(node: Variant, current_label: String) -> Dictionary:
	var branches: Array = []
	for branch in node.branches:
		branches.append({
			"line": int(branch.get("line", node.line)),
			"condition": str(branch.get("condition", "")),
			"children": _events_from_nodes(branch.get("actions", []), current_label),
		})
	return {"type": "if", "line": node.line, "label": current_label, "branches": branches}


func _event_from_command(node: Variant, current_label: String) -> Dictionary:
	var command_name := String(node.command_name)
	var event := {
		"type": String(_category_for_command(node.command_name)),
		"line": node.line,
		"label": current_label,
		"command": command_name,
		"arguments": node.raw_arguments,
	}
	var asset_id := _asset_id_from_argument(node.command_name, node.raw_arguments)
	if not asset_id.is_empty():
		event["id"] = asset_id
	return event


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


func _asset_report_for_events(events: Array) -> Dictionary:
	var references: Array = []
	_collect_asset_references(events, references)
	return asset_index.validate_references(current_asset_index, references)


func _collect_asset_references(events: Array, references: Array) -> void:
	for event_value in events:
		if not event_value is Dictionary:
			continue
		var event: Dictionary = event_value
		var reference := _asset_reference_for_event(event)
		if not reference.is_empty():
			references.append(reference)
		if event.has("children"):
			_collect_asset_references(event["children"], references)
		if event.has("choices"):
			_collect_asset_references(event["choices"], references)
		if event.has("branches"):
			for branch in event["branches"]:
				if branch is Dictionary and branch.has("children"):
					_collect_asset_references(branch["children"], references)


func _asset_reference_for_event(event: Dictionary) -> Dictionary:
	var command_name := StringName(str(event.get("command", "")))
	var asset_id := str(event.get("id", _asset_id_from_argument(command_name, str(event.get("arguments", "")))))
	if asset_id.is_empty():
		return {}
	var categories := _asset_categories_for_command(command_name)
	if categories.is_empty():
		return {}
	return {
		"id": asset_id,
		"categories": categories,
		"command": String(command_name),
		"line": int(event.get("line", 0)),
	}


func _asset_categories_for_command(command_name: StringName) -> Array:
	if [&"bg", &"scene"].has(command_name):
		return ["backgrounds"]
	if [&"char", &"char_emotion", &"char_move", &"char_remove"].has(command_name):
		return ["characters"]
	if [&"play_music", &"play_se", &"play_voice", &"ambience"].has(command_name):
		return ["audio"]
	if [&"gallery", &"replay"].has(command_name):
		return ["backgrounds", "characters", "other"]
	return []


func _asset_id_from_argument(command_name: StringName, raw_arguments: String) -> String:
	var parsed := command_parser.parse_arguments(raw_arguments)
	var positional: Array = parsed.get("positional", [])
	var named: Dictionary = parsed.get("named", {})
	if [&"bg", &"scene", &"char", &"char_emotion", &"char_move", &"char_remove", &"play_music", &"play_se", &"play_voice", &"ambience"].has(command_name):
		if not positional.is_empty():
			return _clean_text(str(positional[0]))
	if [&"gallery", &"replay"].has(command_name) and named.has(&"asset"):
		return _clean_text(str(named[&"asset"])).get_file().get_basename()
	return ""


func _localization_report_for_events(events: Array, file_path: String) -> Dictionary:
	var entries := _extract_localization_entries(events, file_path)
	var keys: Array = []
	for entry in entries:
		var key := str(entry.get("key", ""))
		if not key.is_empty() and not keys.has(key):
			keys.append(key)
	keys.sort()
	return {
		"entries": entries,
		"keys": keys,
		"coverage": localization.coverage_report(keys),
	}


func _extract_localization_entries(events: Array, file_path: String) -> Array:
	var entries: Array = []
	var seen: Dictionary = {}
	_collect_localization_entries(events, file_path, entries, seen)
	return entries


func _collect_localization_entries(events: Array, file_path: String, entries: Array, seen: Dictionary) -> void:
	for event_value in events:
		if not event_value is Dictionary:
			continue
		var event: Dictionary = event_value
		var entry := _localization_entry_for_event(event, file_path)
		if not entry.is_empty() and not seen.has(entry["key"]):
			seen[entry["key"]] = true
			entries.append(entry)
		if event.has("children"):
			_collect_localization_entries(event["children"], file_path, entries, seen)
		if event.has("choices"):
			_collect_localization_entries(event["choices"], file_path, entries, seen)
		if event.has("branches"):
			for branch in event["branches"]:
				if branch is Dictionary and branch.has("children"):
					_collect_localization_entries(branch["children"], file_path, entries, seen)


func _localization_entry_for_event(event: Dictionary, file_path: String) -> Dictionary:
	if event.get("command", "") == "translation":
		var parsed := command_parser.parse_arguments(str(event.get("arguments", "")))
		var positional: Array = parsed.get("positional", [])
		var named: Dictionary = parsed.get("named", {})
		var key := str(positional[1] if positional.size() > 1 else named.get(&"key", "")).strip_edges()
		if key.is_empty():
			return {}
		return {
			"key": key,
			"original": _clean_text(str(named.get(&"text", positional[2] if positional.size() > 2 else ""))),
			"source": file_path,
			"line": int(event.get("line", 0)),
			"kind": "translation",
		}
	if not ["dialogue", "narration", "choice"].has(str(event.get("type", ""))):
		return {}
	var text := str(event.get("text", "")).strip_edges()
	if text.is_empty():
		return {}
	var key := _localization_key_for_event(event, file_path)
	return {
		"key": key,
		"original": text,
		"source": file_path,
		"line": int(event.get("line", 0)),
		"kind": str(event.get("type", "")),
	}


func _localization_key_for_event(event: Dictionary, file_path: String) -> String:
	var text := str(event.get("text", "")).strip_edges()
	if text.begins_with("$"):
		return text.substr(1).strip_edges()
	if text.begins_with("tr:"):
		return text.substr(3).strip_edges()
	var basename := file_path.get_file().get_basename()
	if basename.is_empty():
		basename = "script"
	return "%s.%s.%s" % [basename, str(event.get("type", "text")), int(event.get("line", 0))]


func _register_translation_commands(events: Array) -> void:
	for event_value in events:
		if not event_value is Dictionary:
			continue
		var event: Dictionary = event_value
		if event.get("command", "") == "translation":
			var parsed := command_parser.parse_arguments(str(event.get("arguments", "")))
			var positional: Array = parsed.get("positional", [])
			var named: Dictionary = parsed.get("named", {})
			var locale := StringName(str(positional[0] if positional.size() > 0 else named.get(&"locale", localization.default_locale)))
			var key := StringName(str(positional[1] if positional.size() > 1 else named.get(&"key", "")))
			var text := _clean_text(str(named.get(&"text", positional[2] if positional.size() > 2 else "")))
			if key != &"":
				localization.add_translation(locale, key, text)
		if event.has("children"):
			_register_translation_commands(event["children"])
		if event.has("choices"):
			_register_translation_commands(event["choices"])
		if event.has("branches"):
			for branch in event["branches"]:
				if branch is Dictionary and branch.has("children"):
					_register_translation_commands(branch["children"])


func _apply_locale_to_events(events: Array, locale: StringName) -> Array:
	localization.set_locale(locale)
	var localized: Array = []
	for event_value in events:
		if not event_value is Dictionary:
			continue
		localized.append(_apply_locale_to_event(event_value, locale))
	return localized


func _apply_locale_to_event(event: Dictionary, locale: StringName) -> Dictionary:
	var copy := event.duplicate(true)
	if copy.has("text"):
		var text := str(copy["text"])
		if text.begins_with("$") or text.begins_with("tr:") or localization.has_translation(StringName(text), locale):
			copy["text"] = localization.localize_text(text)
	if copy.has("children"):
		copy["children"] = _apply_locale_to_events(copy["children"], locale)
	if copy.has("choices"):
		copy["choices"] = _apply_locale_to_events(copy["choices"], locale)
	if copy.has("branches"):
		var branches: Array = []
		for branch_value in copy["branches"]:
			if branch_value is Dictionary:
				var branch: Dictionary = branch_value.duplicate(true)
				if branch.has("children"):
					branch["children"] = _apply_locale_to_events(branch["children"], locale)
				branches.append(branch)
		copy["branches"] = branches
	return copy


func _entries_to_csv(entries: Array, locale: StringName) -> String:
	var seen: Dictionary = {}
	var lines := ["key,text,source,line,kind,original"]
	for entry_value in entries:
		if not entry_value is Dictionary:
			continue
		var entry: Dictionary = entry_value
		var key := str(entry.get("key", ""))
		if key.is_empty() or seen.has(key):
			continue
		seen[key] = true
		var text := ""
		if localization.has_translation(StringName(key), locale):
			text = localization.translate(StringName(key), {}, locale)
		else:
			text = _clean_text(str(entry.get("original", "")))
		lines.append("%s,%s,%s,%s,%s,%s" % [
			_csv_escape(key),
			_csv_escape(text),
			_csv_escape(str(entry.get("source", ""))),
			int(entry.get("line", 0)),
			_csv_escape(str(entry.get("kind", ""))),
			_csv_escape(_clean_text(str(entry.get("original", "")))),
		])
	return "\n".join(lines)


func _csv_escape(value: String) -> String:
	if value.contains("\"") or value.contains(",") or value.contains("\n") or value.contains("\r"):
		return "\"%s\"" % value.replace("\"", "\"\"")
	return value


func _clean_text(value: String) -> String:
	var text := value.strip_edges()
	if text.begins_with("\"") and text.ends_with("\"") and text.length() >= 2:
		return text.substr(1, text.length() - 2).replace("\\\"", "\"")
	return text
