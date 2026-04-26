extends RefCounted

class_name NovellaBackgroundManager

signal background_changed(state: Dictionary)
signal background_removed(state: Dictionary)
signal scene_changed(state: Dictionary)

var backgrounds: Dictionary = {}
var current_background: Dictionary = {}
var environment: Dictionary = {}

func register_background(background_id: StringName, resource: Variant = {}) -> void:
	backgrounds[background_id] = resource


func show_background(background_id: StringName, options: Dictionary = {}) -> Dictionary:
	current_background = {
		"ok": true,
		"id": String(background_id),
		"resource": backgrounds.get(background_id, {}),
		"transition": str(options.get("transition", "fade")),
		"time": float(options.get("time", 0.5)),
		"filters": options.get("filters", {}).duplicate(true) if options.get("filters", {}) is Dictionary else {},
	}
	background_changed.emit(current_background)
	return current_background.duplicate(true)


func remove_background(options: Dictionary = {}) -> Dictionary:
	var previous := current_background.duplicate(true)
	current_background.clear()
	var payload := {
		"ok": true,
		"removed": previous,
		"transition": str(options.get("transition", "fade")),
		"time": float(options.get("time", 0.35)),
	}
	background_removed.emit(payload)
	return payload


func change_scene(background_id: StringName, options: Dictionary = {}) -> Dictionary:
	var bg := show_background(background_id, options)
	var payload := {
		"ok": true,
		"background": bg,
		"clear_characters": bool(options.get("clear_characters", true)),
		"reset_camera": bool(options.get("reset_camera", true)),
	}
	scene_changed.emit(payload)
	return payload


func set_environment(environment_type: StringName, options: Dictionary = {}) -> Dictionary:
	environment = {
		"type": String(environment_type),
		"params": options.duplicate(true),
	}
	return {"ok": true, "environment": environment.duplicate(true)}


func get_state() -> Dictionary:
	return {
		"background": current_background.duplicate(true),
		"environment": environment.duplicate(true),
	}
