extends RefCounted

class_name NovellaSkipManager

signal skip_mode_changed(mode: StringName)
signal line_marked_read(line_id: String)

var mode: StringName = &"off"
var prevented: bool = false
var read_lines: Dictionary = {}

func start_skip(skip_mode: StringName = &"read") -> Dictionary:
	if prevented:
		return {"ok": false, "prevented": true, "mode": String(mode)}
	if not [&"read", &"all"].has(skip_mode):
		return {"ok": false, "error": "Unknown skip mode '%s'." % skip_mode}
	mode = skip_mode
	skip_mode_changed.emit(mode)
	return {"ok": true, "mode": String(mode)}


func stop_skip() -> Dictionary:
	mode = &"off"
	skip_mode_changed.emit(mode)
	return {"ok": true, "mode": String(mode)}


func prevent_skip() -> void:
	prevented = true
	stop_skip()


func allow_skip() -> void:
	prevented = false


func mark_read(line_id: Variant) -> void:
	var key := str(line_id)
	if key.is_empty():
		return
	read_lines[key] = true
	line_marked_read.emit(key)


func is_read(line_id: Variant) -> bool:
	return read_lines.has(str(line_id))


func should_skip(line_id: Variant, unread: bool = false) -> bool:
	if prevented or mode == &"off":
		return false
	if mode == &"all":
		return true
	return not unread and is_read(line_id)


func get_state() -> Dictionary:
	return {
		"mode": String(mode),
		"prevented": prevented,
		"read_lines": read_lines.duplicate(true),
	}


func restore_state(state: Dictionary) -> void:
	mode = StringName(str(state.get("mode", String(mode))))
	prevented = _as_bool(state.get("prevented", prevented))
	read_lines = state.get("read_lines", {}).duplicate(true)


func _as_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var text := str(value).strip_edges().to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"
