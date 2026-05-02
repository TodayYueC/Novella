extends RefCounted

class_name NovellaCameraDirector

signal camera_changed(state: Dictionary)
signal camera_shaken(state: Dictionary)

var state: Dictionary = {
	"pos": Vector2.ZERO,
	"zoom": Vector2.ONE,
	"rot": 0.0,
}
var presets: Dictionary = {
	&"wide": {"zoom": Vector2(0.85, 0.85), "pos": Vector2.ZERO},
	&"medium": {"zoom": Vector2.ONE, "pos": Vector2.ZERO},
	&"close": {"zoom": Vector2(1.35, 1.35), "pos": Vector2.ZERO},
}
var animation_queue: Array = []

func move_camera(options: Dictionary = {}) -> Dictionary:
	if options.has("preset"):
		var preset := presets.get(StringName(str(options["preset"])), {})
		for key in preset:
			state[key] = preset[key]
	if options.has("pos"):
		state["pos"] = _parse_vector2(options["pos"])
	if options.has("zoom"):
		state["zoom"] = _parse_zoom(options["zoom"])
	if options.has("rot"):
		state["rot"] = float(options["rot"])
	state["time"] = float(options.get("time", 0.35))
	state["ease"] = str(options.get("ease", "ease_out"))
	camera_changed.emit(state)
	return get_state()


func animate_to(options: Dictionary = {}) -> Dictionary:
	var target := state.duplicate(true)
	if options.has("pos"):
		target["pos"] = _parse_vector2(options["pos"])
	if options.has("zoom"):
		target["zoom"] = _parse_zoom(options["zoom"])
	if options.has("rot"):
		target["rot"] = float(options["rot"])
	var animation := {
		"from": state.duplicate(true),
		"to": target,
		"duration": float(options.get("time", options.get("duration", 0.35))),
		"elapsed": 0.0,
		"ease": str(options.get("ease", "ease_out")),
	}
	animation_queue.append(animation)
	return {"ok": true, "animation": animation.duplicate(true), "queue_size": animation_queue.size()}


func advance(delta: float) -> Dictionary:
	if animation_queue.is_empty():
		return get_state()
	var animation: Dictionary = animation_queue[0]
	animation["elapsed"] = min(float(animation.get("duration", 0.0)), float(animation.get("elapsed", 0.0)) + maxf(0.0, delta))
	var duration := maxf(0.001, float(animation.get("duration", 0.0)))
	var t := clampf(float(animation["elapsed"]) / duration, 0.0, 1.0)
	var from_state: Dictionary = animation.get("from", {})
	var to_state: Dictionary = animation.get("to", {})
	state["pos"] = _coerce_vector2(from_state.get("pos", Vector2.ZERO), Vector2.ZERO).lerp(_coerce_vector2(to_state.get("pos", Vector2.ZERO), Vector2.ZERO), t)
	state["zoom"] = _coerce_vector2(from_state.get("zoom", Vector2.ONE), Vector2.ONE).lerp(_coerce_vector2(to_state.get("zoom", Vector2.ONE), Vector2.ONE), t)
	state["rot"] = lerpf(float(from_state.get("rot", 0.0)), float(to_state.get("rot", 0.0)), t)
	if t >= 1.0:
		animation_queue.pop_front()
	camera_changed.emit(state)
	return get_state()


func shake(options: Dictionary = {}) -> Dictionary:
	var payload := {
		"ok": true,
		"intensity": float(options.get("intensity", 0.5)),
		"duration": float(options.get("duration", options.get("time", 0.35))),
		"frequency": float(options.get("frequency", 30.0)),
	}
	state["shake"] = payload
	camera_shaken.emit(payload)
	return payload


func reset(options: Dictionary = {}) -> Dictionary:
	state = {
		"pos": Vector2.ZERO,
		"zoom": Vector2.ONE,
		"rot": 0.0,
		"time": float(options.get("time", 0.25)),
	}
	camera_changed.emit(state)
	return get_state()


func get_state() -> Dictionary:
	var result := state.duplicate(true)
	result["ok"] = true
	result["animation_queue"] = animation_queue.duplicate(true)
	return result


func restore_state(next_state: Dictionary) -> void:
	state = next_state.duplicate(true)
	state.erase("ok")
	state["pos"] = _coerce_vector2(state.get("pos", Vector2.ZERO), Vector2.ZERO)
	state["zoom"] = _coerce_vector2(state.get("zoom", Vector2.ONE), Vector2.ONE)
	state["rot"] = float(state.get("rot", 0.0))
	animation_queue = next_state.get("animation_queue", animation_queue).duplicate(true)


func _parse_vector2(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	var text := str(value)
	var parts := text.split(",", false)
	if parts.size() == 2:
		return Vector2(float(parts[0]), float(parts[1]))
	return Vector2(float(text), 0.0)


func _parse_zoom(value: Variant) -> Vector2:
	if value is Vector2:
		return value
	var text := str(value)
	var parts := text.split(",", false)
	if parts.size() == 2:
		return Vector2(float(parts[0]), float(parts[1]))
	var scalar := float(text)
	return Vector2(scalar, scalar)


func _coerce_vector2(value: Variant, fallback: Vector2) -> Vector2:
	if value is Vector2:
		return value
	if value is Dictionary and value.has("x") and value.has("y"):
		return Vector2(float(value["x"]), float(value["y"]))
	var text := str(value)
	if text.is_valid_float():
		return Vector2(float(text), float(text))
	return fallback
