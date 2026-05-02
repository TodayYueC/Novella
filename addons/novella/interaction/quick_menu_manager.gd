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
var confirm_required_actions: Array[StringName] = [&"title", &"load"]

func set_visible(enabled: bool) -> void:
	visible = enabled
	visibility_changed.emit(visible)


func set_actions(next_actions: Array) -> void:
	actions = next_actions.duplicate(true)
	_normalize_action_orders()


func get_visible_actions() -> Array:
	var result: Array = []
	for action in actions:
		if _as_bool(action.get("visible", true)):
			result.append(action.duplicate(true))
	result.sort_custom(func(a, b): return int(a.get("order", 0)) < int(b.get("order", 0)))
	return result


func set_action_enabled(action_id: StringName, enabled: bool) -> void:
	for action in actions:
		if action.get("id", &"") == action_id:
			action["enabled"] = enabled
			return


func set_action_visible(action_id: StringName, next_visible: bool) -> void:
	for action in actions:
		if action.get("id", &"") == action_id:
			action["visible"] = next_visible
			return


func configure_action(action_id: StringName, patch: Dictionary) -> Dictionary:
	for action in actions:
		if action.get("id", &"") == action_id:
			for key in patch:
				action[key] = patch[key]
			_normalize_action_orders()
			return {"ok": true, "action": action.duplicate(true)}
	return {"ok": false, "error": "Unknown quick menu action '%s'." % action_id}


func move_action(action_id: StringName, to_index: int) -> Dictionary:
	var from_index := -1
	for index in range(actions.size()):
		if actions[index].get("id", &"") == action_id:
			from_index = index
			break
	if from_index < 0:
		return {"ok": false, "error": "Unknown quick menu action '%s'." % action_id}
	var action: Dictionary = actions[from_index]
	actions.remove_at(from_index)
	actions.insert(clampi(to_index, 0, actions.size()), action)
	_normalize_action_orders()
	return {"ok": true, "from": from_index, "to": actions.find(action), "actions": actions.duplicate(true)}


func get_action_order() -> Array:
	_normalize_action_orders()
	var result: Array = []
	for action in actions:
		result.append(String(action.get("id", "")))
	return result


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
	if _requires_confirmation(action_id) and not _as_bool(context.get("confirmed", false)):
		var confirmation := {
			"ok": false,
			"confirmation_required": true,
			"action": String(action_id),
			"message": str(action.get("confirm_message", "Confirm %s?" % String(action_id))),
		}
		action_requested.emit(action_id, confirmation)
		return confirmation
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
		"confirm_required_actions": confirm_required_actions.duplicate(),
	}


func restore_state(state: Dictionary) -> void:
	visible = _as_bool(state.get("visible", visible))
	actions = state.get("actions", actions).duplicate(true)
	confirm_required_actions = state.get("confirm_required_actions", confirm_required_actions).duplicate()
	_normalize_action_orders()


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


func _requires_confirmation(action_id: StringName) -> bool:
	for item in confirm_required_actions:
		if item == action_id or String(item) == String(action_id):
			return true
	return false


func _normalize_action_orders() -> void:
	for index in range(actions.size()):
		if not actions[index].has("order"):
			actions[index]["order"] = index
