extends RefCounted

class_name NovellaCharacterManager

const LayeredSprite := preload("res://addons/novella/presentation/characters/layered_sprite.gd")
const SidePortrait := preload("res://addons/novella/presentation/characters/side_portrait.gd")

signal character_registered(character_id: StringName)
signal character_shown(character_id: StringName, state: Dictionary)
signal character_hidden(character_id: StringName)
signal character_moved(character_id: StringName, position: Variant)
signal focus_changed(character_id: StringName)

var character_resources: Dictionary = {}
var visible_characters: Dictionary = {}
var positions: Dictionary = {
	&"far_left": 0.1,
	&"left": 0.25,
	&"center": 0.5,
	&"right": 0.75,
	&"far_right": 0.9,
}
var max_visible_characters: int = 8
var side_portrait := SidePortrait.new()

func register_character(character_id: StringName, resource: Variant = {}) -> void:
	character_resources[character_id] = resource
	if resource != null and resource.get("side_portraits") is Dictionary:
		side_portrait.register_portraits(character_id, resource.get("side_portraits"))
	elif resource != null and resource.has_method("to_dict"):
		var data: Dictionary = resource.to_dict()
		side_portrait.register_portraits(character_id, data.get("side_portraits", {}))
	character_registered.emit(character_id)


func show_character(character_id: StringName, attributes: Array = [], options: Dictionary = {}) -> Dictionary:
	if visible_characters.size() >= max_visible_characters and not visible_characters.has(character_id):
		return {"ok": false, "error": "Maximum visible character count reached."}
	var sprite := LayeredSprite.new()
	var resource := character_resources.get(character_id, {})
	var layers := _extract_layers(resource)
	sprite.configure(character_id, layers, _extract_base_layer(resource))
	sprite.set_attributes(attributes)
	var state := {
		"ok": true,
		"character_id": String(character_id),
		"attributes": attributes.duplicate(),
		"position": _resolve_position(options.get("pos", "center")),
		"position_name": str(options.get("pos", "center")),
		"enter": str(options.get("enter", "fade")),
		"exit": str(options.get("exit", "fade")),
		"time": float(options.get("time", 0.35)),
		"flip": bool(options.get("flip", false)),
		"scale": float(options.get("scale", 1.0)),
		"focused": bool(options.get("focused", false)),
		"sprite": sprite,
		"layers": sprite.get_visible_layers(),
	}
	visible_characters[character_id] = state
	character_shown.emit(character_id, get_character_state(character_id))
	return get_character_state(character_id)


func hide_character(character_id: StringName, options: Dictionary = {}) -> Dictionary:
	if not visible_characters.has(character_id):
		return {"ok": true, "hidden": false, "character_id": String(character_id)}
	var state: Dictionary = visible_characters[character_id]
	state["exit"] = str(options.get("exit", state.get("exit", "fade")))
	state["time"] = float(options.get("time", state.get("time", 0.25)))
	visible_characters.erase(character_id)
	character_hidden.emit(character_id)
	return {"ok": true, "hidden": true, "character_id": String(character_id), "exit": state["exit"], "time": state["time"]}


func move_character(character_id: StringName, position: Variant, options: Dictionary = {}) -> Dictionary:
	if not visible_characters.has(character_id):
		return {"ok": false, "error": "Character '%s' is not visible." % character_id}
	var state: Dictionary = visible_characters[character_id]
	state["position"] = _resolve_position(position)
	state["position_name"] = str(position)
	state["time"] = float(options.get("time", 0.35))
	state["ease"] = str(options.get("ease", "ease_out"))
	character_moved.emit(character_id, state["position"])
	return get_character_state(character_id)


func set_emotion(character_id: StringName, emotion: StringName, options: Dictionary = {}) -> Dictionary:
	if not visible_characters.has(character_id):
		return show_character(character_id, [emotion], options)
	var state: Dictionary = visible_characters[character_id]
	state["attributes"].append(String(emotion))
	var sprite = state["sprite"]
	if sprite != null and sprite.has_method("set_attribute"):
		sprite.set_attribute(&"expression", emotion)
		state["layers"] = sprite.get_visible_layers()
	side_portrait.update_speaker(character_id, emotion)
	return get_character_state(character_id)


func focus_character(character_id: StringName) -> void:
	for id in visible_characters:
		visible_characters[id]["focused"] = id == character_id
	focus_changed.emit(character_id)


func get_character_state(character_id: StringName) -> Dictionary:
	if not visible_characters.has(character_id):
		return {}
	var state: Dictionary = visible_characters[character_id].duplicate(true)
	state.erase("sprite")
	return state


func get_scene_state() -> Dictionary:
	var result: Dictionary = {}
	for character_id in visible_characters:
		result[character_id] = get_character_state(character_id)
	return result


func clear() -> void:
	visible_characters.clear()
	side_portrait.clear()


func _resolve_position(position: Variant) -> Variant:
	if position is float or position is int:
		return float(position)
	var text := str(position)
	if text.is_valid_float():
		return float(text)
	return positions.get(StringName(text), positions[&"center"])


func _extract_layers(resource: Variant) -> Array:
	if resource is Dictionary:
		return resource.get("layers", resource.get("portraits", []))
	if resource != null and resource.has_method("to_dict"):
		return resource.to_dict().get("portraits", [])
	return []


func _extract_base_layer(resource: Variant) -> Dictionary:
	if resource is Dictionary:
		return resource.get("base_layer", {})
	return {}
