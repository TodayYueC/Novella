extends RefCounted

class_name NovellaVariableManager

const Constants := preload("res://addons/novella/core/constants.gd")
const FlagSet := preload("res://addons/novella/script/flag_set.gd")

signal variable_changed(variable_name: StringName, value: Variant, scope: int)

var game_state: Dictionary = {}
var global_state: Dictionary = {}
var settings_state: Dictionary = {}
var declarations: Dictionary = {}
var flags: Variant = FlagSet.new()

func declare_variable(variable_name: StringName, default_value: Variant = null, scope: int = Constants.VariableScope.GAME, variable_type: int = Constants.VariableType.ANY) -> void:
	declarations[variable_name] = {
		"scope": scope,
		"type": variable_type,
		"default_value": default_value,
	}
	if not has_variable(variable_name):
		set_variable(variable_name, default_value, scope)


func has_variable(variable_name: StringName) -> bool:
	return _state_for_lookup(variable_name) != null


func set_variable(variable_name: StringName, value: Variant, scope: int = -1) -> void:
	var resolved_scope := _resolve_scope(variable_name, scope)
	var state := _state_for_scope(resolved_scope)
	state[variable_name] = value
	variable_changed.emit(variable_name, value, resolved_scope)


func get_variable(variable_name: StringName, default_value: Variant = null) -> Variant:
	var state: Variant = _state_for_lookup(variable_name)
	if state == null:
		return default_value
	return state.get(variable_name, default_value)


func remove_variable(variable_name: StringName) -> bool:
	var state: Variant = _state_for_lookup(variable_name)
	if state == null:
		return false
	state.erase(variable_name)
	return true


func get_scope(variable_name: StringName) -> int:
	if declarations.has(variable_name):
		return int(declarations[variable_name]["scope"])
	if game_state.has(variable_name):
		return Constants.VariableScope.GAME
	if global_state.has(variable_name):
		return Constants.VariableScope.GLOBAL
	if settings_state.has(variable_name):
		return Constants.VariableScope.SETTINGS
	return Constants.VariableScope.GAME


func snapshot() -> Dictionary:
	return {
		"game": game_state.duplicate(true),
		"global": global_state.duplicate(true),
		"settings": settings_state.duplicate(true),
		"declarations": declarations.duplicate(true),
		"flags": flags.to_array(),
	}


func restore(snapshot_data: Dictionary) -> void:
	game_state = snapshot_data.get("game", {}).duplicate(true)
	global_state = snapshot_data.get("global", {}).duplicate(true)
	settings_state = snapshot_data.get("settings", {}).duplicate(true)
	declarations = snapshot_data.get("declarations", {}).duplicate(true)
	flags.from_array(snapshot_data.get("flags", []))


func to_expression_dictionary() -> Dictionary:
	var result: Dictionary = {}
	for key in settings_state:
		result[key] = settings_state[key]
	for key in global_state:
		result[key] = global_state[key]
	for key in game_state:
		result[key] = game_state[key]
	return result


func _resolve_scope(variable_name: StringName, requested_scope: int) -> int:
	if requested_scope >= 0:
		return requested_scope
	return get_scope(variable_name)


func _state_for_scope(scope: int) -> Dictionary:
	match scope:
		Constants.VariableScope.GLOBAL:
			return global_state
		Constants.VariableScope.SETTINGS:
			return settings_state
		_:
			return game_state


func _state_for_lookup(variable_name: StringName) -> Variant:
	if game_state.has(variable_name):
		return game_state
	if global_state.has(variable_name):
		return global_state
	if settings_state.has(variable_name):
		return settings_state
	return null
