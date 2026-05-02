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
var default_slot_count: int = 64
var default_page_size: int = 8
var current_chapter: String = ""
var playtime_seconds: float = 0.0
var autosave_triggers: Dictionary = {
	"choice": true,
	"scene": true,
	"timed": false,
}

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
	if options.has("slot_count"):
		default_slot_count = max(1, int(options["slot_count"]))
	if options.has("page_size"):
		default_page_size = max(1, int(options["page_size"]))
	if options.has("chapter"):
		current_chapter = str(options["chapter"])
	if options.has("autosave_triggers") and options["autosave_triggers"] is Dictionary:
		autosave_triggers = options["autosave_triggers"].duplicate(true)


func set_chapter(chapter_name: String) -> void:
	current_chapter = chapter_name


func set_playtime(seconds: float) -> void:
	playtime_seconds = maxf(0.0, seconds)


func advance_playtime(delta: float) -> void:
	playtime_seconds = maxf(0.0, playtime_seconds + delta)


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


func save_game_with_thumbnail(slot: StringName, state: Dictionary, metadata: Dictionary, viewport: Viewport, thumbnail_dir: String = "user://novella/thumbnails") -> Dictionary:
	var next_metadata := metadata.duplicate(true)
	var thumbnail_path := "%s/%s.png" % [thumbnail_dir.trim_suffix("/"), String(slot)]
	var thumbnail_result := capture_thumbnail(viewport, thumbnail_path)
	if bool(thumbnail_result.get("ok", false)):
		next_metadata["thumbnail"] = thumbnail_result["thumbnail"]
	else:
		next_metadata["thumbnail_error"] = thumbnail_result.get("error", "thumbnail capture failed")
	return save_game(slot, state, next_metadata)


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


func list_slots(slot_count: int = -1, page: int = 0, page_size: int = -1, slot_prefix: String = "") -> Array:
	var size: int = default_page_size if page_size <= 0 else page_size
	var prefix: String = default_slot_prefix if slot_prefix.is_empty() else slot_prefix
	var safe_slot_count: int = default_slot_count if slot_count <= 0 else slot_count
	var safe_page: int = max(0, page)
	var start: int = safe_page * size
	var stop: int = min(start + size, safe_slot_count)
	var result: Array = []
	for index in range(start, stop):
		var slot_name := _numbered_slot_name(index, prefix)
		result.append(get_slot_summary(slot_name, index, safe_page))
	return result


func page_count(slot_count: int = -1, page_size: int = -1) -> int:
	var safe_slot_count: int = default_slot_count if slot_count <= 0 else slot_count
	var size: int = default_page_size if page_size <= 0 else page_size
	return maxi(1, int(ceil(float(safe_slot_count) / float(size))))


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


func autosave_if(trigger: StringName, state: Dictionary, metadata: Dictionary = {}) -> Dictionary:
	if not _as_bool(autosave_triggers.get(String(trigger), false)):
		return {"ok": true, "skipped": true, "trigger": String(trigger)}
	var next_metadata := metadata.duplicate(true)
	next_metadata["kind"] = "auto"
	next_metadata["trigger"] = String(trigger)
	return autosave(state, next_metadata)


func export_save(slot: StringName, encrypted: bool = false, passphrase: String = "") -> Dictionary:
	var payload := load_game(slot)
	if not bool(payload.get("ok", false)):
		return payload
	var text := JSON.stringify(_jsonify(payload))
	if encrypted:
		text = JSON.stringify({
			"encrypted": true,
			"version": SAVE_VERSION,
			"payload": _xor_to_base64(text, passphrase),
		})
	return {"ok": true, "slot": String(slot), "encrypted": encrypted, "text": text}


func import_save(serialized: String, slot_override: StringName = &"", passphrase: String = "") -> Dictionary:
	var parsed: Variant = JSON.parse_string(serialized)
	if not (parsed is Dictionary):
		return {"ok": false, "error": "Save import text is not valid JSON."}
	var payload: Dictionary = parsed
	if bool(payload.get("encrypted", false)):
		var decoded := _xor_from_base64(str(payload.get("payload", "")), passphrase)
		var decrypted: Variant = JSON.parse_string(decoded)
		if not (decrypted is Dictionary):
			return {"ok": false, "error": "Encrypted save payload could not be decoded."}
		payload = decrypted
	var slot := slot_override if slot_override != &"" else StringName(str(payload.get("slot", "imported")))
	return save_game(slot, payload.get("state", {}), payload.get("metadata", {}))


func capture_thumbnail(viewport: Viewport, path: String) -> Dictionary:
	if viewport == null:
		return {"ok": false, "error": "No viewport supplied for thumbnail capture."}
	var image := viewport.get_texture().get_image()
	if image == null:
		return {"ok": false, "error": "Could not read viewport image."}
	var dir_path := path.get_base_dir()
	if not dir_path.is_empty():
		DirAccess.make_dir_recursive_absolute(dir_path)
	var error := image.save_png(path)
	if error != OK:
		return {"ok": false, "error": "Could not save thumbnail '%s'." % path, "code": error}
	return {"ok": true, "thumbnail": path}


func get_state() -> Dictionary:
	return {
		"save_dir": save_dir,
		"use_memory_storage": use_memory_storage,
		"quick_slot": String(quick_slot),
		"autosave_slot": String(autosave_slot),
		"default_slot_prefix": default_slot_prefix,
		"default_slot_count": default_slot_count,
		"default_page_size": default_page_size,
		"current_chapter": current_chapter,
		"playtime_seconds": playtime_seconds,
		"autosave_triggers": autosave_triggers.duplicate(true),
		"memory_slots": _memory_slots.duplicate(true),
	}


func restore_state(state: Dictionary) -> void:
	save_dir = str(state.get("save_dir", save_dir))
	use_memory_storage = _as_bool(state.get("use_memory_storage", use_memory_storage))
	quick_slot = StringName(str(state.get("quick_slot", String(quick_slot))))
	autosave_slot = StringName(str(state.get("autosave_slot", String(autosave_slot))))
	default_slot_prefix = str(state.get("default_slot_prefix", default_slot_prefix))
	default_slot_count = max(1, int(state.get("default_slot_count", default_slot_count)))
	default_page_size = max(1, int(state.get("default_page_size", default_page_size)))
	current_chapter = str(state.get("current_chapter", current_chapter))
	playtime_seconds = maxf(0.0, float(state.get("playtime_seconds", playtime_seconds)))
	autosave_triggers = state.get("autosave_triggers", autosave_triggers).duplicate(true)
	_memory_slots = state.get("memory_slots", {}).duplicate(true)


func _build_metadata(metadata: Dictionary) -> Dictionary:
	var result := metadata.duplicate(true)
	if not result.has("saved_at"):
		result["saved_at"] = Time.get_datetime_string_from_system(false, true)
	if not result.has("chapter") and not current_chapter.is_empty():
		result["chapter"] = current_chapter
	if not result.has("playtime_seconds"):
		result["playtime_seconds"] = playtime_seconds
	if not result.has("playtime"):
		result["playtime"] = _format_playtime(float(result.get("playtime_seconds", 0.0)))
	return result


func _format_playtime(seconds: float) -> String:
	var total := int(maxf(0.0, seconds))
	var hours := total / 3600
	var minutes := (total % 3600) / 60
	var secs := total % 60
	return "%02d:%02d:%02d" % [hours, minutes, secs]


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


func _xor_to_base64(text: String, passphrase: String) -> String:
	var bytes := text.to_utf8_buffer()
	var key := passphrase if not passphrase.is_empty() else "novella"
	var encoded := PackedByteArray()
	for index in range(bytes.size()):
		encoded.append(int(bytes[index]) ^ (key.unicode_at(index % key.length()) & 0xff))
	return Marshalls.raw_to_base64(encoded)


func _xor_from_base64(text: String, passphrase: String) -> String:
	var bytes := Marshalls.base64_to_raw(text)
	var key := passphrase if not passphrase.is_empty() else "novella"
	var decoded := PackedByteArray()
	for index in range(bytes.size()):
		decoded.append(int(bytes[index]) ^ (key.unicode_at(index % key.length()) & 0xff))
	return decoded.get_string_from_utf8()


func _as_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var text := str(value).strip_edges().to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"
