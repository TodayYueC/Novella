extends RefCounted

class_name NovellaInteractionCommands

const CommandParser := preload("res://addons/novella/script/command_parser.gd")

var parser := CommandParser.new()
var save_manager: Variant = null
var rollback_manager: Variant = null
var skip_manager: Variant = null
var auto_manager: Variant = null
var backlog_manager: Variant = null
var choice_manager: Variant = null
var quick_menu_manager: Variant = null
var settings_manager: Variant = null

func register_all(registry: Variant, managers: Dictionary) -> void:
	save_manager = managers.get("save_manager")
	rollback_manager = managers.get("rollback_manager")
	skip_manager = managers.get("skip_manager")
	auto_manager = managers.get("auto_manager")
	backlog_manager = managers.get("backlog_manager")
	choice_manager = managers.get("choice_manager")
	quick_menu_manager = managers.get("quick_menu_manager")
	settings_manager = managers.get("settings_manager")

	registry.register_command(&"save", Callable(self, "_command_save"))
	registry.register_command(&"load", Callable(self, "_command_load"))
	registry.register_command(&"quick_save", Callable(self, "_command_quick_save"))
	registry.register_command(&"quick_load", Callable(self, "_command_quick_load"))
	registry.register_command(&"auto_save", Callable(self, "_command_auto_save"))
	registry.register_command(&"rollback", Callable(self, "_command_rollback"))
	registry.register_command(&"prevent_rollback", Callable(self, "_command_prevent_rollback"))
	registry.register_command(&"allow_rollback", Callable(self, "_command_allow_rollback"))
	registry.register_command(&"fix_rollback", Callable(self, "_command_fix_rollback"))
	registry.register_command(&"skip", Callable(self, "_command_skip"))
	registry.register_command(&"prevent_skip", Callable(self, "_command_prevent_skip"))
	registry.register_command(&"allow_skip", Callable(self, "_command_allow_skip"))
	registry.register_command(&"auto", Callable(self, "_command_auto"))
	registry.register_command(&"prevent_auto", Callable(self, "_command_prevent_auto"))
	registry.register_command(&"allow_auto", Callable(self, "_command_allow_auto"))
	registry.register_command(&"backlog_clear", Callable(self, "_command_backlog_clear"))
	registry.register_command(&"choice_timeout", Callable(self, "_command_choice_timeout"))
	registry.register_command(&"quick_menu", Callable(self, "_command_quick_menu"))
	registry.register_command(&"settings", Callable(self, "_command_settings"))
	registry.register_command(&"config", Callable(self, "_command_settings"))
	registry.register_command(&"input", Callable(self, "_command_input"))


func _command_save(raw_arguments: String, context: Dictionary) -> Dictionary:
	if save_manager == null:
		return _missing("save_manager")
	var parsed := _parse(raw_arguments)
	var slot := StringName(str(_argument(parsed, 0, "manual")))
	return save_manager.save_game(slot, _snapshot_from_context(context), parsed["named"])


func _command_load(raw_arguments: String, context: Dictionary) -> Dictionary:
	if save_manager == null:
		return _missing("save_manager")
	var parsed := _parse(raw_arguments)
	var slot := StringName(str(_argument(parsed, 0, "manual")))
	var payload: Dictionary = save_manager.load_game(slot)
	if bool(payload.get("ok", false)):
		var state: Dictionary = payload.get("state", {})
		_restore_to_context(context, state)
		payload["restored_state"] = true
		payload["current_index"] = int(state.get("current_index", 0))
	return payload


func _command_quick_save(_raw_arguments: String, context: Dictionary) -> Dictionary:
	if save_manager == null:
		return _missing("save_manager")
	return save_manager.quick_save(_snapshot_from_context(context), {"kind": "quick"})


func _command_quick_load(_raw_arguments: String, context: Dictionary) -> Dictionary:
	if save_manager == null:
		return _missing("save_manager")
	var payload: Dictionary = save_manager.quick_load()
	if bool(payload.get("ok", false)):
		var state: Dictionary = payload.get("state", {})
		_restore_to_context(context, state)
		payload["restored_state"] = true
		payload["current_index"] = int(state.get("current_index", 0))
	return payload


func _command_auto_save(_raw_arguments: String, context: Dictionary) -> Dictionary:
	if save_manager == null:
		return _missing("save_manager")
	return save_manager.autosave(_snapshot_from_context(context), {"kind": "auto"})


func _command_rollback(raw_arguments: String, context: Dictionary) -> Dictionary:
	if rollback_manager == null:
		return _missing("rollback_manager")
	var steps := 1
	var stripped := raw_arguments.strip_edges()
	if stripped.is_valid_int():
		steps = int(stripped)
	var payload: Dictionary = rollback_manager.rollback(steps)
	if bool(payload.get("ok", false)):
		var state: Dictionary = payload.get("state", {})
		_restore_to_context(context, state)
		payload["restored_state"] = true
		payload["current_index"] = int(state.get("current_index", 0))
	return payload


func _command_prevent_rollback(_raw_arguments: String, _context: Dictionary) -> Dictionary:
	if rollback_manager == null:
		return _missing("rollback_manager")
	rollback_manager.prevent_rollback()
	return {"ok": true, "rollback_prevented": true}


func _command_allow_rollback(_raw_arguments: String, _context: Dictionary) -> Dictionary:
	if rollback_manager == null:
		return _missing("rollback_manager")
	rollback_manager.allow_rollback()
	return {"ok": true, "rollback_prevented": false}


func _command_fix_rollback(_raw_arguments: String, _context: Dictionary) -> Dictionary:
	if rollback_manager == null:
		return _missing("rollback_manager")
	rollback_manager.fix_current_position()
	return {"ok": true, "fixed": true}


func _command_skip(raw_arguments: String, _context: Dictionary) -> Dictionary:
	if skip_manager == null:
		return _missing("skip_manager")
	var action := raw_arguments.strip_edges()
	if action.is_empty() or action == "read":
		return skip_manager.start_skip(&"read")
	if action == "all":
		return skip_manager.start_skip(&"all")
	if action == "off" or action == "stop":
		return skip_manager.stop_skip()
	return {"ok": false, "error": "Invalid @skip mode. Expected read, all, or off."}


func _command_prevent_skip(_raw_arguments: String, _context: Dictionary) -> Dictionary:
	if skip_manager == null:
		return _missing("skip_manager")
	skip_manager.prevent_skip()
	return {"ok": true, "skip_prevented": true}


func _command_allow_skip(_raw_arguments: String, _context: Dictionary) -> Dictionary:
	if skip_manager == null:
		return _missing("skip_manager")
	skip_manager.allow_skip()
	return {"ok": true, "skip_prevented": false}


func _command_auto(raw_arguments: String, _context: Dictionary) -> Dictionary:
	if auto_manager == null:
		return _missing("auto_manager")
	var parsed := _parse(raw_arguments)
	var action := str(_argument(parsed, 0, "toggle"))
	match action:
		"on", "start":
			return auto_manager.start(parsed["named"])
		"off", "stop":
			return auto_manager.stop()
		"toggle":
			return auto_manager.toggle(parsed["named"])
	return {"ok": false, "error": "Invalid @auto mode. Expected on, off, or toggle."}


func _command_prevent_auto(_raw_arguments: String, _context: Dictionary) -> Dictionary:
	if auto_manager == null:
		return _missing("auto_manager")
	auto_manager.prevent_auto()
	return {"ok": true, "auto_prevented": true}


func _command_allow_auto(_raw_arguments: String, _context: Dictionary) -> Dictionary:
	if auto_manager == null:
		return _missing("auto_manager")
	auto_manager.allow_auto()
	return {"ok": true, "auto_prevented": false}


func _command_backlog_clear(_raw_arguments: String, _context: Dictionary) -> Dictionary:
	if backlog_manager == null:
		return _missing("backlog_manager")
	backlog_manager.clear()
	return {"ok": true, "cleared": "backlog"}


func _command_choice_timeout(raw_arguments: String, _context: Dictionary) -> Dictionary:
	if choice_manager == null:
		return _missing("choice_manager")
	var parsed := _parse(raw_arguments)
	var options: Dictionary = parsed["named"]
	if not parsed["positional"].is_empty():
		options["timeout"] = parsed["positional"][0]
	choice_manager.configure(options)
	return {"ok": true, "choice_timeout": choice_manager.timeout_seconds, "default": choice_manager.timeout_default_index}


func _command_quick_menu(raw_arguments: String, _context: Dictionary) -> Dictionary:
	if quick_menu_manager == null:
		return _missing("quick_menu_manager")
	var parsed := _parse(raw_arguments)
	var action := str(_argument(parsed, 0, "show"))
	match action:
		"show":
			quick_menu_manager.set_visible(true)
		"hide":
			quick_menu_manager.set_visible(false)
		_:
			return quick_menu_manager.dispatch_action(StringName(action), parsed["named"])
	return {"ok": true, "visible": quick_menu_manager.visible}


func _command_settings(raw_arguments: String, _context: Dictionary) -> Dictionary:
	if settings_manager == null:
		return _missing("settings_manager")
	var parsed := _parse(raw_arguments)
	if parsed["positional"].is_empty() and parsed["named"].is_empty():
		return {"ok": true, "settings": settings_manager.settings.duplicate(true)}
	var action := str(_argument(parsed, 0, "set"))
	match action:
		"reset":
			return {"ok": true, "settings": settings_manager.reset_to_defaults()}
		"save":
			return settings_manager.save_to_disk()
		"load":
			return settings_manager.load_from_disk()
		"set":
			var changed: Dictionary = {}
			for key in parsed["named"]:
				var result: Dictionary = settings_manager.set_setting(StringName(str(key)), parsed["named"][key])
				changed[String(key)] = result.get("value")
			return {"ok": true, "changed": changed, "settings": settings_manager.settings.duplicate(true)}
		_:
			if parsed["named"].is_empty():
				return {"ok": false, "error": "Invalid @settings syntax. Expected set key:value, reset, save, or load."}
			var changed: Dictionary = {}
			for key in parsed["named"]:
				var result: Dictionary = settings_manager.set_setting(StringName(str(key)), parsed["named"][key])
				changed[String(key)] = result.get("value")
			return {"ok": true, "changed": changed, "settings": settings_manager.settings.duplicate(true)}


func _command_input(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var action := raw_arguments.strip_edges()
	return {"ok": true, "input": action if not action.is_empty() else "noop"}


func _snapshot_from_context(context: Dictionary) -> Dictionary:
	var vm = context.get("vm")
	if vm != null and vm.has_method("snapshot_state"):
		return vm.snapshot_state()
	return context.duplicate(true)


func _restore_to_context(context: Dictionary, state: Dictionary) -> void:
	var vm = context.get("vm")
	if vm != null and vm.has_method("restore_state"):
		vm.restore_state(state)


func _parse(raw_arguments: String) -> Dictionary:
	return parser.parse_arguments(raw_arguments)


func _argument(parsed: Dictionary, index: int, default_value: Variant = "") -> Variant:
	var positional: Array = parsed["positional"]
	if index < positional.size():
		return positional[index]
	return default_value


func _missing(manager_name: String) -> Dictionary:
	return {"ok": false, "error": "No %s configured." % manager_name}
