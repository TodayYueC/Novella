extends "res://addons/novella/core/interfaces/service_interface.gd"

func declare_variable(_name: StringName, _default_value: Variant = null, _scope: int = 0) -> void:
	push_error("declare_variable must be implemented by a variable manager service.")


func set_variable(_name: StringName, _value: Variant, _scope: int = 0) -> void:
	push_error("set_variable must be implemented by a variable manager service.")


func get_variable(_name: StringName, _default_value: Variant = null) -> Variant:
	push_error("get_variable must be implemented by a variable manager service.")
	return _default_value
