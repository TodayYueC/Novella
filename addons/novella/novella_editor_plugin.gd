@tool
extends EditorPlugin

const Compatibility := preload("res://addons/novella/core/compatibility.gd")

func _enter_tree() -> void:
	var result := Compatibility.check_engine_version()
	if not result["supported"]:
		push_warning(result["message"])


func _exit_tree() -> void:
	pass
