extends RefCounted

class_name NovellaEffectManager

signal effect_triggered(effect_name: StringName, target: String, params: Dictionary)

var registered_effects: Dictionary = {}
var active_effects: Array = []

func _init() -> void:
	for effect_name in ["shake", "flash", "fade", "blink", "bounce", "heartbeat", "slide", "sway", "spin", "filter", "particle"]:
		register_effect(StringName(effect_name), Callable(self, "_default_effect"))


func register_effect(effect_name: StringName, handler: Callable, replace_existing: bool = true) -> void:
	if registered_effects.has(effect_name) and not replace_existing:
		push_error("Effect '%s' is already registered." % effect_name)
		return
	registered_effects[effect_name] = handler


func trigger_effect(effect_name: StringName, target: String = "screen", params: Dictionary = {}) -> Dictionary:
	if not registered_effects.has(effect_name):
		return {"ok": false, "error": "Unknown effect '%s'." % effect_name}
	var payload: Dictionary = registered_effects[effect_name].call(effect_name, target, params)
	active_effects.append(payload)
	effect_triggered.emit(effect_name, target, params)
	return payload


func clear_effects(target: String = "") -> void:
	if target.is_empty():
		active_effects.clear()
	else:
		active_effects = active_effects.filter(func(effect): return effect.get("target", "") != target)


func get_state() -> Dictionary:
	return {"active_effects": active_effects.duplicate(true)}


func _default_effect(effect_name: StringName, target: String, params: Dictionary) -> Dictionary:
	return {
		"ok": true,
		"effect": String(effect_name),
		"target": target,
		"params": params.duplicate(true),
		"duration": float(params.get("duration", params.get("time", 0.35))),
		"intensity": float(params.get("intensity", 1.0)),
	}
