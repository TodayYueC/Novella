extends "res://addons/novella/core/novella_resource.gd"

class_name NovellaTransitionResource

@export var transition_name: StringName = &"fade"
@export var duration: float = 0.5
@export var shader_path: String = ""
@export var parameters: Dictionary = {}

func to_dict() -> Dictionary:
	var data := super.to_dict()
	data.merge({
		"transition_name": String(transition_name),
		"duration": duration,
		"shader_path": shader_path,
		"parameters": parameters.duplicate(true),
	}, true)
	return data


func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	transition_name = StringName(str(data.get("transition_name", "fade")))
	duration = float(data.get("duration", 0.5))
	shader_path = str(data.get("shader_path", ""))
	parameters = data.get("parameters", {}).duplicate(true)
