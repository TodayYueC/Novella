extends "res://addons/novella/core/novella_resource.gd"

class_name NovellaPortraitLayerResource

@export var group: StringName = &""
@export var attribute: StringName = &""
@export_file("*.png", "*.webp", "*.jpg", "*.jpeg") var texture_path: String = ""
@export var order: int = 0
@export var condition: String = ""
@export var fallback_attribute: StringName = &""

func to_dict() -> Dictionary:
	var data := super.to_dict()
	data.merge({
		"group": String(group),
		"attribute": String(attribute),
		"texture_path": texture_path,
		"order": order,
		"condition": condition,
		"fallback_attribute": String(fallback_attribute),
	}, true)
	return data


func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	group = StringName(str(data.get("group", "")))
	attribute = StringName(str(data.get("attribute", "")))
	texture_path = str(data.get("texture_path", ""))
	order = int(data.get("order", 0))
	condition = str(data.get("condition", ""))
	fallback_attribute = StringName(str(data.get("fallback_attribute", "")))
