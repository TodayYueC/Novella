extends RefCounted

class_name NovellaResourceWorkbench

const AssetIndex := preload("res://addons/novella/editor/asset_index.gd")
const CharacterResource := preload("res://addons/novella/resources/character_resource.gd")
const PortraitLayerResource := preload("res://addons/novella/resources/portrait_layer_resource.gd")
const BackgroundResource := preload("res://addons/novella/resources/background_resource.gd")
const CharacterManager := preload("res://addons/novella/presentation/characters/character_manager.gd")

var asset_indexer := AssetIndex.new()
var asset_catalog: Dictionary = {}
var characters: Dictionary = {}
var backgrounds: Dictionary = {}

func build_asset_catalog(paths: Array) -> Dictionary:
	asset_catalog = asset_indexer.build(paths)
	return {
		"ok": true,
		"index": asset_catalog.duplicate(true),
		"summary": asset_indexer.summarize(asset_catalog),
		"cards": build_resource_cards(asset_catalog),
	}


func build_resource_cards(index: Dictionary = {}) -> Array:
	var source := asset_catalog if index.is_empty() else index
	var cards: Array = []
	for item in asset_indexer.flatten(source):
		cards.append({
			"id": str(item.get("id", "")),
			"title": _title_from_id(str(item.get("id", ""))),
			"category": str(item.get("category", "")),
			"role": str(item.get("role", "")),
			"path": str(item.get("path", "")),
			"tags": item.get("tags", []).duplicate(),
		})
	return cards


func create_character(character_id: StringName, data: Dictionary = {}) -> Dictionary:
	var resource: Resource = CharacterResource.new()
	resource.id = character_id
	resource.character_id = character_id
	resource.display_name = str(data.get("display_name", _title_from_id(String(character_id))))
	resource.description = str(data.get("description", ""))
	resource.voice_directory = str(data.get("voice_directory", ""))
	resource.text_style = data.get("text_style", {}).duplicate(true)
	resource.side_portraits = data.get("side_portraits", {}).duplicate(true)
	if data.has("color"):
		resource.color = _coerce_color(data["color"], Color.WHITE)
	characters[character_id] = resource
	return _character_data(character_id)


func update_character(character_id: StringName, patch: Dictionary) -> Dictionary:
	if not characters.has(character_id):
		return {"ok": false, "error": "Unknown character '%s'." % String(character_id)}
	var resource: Resource = characters[character_id]
	for key in patch:
		match str(key):
			"display_name":
				resource.display_name = str(patch[key])
			"description":
				resource.description = str(patch[key])
			"voice_directory":
				resource.voice_directory = str(patch[key])
			"text_style":
				resource.text_style = patch[key].duplicate(true) if patch[key] is Dictionary else {}
			"side_portraits":
				resource.side_portraits = patch[key].duplicate(true) if patch[key] is Dictionary else {}
			"color":
				resource.color = _coerce_color(patch[key], resource.color)
			_:
				resource.metadata[str(key)] = patch[key]
	return _character_data(character_id)


func add_portrait_layer(character_id: StringName, group: StringName, attribute: StringName, texture_path: String, order: int = 0, condition: String = "") -> Dictionary:
	if not characters.has(character_id):
		create_character(character_id)
	var resource: Resource = characters[character_id]
	var layer: Resource = PortraitLayerResource.new()
	layer.id = StringName("%s_%s_%s" % [String(character_id), String(group), String(attribute)])
	layer.group = group
	layer.attribute = attribute
	layer.texture_path = texture_path
	layer.order = order
	layer.condition = condition
	resource.portraits.append(layer)
	return {
		"ok": true,
		"character_id": String(character_id),
		"layer": layer.to_dict(),
		"count": resource.portraits.size(),
	}


func configure_side_portrait(character_id: StringName, expression: StringName, texture_path: String) -> Dictionary:
	if not characters.has(character_id):
		create_character(character_id)
	var resource: Resource = characters[character_id]
	resource.side_portraits[expression] = texture_path
	return _character_data(character_id)


func configure_voice(character_id: StringName, voice_directory: String) -> Dictionary:
	if not characters.has(character_id):
		create_character(character_id)
	var resource: Resource = characters[character_id]
	resource.voice_directory = voice_directory
	return _character_data(character_id)


func configure_text_style(character_id: StringName, style_patch: Dictionary) -> Dictionary:
	if not characters.has(character_id):
		create_character(character_id)
	var resource: Resource = characters[character_id]
	for key in style_patch:
		resource.text_style[key] = style_patch[key]
	return _character_data(character_id)


func create_background(background_id: StringName, source_path: String, data: Dictionary = {}) -> Dictionary:
	var resource: Resource = BackgroundResource.new()
	resource.id = background_id
	resource.display_name = str(data.get("display_name", _title_from_id(String(background_id))))
	resource.description = str(data.get("description", ""))
	resource.source_path = source_path
	resource.default_transition = StringName(str(data.get("default_transition", "fade")))
	resource.localized_overrides = data.get("localized_overrides", {}).duplicate(true)
	resource.filters = data.get("filters", {}).duplicate(true)
	backgrounds[background_id] = resource
	return _background_data(background_id)


func auto_character_from_assets(character_id: StringName, paths: Array) -> Dictionary:
	create_character(character_id)
	var lower_id := String(character_id).to_lower()
	var side_count := 0
	var layer_count := 0
	for path_value in paths:
		var path := str(path_value).replace("\\", "/")
		var lower := path.to_lower()
		if not lower.contains(lower_id):
			continue
		var base_id := path.get_file().get_basename()
		if lower.contains("side") or lower.contains("portrait"):
			configure_side_portrait(character_id, StringName(_expression_from_path(path)), path)
			side_count += 1
		else:
			add_portrait_layer(character_id, &"sprite", StringName(_attribute_from_path(path, lower_id)), path, layer_count)
			layer_count += 1
	return {
		"ok": true,
		"character": _character_data(character_id),
		"layers": layer_count,
		"side_portraits": side_count,
	}


func preview_character(character_id: StringName, attributes: Array = [], options: Dictionary = {}) -> Dictionary:
	if not characters.has(character_id):
		return {"ok": false, "error": "Unknown character '%s'." % String(character_id)}
	var manager := CharacterManager.new()
	manager.register_character(character_id, characters[character_id])
	var state := manager.show_character(character_id, attributes, options)
	state["side_portrait"] = _side_portrait_for(character_id, attributes)
	state["resource"] = characters[character_id].to_dict()
	return state


func validate_resources() -> Dictionary:
	var errors: Array = []
	for character_id in characters:
		var data: Dictionary = characters[character_id].to_dict()
		if str(data.get("character_id", "")).is_empty():
			errors.append({"kind": "character", "id": String(character_id), "message": "Character id is empty."})
		for layer in data.get("portraits", []):
			if str(layer.get("texture_path", "")).is_empty():
				errors.append({"kind": "portrait", "id": String(character_id), "message": "Portrait layer has no texture path."})
	for background_id in backgrounds:
		var bg: Dictionary = backgrounds[background_id].to_dict()
		if str(bg.get("source_path", "")).is_empty():
			errors.append({"kind": "background", "id": String(background_id), "message": "Background has no source path."})
	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"characters": characters.size(),
		"backgrounds": backgrounds.size(),
	}


func get_state() -> Dictionary:
	var character_data := {}
	for character_id in characters:
		character_data[String(character_id)] = characters[character_id].to_dict()
	var background_data := {}
	for background_id in backgrounds:
		background_data[String(background_id)] = backgrounds[background_id].to_dict()
	return {
		"asset_catalog": asset_catalog.duplicate(true),
		"characters": character_data,
		"backgrounds": background_data,
	}


func _character_data(character_id: StringName) -> Dictionary:
	var data: Dictionary = characters[character_id].to_dict()
	data["ok"] = true
	return data


func _background_data(background_id: StringName) -> Dictionary:
	var data: Dictionary = backgrounds[background_id].to_dict()
	data["ok"] = true
	return data


func _side_portrait_for(character_id: StringName, attributes: Array) -> String:
	var portraits: Dictionary = characters[character_id].side_portraits
	for index in range(attributes.size() - 1, -1, -1):
		var key := StringName(str(attributes[index]))
		if portraits.has(key):
			return str(portraits[key])
		if portraits.has(String(key)):
			return str(portraits[String(key)])
	if portraits.has(&"default"):
		return str(portraits[&"default"])
	if portraits.has("default"):
		return str(portraits["default"])
	return ""


func _coerce_color(value: Variant, fallback: Color) -> Color:
	if value is Color:
		return value
	var text := str(value).strip_edges()
	if text.is_empty():
		return fallback
	return Color.html(text)


func _title_from_id(value: String) -> String:
	var words := value.replace("_", " ").replace("-", " ").split(" ", false)
	for index in range(words.size()):
		words[index] = str(words[index]).capitalize()
	return " ".join(words)


func _attribute_from_path(path: String, lower_id: String) -> String:
	var base_id := path.get_file().get_basename().to_lower()
	base_id = base_id.replace(lower_id, "").trim_prefix("_").trim_prefix("-")
	return base_id if not base_id.is_empty() else path.get_file().get_basename()


func _expression_from_path(path: String) -> String:
	var base_id := path.get_file().get_basename().to_lower()
	if base_id.contains("happy"):
		return "happy"
	if base_id.contains("sad"):
		return "sad"
	if base_id.contains("angry"):
		return "angry"
	return "default"
