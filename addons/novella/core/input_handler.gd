extends RefCounted

signal advance_requested
signal rollback_requested
signal quick_save_requested
signal quick_load_requested
signal hide_ui_requested

var action_map: Dictionary = {
	"advance": ["ui_accept", "mouse_left"],
	"rollback": ["ui_up", "mouse_wheel_up"],
	"quick_save": ["novella_quick_save"],
	"quick_load": ["novella_quick_load"],
	"hide_ui": ["ui_cancel", "mouse_right"],
}

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


func set_bindings(action_name: StringName, bindings: Array) -> void:
	action_map[String(action_name)] = bindings.duplicate()


func get_bindings(action_name: StringName) -> Array:
	return action_map.get(String(action_name), []).duplicate()
