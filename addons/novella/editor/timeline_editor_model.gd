extends RefCounted

class_name NovellaTimelineEditorModel

signal changed(events: Array)

var events: Array = []
var undo_stack: Array = []
var redo_stack: Array = []
var max_history: int = 64

func load_events(source_events: Array) -> void:
	_push_history()
	events = _normalize_events(source_events.duplicate(true))
	_normalize_orders()
	redo_stack.clear()
	changed.emit(events.duplicate(true))


func add_event(event_type: StringName, data: Dictionary = {}, index: int = -1) -> Dictionary:
	_push_history()
	var event := data.duplicate(true)
	event["type"] = String(event_type)
	if not event.has("line"):
		event["line"] = 0
	if index < 0 or index > events.size():
		events.append(event)
	else:
		events.insert(index, event)
	_normalize_orders()
	redo_stack.clear()
	changed.emit(events.duplicate(true))
	return event.duplicate(true)


func update_event(index: int, patch: Dictionary) -> Dictionary:
	if index < 0 or index >= events.size():
		return {"ok": false, "error": "Event index out of range."}
	_push_history()
	for key in patch:
		events[index][key] = patch[key]
	redo_stack.clear()
	changed.emit(events.duplicate(true))
	var result: Dictionary = events[index].duplicate(true)
	result["ok"] = true
	return result


func move_event(from_index: int, to_index: int) -> Dictionary:
	if from_index < 0 or from_index >= events.size():
		return {"ok": false, "error": "Source event index out of range."}
	var target: int = clampi(to_index, 0, events.size() - 1)
	if from_index == target:
		return {"ok": true, "moved": false, "index": from_index}
	_push_history()
	var event: Dictionary = events[from_index]
	events.remove_at(from_index)
	events.insert(target, event)
	_normalize_orders()
	redo_stack.clear()
	changed.emit(events.duplicate(true))
	return {"ok": true, "moved": true, "from": from_index, "to": target}


func duplicate_event(index: int) -> Dictionary:
	if index < 0 or index >= events.size():
		return {"ok": false, "error": "Event index out of range."}
	_push_history()
	var copy: Dictionary = events[index].duplicate(true)
	copy["line"] = int(copy.get("line", 0)) + 1
	events.insert(index + 1, copy)
	_normalize_orders()
	redo_stack.clear()
	changed.emit(events.duplicate(true))
	copy["ok"] = true
	return copy


func delete_event(index: int) -> Dictionary:
	if index < 0 or index >= events.size():
		return {"ok": false, "error": "Event index out of range."}
	_push_history()
	var removed: Dictionary = events[index]
	events.remove_at(index)
	_normalize_orders()
	redo_stack.clear()
	changed.emit(events.duplicate(true))
	return {"ok": true, "removed": removed.duplicate(true)}


func undo() -> Dictionary:
	if undo_stack.is_empty():
		return {"ok": false, "empty": true}
	redo_stack.append(events.duplicate(true))
	events = undo_stack.pop_back()
	_normalize_orders()
	changed.emit(events.duplicate(true))
	return {"ok": true, "events": events.duplicate(true)}


func redo() -> Dictionary:
	if redo_stack.is_empty():
		return {"ok": false, "empty": true}
	undo_stack.append(events.duplicate(true))
	events = redo_stack.pop_back()
	_normalize_orders()
	changed.emit(events.duplicate(true))
	return {"ok": true, "events": events.duplicate(true)}


func find_events(query: String, fields: Array = ["speaker", "text", "command", "arguments", "label", "id"]) -> Array:
	var needle := query.to_lower()
	var result: Array = []
	_find_events_recursive(events, needle, fields, [], result)
	return result


func replace_text(query: String, replacement: String, fields: Array = ["text", "arguments"]) -> Dictionary:
	if query.is_empty():
		return {"ok": false, "error": "Query cannot be empty.", "replaced": 0}
	_push_history()
	var replaced := _replace_text_recursive(events, query, replacement, fields)
	if replaced == 0:
		undo_stack.pop_back()
	else:
		_normalize_orders()
		redo_stack.clear()
		changed.emit(events.duplicate(true))
	return {"ok": true, "replaced": replaced, "events": events.duplicate(true)}


func filter_events(filter: Dictionary) -> Array:
	var result: Array = []
	_filter_events_recursive(events, filter, [], result)
	return result


func to_script(events_override: Array = []) -> String:
	var source_events := events if events_override.is_empty() else events_override
	return _events_to_script(source_events, 0)


func get_events() -> Array:
	return events.duplicate(true)


func _push_history() -> void:
	undo_stack.append(events.duplicate(true))
	while undo_stack.size() > max_history:
		undo_stack.pop_front()


func _normalize_orders() -> void:
	for index in range(events.size()):
		events[index]["order"] = index


func _event_to_script(event: Dictionary) -> String:
	match str(event.get("type", "")):
		"label":
			return "label %s:" % str(event.get("label", "start"))
		"dialogue":
			return "%s: %s" % [str(event.get("speaker", "Narrator")), str(event.get("text", ""))]
		"narration":
			return str(event.get("text", ""))
		"background":
			return ("@bg %s %s" % [str(event.get("id", event.get("arguments", ""))), str(event.get("options", ""))]).strip_edges()
		"character":
			return ("@char %s %s" % [str(event.get("id", event.get("arguments", ""))), str(event.get("options", ""))]).strip_edges()
		"audio":
			var audio_command := str(event.get("command", "play_music"))
			return ("@%s %s" % [audio_command, str(event.get("arguments", event.get("id", "")))]).strip_edges()
		"command", "printer", "interaction", "meta", "effect", "camera":
			return "@%s %s" % [str(event.get("command", "wait")), str(event.get("arguments", ""))]
		"flow":
			var kind := str(event.get("kind", "jump"))
			if kind == "return":
				return "return"
			if kind == "break":
				return "break"
			if kind == "continue":
				return "continue"
			return "%s %s" % [kind, str(event.get("target", ""))]
		"choice_option":
			var condition := str(event.get("condition", ""))
			var line := "\"%s\"" % str(event.get("text", "Choice"))
			if not condition.is_empty():
				line += " if %s" % condition
			return "%s:" % line
		"break":
			return "break"
		"continue":
			return "continue"
		_:
			return ""


func _events_to_script(source_events: Array, indent: int) -> String:
	var lines: Array[String] = []
	for event_value in source_events:
		if not event_value is Dictionary:
			continue
		_append_event_script(event_value, indent, lines)
	return "\n".join(lines)


func _append_event_script(event: Dictionary, indent: int, lines: Array[String]) -> void:
	var event_type := str(event.get("type", ""))
	match event_type:
		"menu":
			lines.append("%smenu:" % _indent_text(indent))
			var choices: Array = event.get("choices", [])
			for choice_value in choices:
				if not choice_value is Dictionary:
					continue
				var choice: Dictionary = choice_value
				var condition := str(choice.get("condition", ""))
				var choice_line := "\"%s\"" % str(choice.get("text", "Choice"))
				if not condition.is_empty():
					choice_line += " if %s" % condition
				lines.append("%s%s:" % [_indent_text(indent + 1), choice_line])
				_append_nested_events(choice, indent + 2, lines)
		"choice":
			var condition := str(event.get("condition", ""))
			var choice_line := "\"%s\"" % str(event.get("text", "Choice"))
			if not condition.is_empty():
				choice_line += " if %s" % condition
			lines.append("%s%s:" % [_indent_text(indent), choice_line])
			_append_nested_events(event, indent + 1, lines)
		"if":
			var branches: Array = event.get("branches", [])
			for branch_index in range(branches.size()):
				var branch: Dictionary = branches[branch_index]
				var condition := str(branch.get("condition", ""))
				if branch_index == 0:
					lines.append("%sif %s:" % [_indent_text(indent), condition])
				elif condition.is_empty():
					lines.append("%selse:" % _indent_text(indent))
				else:
					lines.append("%selif %s:" % [_indent_text(indent), condition])
				_append_nested_events(branch, indent + 1, lines)
		"while":
			lines.append("%swhile %s:" % [_indent_text(indent), str(event.get("condition", ""))])
			_append_nested_events(event, indent + 1, lines)
			lines.append("%sendwhile" % _indent_text(indent))
		_:
			var rendered := _event_to_script(event)
			if not rendered.is_empty():
				lines.append("%s%s" % [_indent_text(indent), rendered])
			_append_nested_events(event, indent + 1, lines)


func _append_nested_events(container: Dictionary, indent: int, lines: Array[String]) -> void:
	var nested: Array = []
	if container.has("children"):
		nested = container.get("children", [])
	elif container.has("actions"):
		nested = container.get("actions", [])
	if nested.is_empty():
		return
	var nested_script := _events_to_script(nested, indent)
	if nested_script.is_empty():
		return
	for line in nested_script.split("\n", false):
		lines.append(line)


func _indent_text(indent: int) -> String:
	return "    ".repeat(maxi(indent, 0))


func _normalize_events(source_events: Array) -> Array:
	var normalized: Array = []
	for event_value in source_events:
		if not event_value is Dictionary:
			continue
		var event: Dictionary = event_value.duplicate(true)
		if not event.has("line"):
			event["line"] = 0
		if event.has("children"):
			event["children"] = _normalize_events(event["children"])
		if event.has("actions"):
			event["actions"] = _normalize_events(event["actions"])
		if event.has("choices"):
			var choices: Array = []
			for choice_value in event["choices"]:
				if choice_value is Dictionary:
					var choice: Dictionary = choice_value.duplicate(true)
					if not choice.has("type"):
						choice["type"] = "choice"
					if choice.has("children"):
						choice["children"] = _normalize_events(choice["children"])
					if choice.has("actions"):
						choice["actions"] = _normalize_events(choice["actions"])
					choices.append(choice)
			event["choices"] = choices
		if event.has("branches"):
			var branches: Array = []
			for branch_value in event["branches"]:
				if branch_value is Dictionary:
					var branch: Dictionary = branch_value.duplicate(true)
					if branch.has("children"):
						branch["children"] = _normalize_events(branch["children"])
					if branch.has("actions"):
						branch["actions"] = _normalize_events(branch["actions"])
					branches.append(branch)
			event["branches"] = branches
		normalized.append(event)
	return normalized


func _find_events_recursive(source_events: Array, needle: String, fields: Array, path: Array, result: Array) -> void:
	for index in range(source_events.size()):
		var event: Dictionary = source_events[index]
		if _event_matches_query(event, needle, fields):
			var copy := event.duplicate(true)
			copy["path"] = path + [index]
			result.append(copy)
		_walk_nested_events(event, Callable(self, "_find_events_recursive").bind(needle, fields, path + [index], result))


func _event_matches_query(event: Dictionary, needle: String, fields: Array) -> bool:
	if needle.is_empty():
		return true
	for field in fields:
		if str(event.get(field, "")).to_lower().contains(needle):
			return true
	return false


func _replace_text_recursive(source_events: Array, query: String, replacement: String, fields: Array) -> int:
	var replaced := 0
	for event in source_events:
		for field in fields:
			if event.has(field) and event[field] is String:
				var before := str(event[field])
				var after := before.replace(query, replacement)
				if after != before:
					event[field] = after
					replaced += 1
		replaced += _replace_nested_text(event, query, replacement, fields)
	return replaced


func _replace_nested_text(event: Dictionary, query: String, replacement: String, fields: Array) -> int:
	var replaced := 0
	if event.has("children"):
		replaced += _replace_text_recursive(event["children"], query, replacement, fields)
	if event.has("actions"):
		replaced += _replace_text_recursive(event["actions"], query, replacement, fields)
	if event.has("choices"):
		replaced += _replace_text_recursive(event["choices"], query, replacement, fields)
	if event.has("branches"):
		for branch in event["branches"]:
			if branch is Dictionary:
				if branch.has("children"):
					replaced += _replace_text_recursive(branch["children"], query, replacement, fields)
				if branch.has("actions"):
					replaced += _replace_text_recursive(branch["actions"], query, replacement, fields)
	return replaced


func _filter_events_recursive(source_events: Array, filter: Dictionary, path: Array, result: Array) -> void:
	for index in range(source_events.size()):
		var event: Dictionary = source_events[index]
		if _event_matches_filter(event, filter):
			var copy := event.duplicate(true)
			copy["path"] = path + [index]
			result.append(copy)
		_walk_nested_events(event, Callable(self, "_filter_events_recursive").bind(filter, path + [index], result))


func _event_matches_filter(event: Dictionary, filter: Dictionary) -> bool:
	for key in filter:
		var expected = filter[key]
		if expected is Array:
			if not expected.has(event.get(key)):
				return false
		elif event.get(key) != expected:
			return false
	return true


func _walk_nested_events(event: Dictionary, callback: Callable) -> void:
	if event.has("children"):
		callback.call(event["children"])
	if event.has("actions"):
		callback.call(event["actions"])
	if event.has("choices"):
		callback.call(event["choices"])
	if event.has("branches"):
		for branch in event["branches"]:
			if branch is Dictionary:
				if branch.has("children"):
					callback.call(branch["children"])
				if branch.has("actions"):
					callback.call(branch["actions"])
