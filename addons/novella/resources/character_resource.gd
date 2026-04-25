extends "res://addons/novella/core/novella_resource.gd"

class_name NovellaCharacterResource

@export var character_id: StringName = &""
@export var color: Color = Color.WHITE
@export var voice_directory: String = ""
@export var portraits: Array[Resource] = []
@export var text_style: Dictionary = {}
@export var side_portraits: Dictionary = {}

func to_dict() -> Dictionary:
	var data := super.to_dict()
	data.merge({
		"character_id": String(character_id),
		"color": color.to_html(true),
		"voice_directory": voice_directory,
		"text_style": text_style.duplicate(true),
		"side_portraits": side_portraits.duplicate(true),
	}, true)
	var portrait_data: Array = []
	for portrait in portraits:
		if portrait != null and portrait.has_method("to_dict"):
			portrait_data.append(portrait.to_dict())
	data["portraits"] = portrait_data
	return data


func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	character_id = StringName(str(data.get("character_id", data.get("id", ""))))
	color = Color.html(str(data.get("color", "#ffffffff")))
	voice_directory = str(data.get("voice_directory", ""))
	text_style = data.get("text_style", {}).duplicate(true)
	side_portraits = data.get("side_portraits", {}).duplicate(true)
