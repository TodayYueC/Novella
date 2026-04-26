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
	return result


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
