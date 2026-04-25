extends "res://addons/novella/core/interfaces/service_interface.gd"

func parse_script(_source: String, _file_path: String = ""):
	push_error("parse_script must be implemented by a script engine service.")
	return null


func run_script(_script, _context: Dictionary = {}) -> Array:
	push_error("run_script must be implemented by a script engine service.")
	return []
