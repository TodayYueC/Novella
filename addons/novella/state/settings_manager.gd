extends RefCounted

class_name NovellaSettingsManager

signal setting_changed(key: StringName, value: Variant)
signal settings_loaded(settings: Dictionary)
signal settings_saved(settings: Dictionary)

const Constants := preload("res://addons/novella/core/constants.gd")

var settings_path: String = "user://novella/settings.json"
var defaults: Dictionary = {
	&"text_speed": Constants.DEFAULT_TEXT_SPEED,
	&"auto_delay": Constants.DEFAULT_AUTO_DELAY,
	&"master_volume": 1.0,
	&"music_volume": 1.0,
	&"voice_volume": 1.0,
	&"sfx_volume": 1.0,
	&"fullscreen": false,
	&"skip_unread": false,
	&"locale": "en",
}
var settings: Dictionary = {}

func _init() -> void:
	reset_to_defaults()


func configure(options: Dictionary = {}) -> void:
	if options.has("settings_path"):
		settings_path = str(options["settings_path"])
	if options.has("defaults") and options["defaults"] is Dictionary:
		for key in options["defaults"]:
			defaults[StringName(str(key))] = options["defaults"][key]
		for key in defaults:
			if not settings.has(key):
				settings[key] = defaults[key]


func reset_to_defaults() -> Dictionary:
	settings.clear()
	for key in defaults:
		settings[key] = defaults[key]
	return settings.duplicate(true)


func set_setting(key: StringName, value: Variant, emit_signal: bool = true) -> Dictionary:
	var next_value := _coerce_value(key, value)
	settings[key] = next_value
	if emit_signal:
		setting_changed.emit(key, next_value)
	return {"ok": true, "key": String(key), "value": next_value}


func get_setting(key: StringName, default_value: Variant = null) -> Variant:
	return settings.get(key, defaults.get(key, default_value))


func set_volume(channel: StringName, value: float) -> Dictionary:
	var key := StringName("%s_volume" % String(channel))
	return set_setting(key, clampf(value, 0.0, 1.0))


func apply_to(variable_manager: Variant = null, auto_manager: Variant = null) -> Dictionary:
	if variable_manager != null and variable_manager.has_method("set_variable"):
		for key in settings:
			variable_manager.set_variable(key, settings[key], Constants.VariableScope.SETTINGS)
	if auto_manager != null and auto_manager.has_method("configure"):
		auto_manager.configure({
			"delay": get_setting(&"auto_delay", Constants.DEFAULT_AUTO_DELAY),
		})
	return {"ok": true, "settings": settings.duplicate(true)}


func save_to_disk(path: String = "") -> Dictionary:
	var target := settings_path if path.is_empty() else path
	var dir_path := target.get_base_dir()
	if not dir_path.is_empty():
		DirAccess.make_dir_recursive_absolute(dir_path)
	var file := FileAccess.open(target, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "error": "Could not open settings file '%s'." % target, "code": FileAccess.get_open_error()}
	file.store_string(JSON.stringify(_jsonify(settings), "\t"))
	settings_saved.emit(settings.duplicate(true))
	return {"ok": true, "path": target, "settings": settings.duplicate(true)}


func load_from_disk(path: String = "") -> Dictionary:
	var target := settings_path if path.is_empty() else path
	if not FileAccess.file_exists(target):
		return {"ok": false, "missing": true, "path": target}
	var file := FileAccess.open(target, FileAccess.READ)
	if file == null:
		return {"ok": false, "error": "Could not open settings file '%s'." % target, "code": FileAccess.get_open_error()}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not (parsed is Dictionary):
		return {"ok": false, "error": "Settings file '%s' is not valid JSON." % target}
	restore_state({"settings": parsed})
	settings_loaded.emit(settings.duplicate(true))
	return {"ok": true, "path": target, "settings": settings.duplicate(true)}


func get_state() -> Dictionary:
	return {
		"settings_path": settings_path,
		"defaults": defaults.duplicate(true),
		"settings": settings.duplicate(true),
	}


func restore_state(state: Dictionary) -> void:
	settings_path = str(state.get("settings_path", settings_path))
	if state.has("defaults") and state["defaults"] is Dictionary:
		defaults.clear()
		for key in state["defaults"]:
			defaults[StringName(str(key))] = state["defaults"][key]
	reset_to_defaults()
	var source: Dictionary = state.get("settings", {})
	for key in source:
		set_setting(StringName(str(key)), source[key], false)


func _coerce_value(key: StringName, value: Variant) -> Variant:
	match key:
		&"text_speed":
			return maxf(1.0, float(value))
		&"auto_delay":
			return maxf(0.0, float(value))
		&"master_volume", &"music_volume", &"voice_volume", &"sfx_volume":
			return clampf(float(value), 0.0, 1.0)
		&"fullscreen", &"skip_unread":
			return _as_bool(value)
		&"locale":
			return str(value)
		_:
			return value


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
	return value


func _as_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var text := str(value).strip_edges().to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"
