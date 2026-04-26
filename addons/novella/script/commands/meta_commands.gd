extends RefCounted

class_name NovellaMetaCommands

const CommandParser := preload("res://addons/novella/script/command_parser.gd")

var parser := CommandParser.new()
var localization_manager: Variant = null
var gallery_manager: Variant = null
var achievement_manager: Variant = null
var variable_manager: Variant = null

func register_all(registry: Variant, managers: Dictionary) -> void:
	localization_manager = managers.get("localization_manager")
	gallery_manager = managers.get("gallery_manager")
	achievement_manager = managers.get("achievement_manager")
	variable_manager = managers.get("variable_manager")

	registry.register_command(&"locale", Callable(self, "_command_locale"))
	registry.register_command(&"language", Callable(self, "_command_locale"))
	registry.register_command(&"translation", Callable(self, "_command_translation"))
	registry.register_command(&"tr_var", Callable(self, "_command_tr_var"))
	registry.register_command(&"gallery", Callable(self, "_command_gallery"))
	registry.register_command(&"replay", Callable(self, "_command_replay"))
	registry.register_command(&"achievement", Callable(self, "_command_achievement"))
	registry.register_command(&"achieve", Callable(self, "_command_achievement"))
	registry.register_command(&"meta_check", Callable(self, "_command_meta_check"))


func _command_locale(raw_arguments: String, _context: Dictionary) -> Dictionary:
	if localization_manager == null:
		return _missing("localization_manager")
	var parsed := _parse(raw_arguments)
	var locale := StringName(str(_argument(parsed, 0, localization_manager.current_locale)))
	return localization_manager.set_locale(locale)


func _command_translation(raw_arguments: String, _context: Dictionary) -> Dictionary:
	if localization_manager == null:
		return _missing("localization_manager")
	var parsed := _parse(raw_arguments)
	var locale := StringName(str(_argument(parsed, 0, localization_manager.current_locale)))
	var key := StringName(str(_argument(parsed, 1, parsed["named"].get(&"key", ""))))
	var text := _clean_text(str(parsed["named"].get(&"text", _argument(parsed, 2, ""))))
	if key == &"":
		return {"ok": false, "error": "Invalid @translation syntax. Expected '@translation locale key text:value'."}
	localization_manager.add_translation(locale, key, text)
	return {"ok": true, "locale": String(locale), "key": String(key), "text": text}


func _command_tr_var(raw_arguments: String, _context: Dictionary) -> Dictionary:
	if localization_manager == null:
		return _missing("localization_manager")
	if variable_manager == null:
		return _missing("variable_manager")
	var parsed := _parse(raw_arguments)
	var key := StringName(str(_argument(parsed, 0, "")))
	var target := StringName(str(parsed["named"].get(&"to", "")))
	if key == &"" or target == &"":
		return {"ok": false, "error": "Invalid @tr_var syntax. Expected '@tr_var key to:variable_name'."}
	var text: String = localization_manager.translate(key, variable_manager)
	variable_manager.set_variable(target, text)
	return {"ok": true, "key": String(key), "variable": String(target), "value": text}


func _command_gallery(raw_arguments: String, _context: Dictionary) -> Dictionary:
	if gallery_manager == null:
		return _missing("gallery_manager")
	var parsed := _parse(raw_arguments)
	var action := str(_argument(parsed, 0, "unlock"))
	var item_id := StringName(str(_argument(parsed, 1, parsed["named"].get(&"id", ""))))
	if item_id == &"":
		return {"ok": false, "error": "Invalid @gallery syntax. Expected '@gallery unlock id'."}
	var data := _named_data(parsed)
	match action:
		"register":
			return _ok(gallery_manager.register_item(item_id, data))
		"unlock":
			return _ok(gallery_manager.unlock_item(item_id, data))
		"lock":
			return _ok(gallery_manager.lock_item(item_id))
		"view":
			return _ok(gallery_manager.mark_viewed(item_id))
	return {"ok": false, "error": "Unknown gallery action '%s'." % action}


func _command_replay(raw_arguments: String, _context: Dictionary) -> Dictionary:
	if gallery_manager == null:
		return _missing("gallery_manager")
	var parsed := _parse(raw_arguments)
	var action := str(_argument(parsed, 0, "unlock"))
	var replay_id := StringName(str(_argument(parsed, 1, parsed["named"].get(&"id", ""))))
	var label := StringName(str(parsed["named"].get(&"label", replay_id)))
	if replay_id == &"":
		return {"ok": false, "error": "Invalid @replay syntax. Expected '@replay unlock id label:start'."}
	if action == "unlock" or action == "register":
		return _ok(gallery_manager.unlock_replay(replay_id, label, _named_data(parsed)))
	if action == "view":
		return _ok(gallery_manager.mark_viewed(replay_id))
	return {"ok": false, "error": "Unknown replay action '%s'." % action}


func _command_achievement(raw_arguments: String, _context: Dictionary) -> Dictionary:
	if achievement_manager == null:
		return _missing("achievement_manager")
	var parsed := _parse(raw_arguments)
	var action := str(_argument(parsed, 0, "unlock"))
	var achievement_id := StringName(str(_argument(parsed, 1, parsed["named"].get(&"id", ""))))
	if achievement_id == &"":
		return {"ok": false, "error": "Invalid @achievement syntax. Expected '@achievement unlock id'."}
	var data := _named_data(parsed)
	match action:
		"register":
			return _ok(achievement_manager.register_achievement(achievement_id, data))
		"unlock":
			return _ok(achievement_manager.unlock(achievement_id, data))
		"progress":
			return _ok(achievement_manager.add_progress(achievement_id, float(data.get("amount", 1.0)), data))
		"set":
			return _ok(achievement_manager.set_progress(achievement_id, float(data.get("value", data.get("amount", 0.0))), data))
	return {"ok": false, "error": "Unknown achievement action '%s'." % action}


func _command_meta_check(_raw_arguments: String, _context: Dictionary) -> Dictionary:
	var unlocked: Array = []
	if achievement_manager != null and achievement_manager.has_method("evaluate_conditions") and variable_manager != null:
		unlocked = achievement_manager.evaluate_conditions(variable_manager)
	return {"ok": true, "unlocked": unlocked}


func _parse(raw_arguments: String) -> Dictionary:
	return parser.parse_arguments(raw_arguments)


func _argument(parsed: Dictionary, index: int, default_value: Variant = "") -> Variant:
	var positional: Array = parsed["positional"]
	if index < positional.size():
		return positional[index]
	return default_value


func _named_data(parsed: Dictionary) -> Dictionary:
	var named: Dictionary = parsed["named"]
	var result: Dictionary = {}
	for key in named:
		result[String(key)] = _clean_text(str(named[key]))
	return result


func _clean_text(value: String) -> String:
	var text := value.strip_edges()
	if text.begins_with("\"") and text.ends_with("\"") and text.length() >= 2:
		return text.substr(1, text.length() - 2)
	return text


func _ok(payload: Dictionary) -> Dictionary:
	payload["ok"] = bool(payload.get("ok", true))
	return payload


func _missing(manager_name: String) -> Dictionary:
	return {"ok": false, "error": "No %s configured." % manager_name}
