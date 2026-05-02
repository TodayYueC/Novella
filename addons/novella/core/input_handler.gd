extends RefCounted

class_name NovellaInputHandler

signal advance_requested
signal rollback_requested
signal quick_save_requested
signal quick_load_requested
signal hide_ui_requested
signal input_device_changed(device: StringName)

var action_map: Dictionary = {
	"advance": ["ui_accept", "mouse_left"],
	"rollback": ["ui_up", "mouse_wheel_up"],
	"quick_save": ["novella_quick_save"],
	"quick_load": ["novella_quick_load"],
	"hide_ui": ["ui_cancel", "mouse_right"],
}
var device_bindings: Dictionary = {
	"touch": {
		"advance": ["tap"],
		"hide_ui": ["two_finger_tap"],
		"rollback": ["swipe_down"],
	},
	"gamepad": {
		"advance": ["button_a", "button_cross"],
		"rollback": ["left_shoulder"],
		"quick_save": ["button_y"],
		"quick_load": ["button_x"],
		"hide_ui": ["button_b", "button_circle"],
	},
}
var last_device: StringName = &"keyboard"

func handle_action(action_name: StringName) -> bool:
	match action_name:
		&"advance":
			advance_requested.emit()
		&"rollback":
			rollback_requested.emit()
		&"quick_save":
			quick_save_requested.emit()
		&"quick_load":
			quick_load_requested.emit()
		&"hide_ui":
			hide_ui_requested.emit()
		_:
			return false
	return true


func handle_input_event_data(event_data: Dictionary) -> Dictionary:
	var device := StringName(str(event_data.get("device", "keyboard")))
	var token := str(event_data.get("action", event_data.get("gesture", event_data.get("button", ""))))
	if device != last_device:
		last_device = device
		input_device_changed.emit(device)
	for action_name in device_bindings.get(String(device), {}):
		var bindings: Array = device_bindings[String(device)][action_name]
		if bindings.has(token):
			return {"ok": handle_action(StringName(str(action_name))), "device": String(device), "action": str(action_name), "token": token}
	return {"ok": false, "device": String(device), "token": token}


func set_device_bindings(device: StringName, action_name: StringName, bindings: Array) -> void:
	if not device_bindings.has(String(device)):
		device_bindings[String(device)] = {}
	device_bindings[String(device)][String(action_name)] = bindings.duplicate()


func bindings_for_device(action_name: StringName, device: StringName) -> Array:
	return device_bindings.get(String(device), {}).get(String(action_name), []).duplicate()


func get_input_help(device: StringName = &"") -> Dictionary:
	var target := last_device if device == &"" else device
	return {
		"device": String(target),
		"bindings": device_bindings.get(String(target), {}).duplicate(true),
	}


func set_bindings(action_name: StringName, bindings: Array) -> void:
	action_map[String(action_name)] = bindings.duplicate()


func get_bindings(action_name: StringName) -> Array:
	return action_map.get(String(action_name), []).duplicate()
