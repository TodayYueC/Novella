extends RefCounted

class_name NovellaSaveManager

signal save_written(slot: StringName, payload: Dictionary)
signal save_loaded(slot: StringName, payload: Dictionary)
signal save_deleted(slot: StringName)

const Constants := preload("res://addons/novella/core/constants.gd")
const SAVE_VERSION := Constants.VERSION

var save_dir: String = "user://novella/saves"
var use_memory_storage: bool = false
var quick_slot: StringName = &"quick"
var autosave_slot: StringName = &"auto"
var default_slot_prefix: String = "slot_"
var default_page_size: int = 6

var _memory_slots: Dictionary = {}

func configure(options: Dictionary = {}) -> void:
	if options.has("save_dir"):
		save_dir = str(options["save_dir"])
	if options.has("memory"):
		use_memory_storage = _as_bool(options["memory"])
	if options.has("quick_slot"):
		quick_slot = StringName(str(options["quick_slot"]))
	if options.has("autosave_slot"):
		autosave_slot = StringName(str(options["autosave_slot"]))
	if options.has("slot_prefix"):
		default_slot_prefix = str(options["slot_prefix"])
	if options.has("page_size"):
		default_page_size = max(1, int(options["page_size"]))


func enable_memory_storage(enabled: bool = true) -> void:
	use_memory_storage = enabled


func save_game(slot: StringName, state: Dictionary, metadata: Dictionary = {}) -> Dictionary:
	var payload := {
		"ok": true,
		"version": SAVE_VERSION,
		"slot": String(slot),
		"metadata": _build_metadata(metadata),
		"state": state.duplicate(true),
	}
	if use_memory_storage:
		_memory_slots[slot] = payload.duplicate(true)
	else:
		var write_result := _write_file(slot, payload)
		if not bool(write_result.get("ok", false)):
			return write_result
	save_written.emit(slot, payload.duplicate(true))
	return payload.duplicate(true)


func load_game(slot: StringName) -> Dictionary:
	var payload: Dictionary = {}
	if use_memory_storage:
		if not _memory_slots.has(slot):
			return {"ok": false, "error": "Save slot '%s' was not found." % slot}
		payload = _memory_slots[slot].duplicate(true)
	else:
		var read_result := _read_file(slot)
		if not bool(read_result.get("ok", false)):
			return read_result
		payload = read_result["payload"]
	payload["ok"] = true
	save_loaded.emit(slot, payload.duplicate(true))
	return payload.duplicate(true)


func delete_save(slot: StringName) -> Dictionary:
	if use_memory_storage:
		var removed := _memory_slots.erase(slot)
		if removed:
			save_deleted.emit(slot)
		return {"ok": true, "deleted": removed, "slot": String(slot)}
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {"ok": true, "deleted": false, "slot": String(slot)}
	var error := DirAccess.remove_absolute(path)
	if error != OK:
		return {"ok": false, "error": "Could not delete save '%s'." % slot, "code": error}
	save_deleted.emit(slot)
	return {"ok": true, "deleted": true, "slot": String(slot)}


func list_saves() -> Array:
	var result: Array = []
	if use_memory_storage:
		for slot in _memory_slots:
			var payload: Dictionary = _memory_slots[slot]
			result.append({
				"slot": String(slot),
				"version": payload.get("version", ""),
				"metadata": payload.get("metadata", {}).duplicate(true),
			})
		return result
	_ensure_save_dir()
	var dir := DirAccess.open(save_dir)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var slot_name := file_name.get_basename()
			var payload := load_game(StringName(slot_name))
			if bool(payload.get("ok", false)):
				result.append({
					"slot": slot_name,
					"version": payload.get("version", ""),
					"metadata": payload.get("metadata", {}).duplicate(true),
				})
		file_name = dir.get_next()
	dir.list_dir_end()
	return result


func list_slots(slot_count: int = 18, page: int = 0, page_size: int = -1, slot_prefix: String = "") -> Array:
	var size: int = default_page_size if page_size <= 0 else page_size
	var prefix: String = default_slot_prefix if slot_prefix.is_empty() else slot_prefix
	var safe_slot_count: int = max(0, slot_count)
	var safe_page: int = max(0, page)
	var start: int = safe_page * size
	var stop: int = min(start + size, safe_slot_count)
	var result: Array = []
	for index in range(start, stop):
		var slot_name := _numbered_slot_name(index, prefix)
		result.append(get_slot_summary(slot_name, index, safe_page))
	return result


func get_slot_summary(slot: StringName, index: int = -1, page: int = -1) -> Dictionary:
	var payload := _peek_slot(slot)
	var occupied := bool(payload.get("ok", false))
	var metadata: Dictionary = payload.get("metadata", {}).duplicate(true) if occupied else {}
	return {
		"slot": String(slot),
		"index": index,
		"page": page,
		"occupied": occupied,
		"version": str(payload.get("version", "")) if occupied else "",
		"metadata": metadata,
		"title": str(metadata.get("title", metadata.get("chapter", "Empty Slot" if not occupied else String(slot)))),
		"summary": str(metadata.get("summary", metadata.get("text", ""))),
		"thumbnail": str(metadata.get("thumbnail", "")),
		"saved_at": str(metadata.get("saved_at", "")),
	}


func quick_save(state: Dictionary, metadata: Dictionary = {}) -> Dictionary:
	return save_game(quick_slot, state, metadata)


func quick_load() -> Dictionary:
	return load_game(quick_slot)


func autosave(state: Dictionary, metadata: Dictionary = {}) -> Dictionary:
	return save_game(autosave_slot, state, metadata)


func get_state() -> Dictionary:
	return {
		"save_dir": save_dir,
		"use_memory_storage": use_memory_storage,
		"quick_slot": String(quick_slot),
		"autosave_slot": String(autosave_slot),
		"default_slot_prefix": default_slot_prefix,
		"default_page_size": default_page_size,
		"memory_slots": _memory_slots.duplicate(true),
	}


func restore_state(state: Dictionary) -> void:
	save_dir = str(state.get("save_dir", save_dir))
	use_memory_storage = _as_bool(state.get("use_memory_storage", use_memory_storage))
	quick_slot = StringName(str(state.get("quick_slot", String(quick_slot))))
	autosave_slot = StringName(str(state.get("autosave_slot", String(autosave_slot))))
	default_slot_prefix = str(state.get("default_slot_prefix", default_slot_prefix))
	default_page_size = max(1, int(state.get("default_page_size", default_page_size)))
	_memory_slots = state.get("memory_slots", {}).duplicate(true)


func _build_metadata(metadata: Dictionary) -> Dictionary:
	var result := metadata.duplicate(true)
	if not result.has("saved_at"):
		result["saved_at"] = Time.get_datetime_string_from_system(false, true)
	return result


func _write_file(slot: StringName, payload: Dictionary) -> Dictionary:
	_ensure_save_dir()
	var file := FileAccess.open(_slot_path(slot), FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not open save slot '%s' for writing." % slot, "code": FileAccess.get_open_error()}
	file.store_string(JSON.stringify(_jsonify(payload), "\t"))
	return {"ok": true}


func _read_file(slot: StringName) -> Dictionary:
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return {"ok": false, "error": "Save slot '%s' was not found." % slot}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not open save slot '%s'." % slot, "code": FileAccess.get_open_error()}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return {"ok": false, "error": "Save slot '%s' is not valid JSON." % slot}
	return {"ok": true, "payload": parsed}


func _peek_slot(slot: StringName) -> Dictionary:
	if use_memory_storage:
		if not _memory_slots.has(slot):
			return {"ok": false}
		var payload: Dictionary = _memory_slots[slot]
		var copy := payload.duplicate(true)
		copy["ok"] = true
		return copy
	var read_result := _read_file(slot)
	if not bool(read_result.get("ok", false)):
		return {"ok": false}
	var payload: Dictionary = read_result["payload"]
	payload["ok"] = true
	return payload


func _ensure_save_dir() -> void:
	DirAccess.make_dir_recursive_absolute(save_dir)


func _slot_path(slot: StringName) -> String:
	return "%s/%s.json" % [save_dir, String(slot)]


func _numbered_slot_name(index: int, prefix: String) -> StringName:
	return StringName("%s%s" % [prefix, index + 1])


func _jsonify(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value:
			result[str(key)] = _jsonify(value[key])
		return result
	if value is Array:
		var result_array: Array = []
		for item in value:
			result_array.append(_jsonify(item))
		return result_array
	if value is StringName:
		return String(value)
	if value is Vector2:
		return {"x": value.x, "y": value.y}
	if value is Object:
		return str(value)
	return value


func _as_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var text := str(value).strip_edges().to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"
