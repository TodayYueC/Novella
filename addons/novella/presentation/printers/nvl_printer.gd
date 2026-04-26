extends "res://addons/novella/presentation/printers/base_printer.gd"

class_name NovellaNvlPrinter

var page_capacity: int = 12
var page_lines: Array = []

func _init() -> void:
	mode = &"nvl"


func present_line(speaker: String, text: String, options: Dictionary = {}) -> Dictionary:
	if page_lines.size() >= page_capacity:
		page_lines.clear()
	var payload := {
		"mode": String(mode),
		"speaker": speaker,
		"text": text,
		"options": options.duplicate(true),
	}
	payload["layout"] = "fullscreen_text_page"
	payload["page_index"] = page_lines.size()
	page_lines.append(payload.duplicate(true))
	payload["page_lines"] = page_lines.duplicate(true)
	current_payload = payload
	history.append(payload.duplicate(true))
	line_presented.emit(payload)
	return payload


func clear() -> void:
	page_lines.clear()
	super.clear()


func get_state() -> Dictionary:
	var state := super.get_state()
	state["page_capacity"] = page_capacity
	state["page_lines"] = page_lines.duplicate(true)
	return state


func restore_state(state: Dictionary) -> void:
	super.restore_state(state)
	page_capacity = int(state.get("page_capacity", page_capacity))
	page_lines = state.get("page_lines", []).duplicate(true)
