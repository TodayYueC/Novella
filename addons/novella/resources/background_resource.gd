extends "res://addons/novella/core/novella_resource.gd"

class_name NovellaBackgroundResource

@export_file("*.png", "*.webp", "*.jpg", "*.jpeg", "*.tscn") var source_path: String = ""
@export var default_transition: StringName = &"fade"
@export var localized_overrides: Dictionary = {}
@export var filters: Dictionary = {}

func to_dict() -> Dictionary:
	var data := super.to_dict()
	data.merge({
		"source_path": source_path,
		"default_transition": String(default_transition),
		"localized_overrides": localized_overrides.duplicate(true),
		"filters": filters.duplicate(true),
	}, true)
	return data


func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	source_path = str(data.get("source_path", ""))
	default_transition = StringName(str(data.get("default_transition", "fade")))
	localized_overrides = data.get("localized_overrides", {}).duplicate(true)
	filters = data.get("filters", {}).duplicate(true)
