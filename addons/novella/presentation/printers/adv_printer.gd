extends "res://addons/novella/presentation/printers/base_printer.gd"

class_name NovellaAdvPrinter

var max_lines: int = 3
var show_side_portrait: bool = true

func _init() -> void:
	mode = &"adv"


func present_line(speaker: String, text: String, options: Dictionary = {}) -> Dictionary:
	var payload := {
		"mode": String(mode),
		"speaker": speaker,
		"text": text,
		"options": options.duplicate(true),
	}
	payload["layout"] = "bottom_dialogue_box"
	payload["max_lines"] = max_lines
	payload["show_side_portrait"] = show_side_portrait
	current_payload = payload
	history.append(payload.duplicate(true))
	line_presented.emit(payload)
	return payload


func get_state() -> Dictionary:
	var state := super.get_state()
	state["max_lines"] = max_lines
	state["show_side_portrait"] = show_side_portrait
	return state


func restore_state(state: Dictionary) -> void:
	super.restore_state(state)
	max_lines = int(state.get("max_lines", max_lines))
	show_side_portrait = bool(state.get("show_side_portrait", show_side_portrait))
