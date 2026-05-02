extends RefCounted

class_name NovellaUIFeedbackManager

signal confirmation_requested(request: Dictionary)
signal confirmation_resolved(result: Dictionary)
signal toast_posted(toast: Dictionary)
signal dialogue_visibility_changed(hidden: bool)

var pending_confirmations: Dictionary = {}
var toasts: Array = []
var dialogue_hidden: bool = false
var max_toasts: int = 5
var _next_confirmation_id: int = 1

func request_confirmation(action_id: StringName, message: String, payload: Dictionary = {}) -> Dictionary:
	var id := _next_confirmation_id
	_next_confirmation_id += 1
	var request := {
		"ok": false,
		"confirmation_required": true,
		"confirmation_id": id,
		"action": String(action_id),
		"message": message,
		"payload": payload.duplicate(true),
	}
	pending_confirmations[id] = request
	confirmation_requested.emit(request.duplicate(true))
	return request.duplicate(true)


func resolve_confirmation(confirmation_id: int, accepted: bool) -> Dictionary:
	if not pending_confirmations.has(confirmation_id):
		return {"ok": false, "error": "Unknown confirmation '%s'." % confirmation_id}
	var request: Dictionary = pending_confirmations[confirmation_id]
	pending_confirmations.erase(confirmation_id)
	var result := {
		"ok": true,
		"confirmation_id": confirmation_id,
		"accepted": accepted,
		"action": request.get("action", ""),
		"payload": request.get("payload", {}).duplicate(true),
	}
	confirmation_resolved.emit(result.duplicate(true))
	return result


func push_toast(message: String, kind: StringName = &"info", duration: float = 2.0, payload: Dictionary = {}) -> Dictionary:
	var toast := {
		"message": message,
		"kind": String(kind),
		"duration": maxf(0.0, duration),
		"remaining": maxf(0.0, duration),
		"payload": payload.duplicate(true),
	}
	toasts.append(toast)
	while toasts.size() > max_toasts:
		toasts.pop_front()
	toast_posted.emit(toast.duplicate(true))
	return {"ok": true, "toast": toast.duplicate(true), "toasts": toasts.duplicate(true)}


func consume_toasts(delta: float) -> Array:
	var remaining_toasts: Array = []
	for toast_value in toasts:
		var toast: Dictionary = toast_value
		toast["remaining"] = maxf(0.0, float(toast.get("remaining", 0.0)) - maxf(0.0, delta))
		if float(toast["remaining"]) > 0.0 or float(toast.get("duration", 0.0)) == 0.0:
			remaining_toasts.append(toast)
	toasts = remaining_toasts
	return toasts.duplicate(true)


func set_dialogue_hidden(hidden: bool) -> Dictionary:
	dialogue_hidden = hidden
	dialogue_visibility_changed.emit(dialogue_hidden)
	return {"ok": true, "hidden": dialogue_hidden}


func toggle_dialogue_hidden() -> Dictionary:
	return set_dialogue_hidden(not dialogue_hidden)


func get_state() -> Dictionary:
	return {
		"pending_confirmations": pending_confirmations.duplicate(true),
		"toasts": toasts.duplicate(true),
		"dialogue_hidden": dialogue_hidden,
		"max_toasts": max_toasts,
		"next_confirmation_id": _next_confirmation_id,
	}


func restore_state(state: Dictionary) -> void:
	pending_confirmations = state.get("pending_confirmations", {}).duplicate(true)
	toasts = state.get("toasts", []).duplicate(true)
	dialogue_hidden = bool(state.get("dialogue_hidden", dialogue_hidden))
	max_toasts = int(state.get("max_toasts", max_toasts))
	_next_confirmation_id = int(state.get("next_confirmation_id", _next_confirmation_id))
