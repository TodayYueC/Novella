extends RefCounted

class_name NovellaTimelineEditorModel

signal changed(events: Array)

var events: Array = []
var undo_stack: Array = []
var redo_stack: Array = []
var max_history: int = 64

func load_events(source_events: Array) -> void:
	_push_history()
	events = source_events.duplicate(true)
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


func to_script() -> String:
	var lines: Array[String] = []
	for event in events:
		var rendered := _event_to_script(event)
		if not rendered.is_empty():
			lines.append(rendered)
	return "\n".join(lines)


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
			return "@play_music %s" % str(event.get("id", event.get("arguments", "")))
		"command", "printer", "interaction", "meta", "effect", "camera":
			return "@%s %s" % [str(event.get("command", "wait")), str(event.get("arguments", ""))]
		"flow":
			var kind := str(event.get("kind", "jump"))
			if kind == "return":
				return "return"
			return "%s %s" % [kind, str(event.get("target", ""))]
		_:
			return ""
