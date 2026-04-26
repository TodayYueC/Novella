extends RefCounted

class_name NovellaTimelineModel

func build(ast: Variant) -> Dictionary:
	var events: Array = []
	if ast != null:
		_collect(ast.children, events, [], "")
	for i in range(events.size()):
		events[i]["order"] = i
	return {
		"events": events,
		"counts": _counts_for(events),
		"segments": _segments_for(events),
	}


func events_by_type(model: Dictionary, event_type: StringName) -> Array:
	var result: Array = []
	for event in model.get("events", []):
		if StringName(str(event.get("type", ""))) == event_type:
			result.append(event.duplicate(true))
	return result


func events_in_line_range(model: Dictionary, from_line: int, to_line: int) -> Array:
	var result: Array = []
	for event in model.get("events", []):
		var line := int(event.get("line", 0))
		if line >= from_line and line <= to_line:
			result.append(event.duplicate(true))
	return result


func _collect(nodes: Array, events: Array, branch_path: Array, current_label: String) -> void:
	var label := current_label
	for node in nodes:
		match node.kind:
			&"label":
				label = String(node.label_name)
				events.append(_event(&"label", node.line, label, {"label": label, "branch_path": branch_path.duplicate()}))
			&"dialogue":
				events.append(_event(&"dialogue", node.line, label, {"speaker": node.speaker, "text": node.text, "branch_path": branch_path.duplicate()}))
			&"narration":
				events.append(_event(&"narration", node.line, label, {"text": node.text, "branch_path": branch_path.duplicate()}))
			&"command":
				var category := _category_for_command(node.command_name)
				events.append(_event(category, node.line, label, {
					"command": String(node.command_name),
					"arguments": node.raw_arguments,
					"branch_path": branch_path.duplicate(),
				}))
			&"jump":
				events.append(_event(&"flow", node.line, label, {"kind": "jump", "target": String(node.target_label), "branch_path": branch_path.duplicate()}))
			&"call":
				events.append(_event(&"flow", node.line, label, {"kind": "call", "target": String(node.target_label), "branch_path": branch_path.duplicate()}))
			&"return":
				events.append(_event(&"flow", node.line, label, {"kind": "return", "branch_path": branch_path.duplicate()}))
			&"menu":
				events.append(_event(&"choice", node.line, label, {"choices": node.choices.size(), "branch_path": branch_path.duplicate()}))
				for choice_index in range(node.choices.size()):
					var choice = node.choices[choice_index]
					var next_path := branch_path.duplicate()
					next_path.append("choice:%s" % choice_index)
					events.append(_event(&"choice_option", choice.line, label, {
						"text": choice.text,
						"condition": choice.condition,
						"choice_index": choice_index,
						"branch_path": next_path.duplicate(),
					}))
					_collect(choice.actions, events, next_path, label)
			&"if":
				events.append(_event(&"branch", node.line, label, {"branches": node.branches.size(), "branch_path": branch_path.duplicate()}))
				for branch_index in range(node.branches.size()):
					var branch: Dictionary = node.branches[branch_index]
					var next_path := branch_path.duplicate()
					next_path.append("if:%s" % branch_index)
					_collect(branch.get("actions", []), events, next_path, label)


func _event(event_type: StringName, line: int, label: String, data: Dictionary) -> Dictionary:
	var payload := data.duplicate(true)
	payload["type"] = String(event_type)
	payload["line"] = line
	payload["label"] = label
	return payload


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
	if String(command_name).contains("save") or [&"load", &"quick_load", &"rollback", &"skip", &"auto", &"quick_menu", &"input"].has(command_name):
		return &"interaction"
	return &"command"


func _counts_for(events: Array) -> Dictionary:
	var counts: Dictionary = {}
	for event in events:
		var event_type := str(event.get("type", ""))
		counts[event_type] = int(counts.get(event_type, 0)) + 1
	return counts


func _segments_for(events: Array) -> Array:
	var segments: Array = []
	var current: Dictionary = {}
	for event in events:
		if event.get("type", "") == "label":
			if not current.is_empty():
				segments.append(current)
			current = {"label": event.get("label", ""), "start_line": event.get("line", 0), "event_count": 0}
		elif not current.is_empty():
			current["event_count"] = int(current.get("event_count", 0)) + 1
			current["end_line"] = event.get("line", current.get("start_line", 0))
	if not current.is_empty():
		segments.append(current)
	return segments
