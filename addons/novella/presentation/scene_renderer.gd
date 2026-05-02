extends RefCounted

class_name NovellaSceneRenderer

func build_scene(background_state: Dictionary, character_state: Dictionary, camera_state: Dictionary, effect_state: Dictionary = {}, options: Dictionary = {}) -> Dictionary:
	return {
		"ok": true,
		"viewport": options.get("viewport", Vector2(1280, 720)),
		"background": _background_instruction(background_state),
		"characters": _character_instructions(character_state),
		"camera": _camera_instruction(camera_state),
		"effects": _effect_instructions(effect_state),
		"layers": ["background", "characters", "effects", "ui"],
	}


func transition_plan(from_background: Dictionary, to_background: Dictionary, transition: StringName = &"fade", duration: float = 0.5) -> Dictionary:
	return {
		"ok": true,
		"type": String(transition),
		"duration": maxf(0.0, duration),
		"from": _background_instruction(from_background),
		"to": _background_instruction(to_background),
		"steps": [
			{"time": 0.0, "alpha_from": 1.0, "alpha_to": 0.0},
			{"time": maxf(0.0, duration), "alpha_from": 0.0, "alpha_to": 1.0},
		],
	}


func character_animation(character: Dictionary, animation: StringName, duration: float = 0.35, options: Dictionary = {}) -> Dictionary:
	return {
		"ok": true,
		"character_id": str(character.get("character_id", character.get("id", ""))),
		"animation": String(animation),
		"duration": maxf(0.0, duration),
		"from": character.duplicate(true),
		"to": _patched_character(character, options),
		"ease": str(options.get("ease", "ease_out")),
	}


func screen_effect_passes(effects: Array) -> Array:
	var passes: Array = []
	for effect_value in effects:
		if not effect_value is Dictionary:
			continue
		var effect: Dictionary = effect_value
		passes.append({
			"effect": str(effect.get("effect", "")),
			"target": str(effect.get("target", "screen")),
			"shader": str(effect.get("shader", effect.get("effect", ""))),
			"duration": float(effect.get("duration", 0.0)),
			"intensity": float(effect.get("intensity", 1.0)),
			"params": effect.get("params", {}).duplicate(true) if effect.get("params", {}) is Dictionary else {},
		})
	return passes


func _background_instruction(state: Dictionary) -> Dictionary:
	var background: Dictionary = state.get("background", state).duplicate(true)
	return {
		"id": str(background.get("id", "")),
		"path": str(background.get("path", background.get("source_path", ""))),
		"transition": str(background.get("transition", "fade")),
		"time": float(background.get("time", 0.0)),
		"filters": background.get("filters", {}).duplicate(true) if background.get("filters", {}) is Dictionary else {},
	}


func _character_instructions(state: Dictionary) -> Array:
	var source: Dictionary = state.get("characters", state) if state.has("characters") else state
	var result: Array = []
	for character_id in source:
		var character: Dictionary = source[character_id]
		result.append({
			"character_id": str(character.get("character_id", character_id)),
			"position": character.get("position", 0.5),
			"position_name": str(character.get("position_name", "center")),
			"attributes": character.get("attributes", []).duplicate(),
			"layers": character.get("layers", []).duplicate(true),
			"focused": bool(character.get("focused", false)),
			"enter": str(character.get("enter", "fade")),
			"exit": str(character.get("exit", "fade")),
			"scale": float(character.get("scale", 1.0)),
			"flip": bool(character.get("flip", false)),
		})
	result.sort_custom(func(a, b): return float(a.get("position", 0.5)) < float(b.get("position", 0.5)))
	return result


func _camera_instruction(state: Dictionary) -> Dictionary:
	return {
		"pos": state.get("pos", Vector2.ZERO),
		"zoom": state.get("zoom", Vector2.ONE),
		"rot": float(state.get("rot", 0.0)),
		"time": float(state.get("time", 0.0)),
		"ease": str(state.get("ease", "linear")),
		"shake": state.get("shake", {}).duplicate(true) if state.get("shake", {}) is Dictionary else {},
	}


func _effect_instructions(state: Dictionary) -> Array:
	return screen_effect_passes(state.get("active_effects", []))


func _patched_character(character: Dictionary, options: Dictionary) -> Dictionary:
	var patched := character.duplicate(true)
	for key in options:
		patched[key] = options[key]
	return patched
