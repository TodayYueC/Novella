extends Resource

class_name NovellaResource

@export var id: StringName = &""
@export var display_name: String = ""
@export var description: String = ""
@export var metadata: Dictionary = {}

func to_dict() -> Dictionary:
	return {
		"id": String(id),
		"display_name": display_name,
		"description": description,
		"metadata": metadata.duplicate(true),
	}


func from_dict(data: Dictionary) -> void:
	id = StringName(str(data.get("id", "")))
	display_name = str(data.get("display_name", ""))
	description = str(data.get("description", ""))
	metadata = data.get("metadata", {}).duplicate(true)


func duplicate_resource() -> Resource:
	var copy: Resource = get_script().new()
	copy.from_dict(to_dict())
	return copy
