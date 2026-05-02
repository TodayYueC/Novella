extends RefCounted

class_name NovellaEffectManager

signal effect_triggered(effect_name: StringName, target: String, params: Dictionary)

var registered_effects: Dictionary = {}
var registered_shaders: Dictionary = {}
var active_effects: Array = []

func _init() -> void:
	for effect_name in ["shake", "flash", "fade", "blink", "bounce", "heartbeat", "slide", "sway", "spin", "filter", "particle"]:
		register_effect(StringName(effect_name), Callable(self, "_default_effect"))


func register_effect(effect_name: StringName, handler: Callable, replace_existing: bool = true) -> void:
	if registered_effects.has(effect_name) and not replace_existing:
		push_error("Effect '%s' is already registered." % effect_name)
		return
	registered_effects[effect_name] = handler


func register_shader(shader_id: StringName, shader_path: String, defaults: Dictionary = {}) -> Dictionary:
	registered_shaders[shader_id] = {
		"id": String(shader_id),
		"path": shader_path,
		"defaults": defaults.duplicate(true),
	}
	return {"ok": true, "shader": registered_shaders[shader_id].duplicate(true)}


func trigger_effect(effect_name: StringName, target: String = "screen", params: Dictionary = {}) -> Dictionary:
	if not registered_effects.has(effect_name):
		return {"ok": false, "error": "Unknown effect '%s'." % effect_name}
	var payload: Dictionary = registered_effects[effect_name].call(effect_name, target, params)
	if params.has("shader"):
		payload["shader_pass"] = shader_pass_for(StringName(str(params["shader"])), target, params)
	active_effects.append(payload)
	effect_triggered.emit(effect_name, target, params)
	return payload


func shader_pass_for(shader_id: StringName, target: String = "screen", params: Dictionary = {}) -> Dictionary:
	var shader: Dictionary = registered_shaders.get(shader_id, {})
	var merged: Dictionary = shader.get("defaults", {}).duplicate(true) if shader.get("defaults", {}) is Dictionary else {}
	for key in params:
		merged[key] = params[key]
	return {
		"ok": not shader.is_empty(),
		"shader": String(shader_id),
		"path": str(shader.get("path", "")),
		"target": target,
		"params": merged,
	}


func build_effect_timeline(effects_override: Array = []) -> Array:
	var source := active_effects if effects_override.is_empty() else effects_override
	var cursor := 0.0
	var timeline: Array = []
	for effect_value in source:
		if not effect_value is Dictionary:
			continue
		var effect: Dictionary = effect_value.duplicate(true)
		effect["start"] = cursor
		effect["end"] = cursor + float(effect.get("duration", 0.0))
		cursor = effect["end"]
		timeline.append(effect)
	return timeline


func advance_effects(delta: float) -> Array:
	var remaining: Array = []
	for effect_value in active_effects:
		var effect: Dictionary = effect_value
		effect["elapsed"] = float(effect.get("elapsed", 0.0)) + maxf(0.0, delta)
		if float(effect.get("elapsed", 0.0)) < float(effect.get("duration", 0.0)):
			remaining.append(effect)
	active_effects = remaining
	return active_effects.duplicate(true)


func clear_effects(target: String = "") -> void:
	if target.is_empty():
		active_effects.clear()
	else:
		active_effects = active_effects.filter(func(effect): return effect.get("target", "") != target)


func get_state() -> Dictionary:
	return {
		"active_effects": active_effects.duplicate(true),
		"registered_shaders": registered_shaders.duplicate(true),
	}


func restore_state(state: Dictionary) -> void:
	active_effects = state.get("active_effects", []).duplicate(true)
	registered_shaders = state.get("registered_shaders", registered_shaders).duplicate(true)


func _default_effect(effect_name: StringName, target: String, params: Dictionary) -> Dictionary:
	return {
		"ok": true,
		"effect": String(effect_name),
		"target": target,
		"params": params.duplicate(true),
		"duration": float(params.get("duration", params.get("time", 0.35))),
		"intensity": float(params.get("intensity", 1.0)),
	}
