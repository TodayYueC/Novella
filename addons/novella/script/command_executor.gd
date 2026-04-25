extends RefCounted

class_name NovellaCommandExecutor

var registry: Variant

func _init(p_registry: Variant = null) -> void:
	registry = p_registry


func execute(command_name: StringName, raw_arguments: String = "", context: Dictionary = {}) -> Dictionary:
	if registry == null:
		return {"ok": false, "error": "No command registry configured."}
	return registry.execute(command_name, raw_arguments, context)
