extends "res://addons/novella/core/novella_resource.gd"

class_name NovellaVariableResource

const Constants := preload("res://addons/novella/core/constants.gd")

@export var variable_name: StringName = &""
@export var scope: Constants.VariableScope = Constants.VariableScope.GAME
@export var variable_type: Constants.VariableType = Constants.VariableType.ANY
@export var default_value: Variant = null
@export var exported_to_script: bool = true

func to_dict() -> Dictionary:
	var data := super.to_dict()
	data.merge({
		"variable_name": String(variable_name),
		"scope": scope,
		"variable_type": variable_type,
		"default_value": default_value,
		"exported_to_script": exported_to_script,
	}, true)
	return data


func from_dict(data: Dictionary) -> void:
	super.from_dict(data)
	variable_name = StringName(str(data.get("variable_name", data.get("id", ""))))
	scope = int(data.get("scope", Constants.VariableScope.GAME))
	variable_type = int(data.get("variable_type", Constants.VariableType.ANY))
	default_value = data.get("default_value", null)
	exported_to_script = bool(data.get("exported_to_script", true))
