extends RefCounted

const Constants := preload("res://addons/novella/core/constants.gd")

static func check_engine_version() -> Dictionary:
	var info := Engine.get_version_info()
	var major := int(info.get("major", 0))
	var minor := int(info.get("minor", 0))
	var status := str(info.get("status", ""))
	var supported := major == Constants.MIN_GODOT_MAJOR and minor >= Constants.MIN_GODOT_MINOR
	var primary := major == Constants.PRIMARY_GODOT_MAJOR and minor == Constants.PRIMARY_GODOT_MINOR
	var message := "Novella %s running on Godot %s.%s %s." % [Constants.VERSION, major, minor, status]
	if not supported:
		message = "Novella requires Godot 4.3 or newer in the Godot 4 line. Current runtime: Godot %s.%s %s." % [major, minor, status]
	elif not primary:
		message += " Godot 4.6 is the primary test target; this runtime is treated as compatibility mode."
	return {
		"supported": supported,
		"primary": primary,
		"major": major,
		"minor": minor,
		"status": status,
		"message": message,
	}
