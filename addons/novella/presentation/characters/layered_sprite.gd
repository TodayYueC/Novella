extends RefCounted

class_name NovellaLayeredSprite

const ExpressionEvaluator := preload("res://addons/novella/script/expression_evaluator.gd")

var character_id: StringName = &""
var base_layer: Dictionary = {}
var layers: Array = []
var active_attributes: Dictionary = {}
var variable_source: Variant = null
var evaluator := ExpressionEvaluator.new()

func configure(id: StringName, portrait_layers: Array = [], base: Dictionary = {}) -> void:
	character_id = id
	base_layer = base.duplicate(true)
	layers.clear()
	for layer in portrait_layers:
		add_layer(layer)


func add_layer(layer: Variant) -> void:
	var data := _layer_to_dictionary(layer)
	if not data.has("order"):
		data["order"] = layers.size()
	layers.append(data)


func set_attribute(group: StringName, attribute: StringName) -> void:
	active_attributes[group] = attribute


func set_attributes(attributes: Array) -> void:
	for attribute in attributes:
		var attribute_name := StringName(str(attribute))
		var matched := false
		for layer in layers:
			if StringName(str(layer.get("attribute", ""))) == attribute_name:
				active_attributes[StringName(str(layer.get("group", "default")))] = attribute_name
				matched = true
				break
		if not matched:
			active_attributes[StringName("default")] = attribute_name


func get_visible_layers() -> Array:
	var visible_layers: Array = []
	if not base_layer.is_empty():
		visible_layers.append(base_layer.duplicate(true))
	for layer in layers:
		var group := StringName(str(layer.get("group", "default")))
		var attribute := StringName(str(layer.get("attribute", "")))
		if active_attributes.has(group) and active_attributes[group] != attribute:
			continue
		if not _condition_matches(str(layer.get("condition", ""))):
			continue
		visible_layers.append(layer.duplicate(true))
	visible_layers.sort_custom(func(a, b): return int(a.get("order", 0)) < int(b.get("order", 0)))
	return visible_layers


func get_state() -> Dictionary:
	return {
		"character_id": String(character_id),
		"active_attributes": active_attributes.duplicate(true),
		"visible_layers": get_visible_layers(),
	}


func _layer_to_dictionary(layer: Variant) -> Dictionary:
	if layer is Dictionary:
		return layer.duplicate(true)
	if layer != null and layer.has_method("to_dict"):
		return layer.to_dict()
	return {"attribute": str(layer)}


func _condition_matches(condition: String) -> bool:
	if condition.strip_edges().is_empty():
		return true
	return bool(evaluator.evaluate(condition, variable_source, false))
