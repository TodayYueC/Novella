extends RefCounted

class_name NovellaBasePrinter

signal line_presented(payload: Dictionary)
signal cleared

var mode: StringName = &"base"
var current_payload: Dictionary = {}
var history: Array = []
var printer_visible: bool = true

func present_line(speaker: String, text: String, options: Dictionary = {}) -> Dictionary:
	current_payload = {
		"mode": String(mode),
		"speaker": speaker,
		"text": text,
		"options": options.duplicate(true),
	}
	history.append(current_payload.duplicate(true))
	line_presented.emit(current_payload)
	return current_payload


func clear() -> void:
	current_payload.clear()
	history.clear()
	cleared.emit()


func set_printer_visible(enabled: bool) -> void:
	printer_visible = enabled
