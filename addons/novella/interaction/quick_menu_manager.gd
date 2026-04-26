extends RefCounted

class_name NovellaQuickMenuManager

signal visibility_changed(visible: bool)
signal action_requested(action_id: StringName, result: Dictionary)

var visible: bool = true
var actions: Array = [
	{"id": &"auto", "label": "Auto", "enabled": true, "visible": true},
	{"id": &"skip", "label": "Skip", "enabled": true, "visible": true},
	{"id": &"save", "label": "Save", "enabled": true, "visible": true},
	{"id": &"load", "label": "Load", "enabled": true, "visible": true},
	{"id": &"log", "label": "Log", "enabled": true, "visible": true},
	{"id": &"gallery", "label": "Gallery", "enabled": true, "visible": true},
	{"id": &"achievements", "label": "Achievements", "enabled": true, "visible": true},
	{"id": &"rollback", "label": "Rollback", "enabled": true, "visible": true},
	{"id": &"config", "label": "Config", "enabled": true, "visible": true},
	{"id": &"title", "label": "Title", "enabled": true, "visible": true},
]
var handlers: Dictionary = {}

func set_visible(enabled: bool) -> void:
	visible = enabled
	visibility_changed.emit(visible)


func set_actions(next_actions: Array) -> void:
	actions = next_actions.duplicate(true)


func get_visible_actions() -> Array:
	var result: Array = []
	for action in actions:
		if _as_bool(action.get("visible", true)):
			result.append(action.duplicate(true))
	return result


func set_action_enabled(action_id: StringName, enabled: bool) -> void:
	for action in actions:
		if action.get("id", &"") == action_id:
			action["enabled"] = enabled
			return


func register_action_handler(action_id: StringName, handler: Callable) -> void:
	handlers[action_id] = handler


func dispatch_action(action_id: StringName, context: Dictionary = {}) -> Dictionary:
	var action := _find_action(action_id)
	if action.is_empty():
		var missing := {"ok": false, "error": "Unknown quick menu action '%s'." % action_id}
		action_requested.emit(action_id, missing)
		return missing
	if not _as_bool(action.get("enabled", true)):
		var disabled := {"ok": false, "disabled": true, "action": String(action_id)}
		action_requested.emit(action_id, disabled)
		return disabled
	var handler: Callable = handlers.get(action_id, Callable())
	var result: Dictionary = {}
	if handler.is_valid():
		var value: Variant = handler.call(context)
		result = value if value is Dictionary else {"ok": true, "value": value}
	else:
		result = {"ok": true, "action": String(action_id), "handled": false}
	action_requested.emit(action_id, result)
	return result


func get_state() -> Dictionary:
	return {
		"visible": visible,
		"actions": actions.duplicate(true),
	}


func restore_state(state: Dictionary) -> void:
	visible = _as_bool(state.get("visible", visible))
	actions = state.get("actions", actions).duplicate(true)


func _find_action(action_id: StringName) -> Dictionary:
	for action in actions:
		if action.get("id", &"") == action_id:
			return action
	return {}


func _as_bool(value: Variant) -> bool:
	if value is bool:
		return value
	var text := str(value).strip_edges().to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"
