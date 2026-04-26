extends RefCounted

class_name NovellaSidePortrait

var current_speaker: StringName = &""
var current_expression: StringName = &""
var portrait_path: String = ""
var portraits: Dictionary = {}

func register_portraits(character_id: StringName, portrait_map: Dictionary) -> void:
	portraits[character_id] = portrait_map.duplicate(true)


func update_speaker(character_id: StringName, expression: StringName = &"") -> Dictionary:
	current_speaker = character_id
	current_expression = expression
	var character_portraits: Dictionary = portraits.get(character_id, {})
	portrait_path = str(character_portraits.get(expression, character_portraits.get(&"default", "")))
	return get_state()


func clear() -> void:
	current_speaker = &""
	current_expression = &""
	portrait_path = ""


func get_state() -> Dictionary:
	return {
		"speaker": String(current_speaker),
		"expression": String(current_expression),
		"portrait_path": portrait_path,
	}
