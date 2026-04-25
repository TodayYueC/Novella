extends "res://addons/novella/core/interfaces/service_interface.gd"

func handle_action(_action_name: StringName) -> bool:
	push_error("handle_action must be implemented by an input handler service.")
	return false
