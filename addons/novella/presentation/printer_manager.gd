extends RefCounted

class_name NovellaPrinterManager

const RichTextParser := preload("res://addons/novella/presentation/rich_text_parser.gd")
const TypewriterEffect := preload("res://addons/novella/presentation/typewriter_effect.gd")
const AdvPrinter := preload("res://addons/novella/presentation/printers/adv_printer.gd")
const NvlPrinter := preload("res://addons/novella/presentation/printers/nvl_printer.gd")

signal mode_changed(previous_mode: StringName, next_mode: StringName)
signal dialogue_presented(payload: Dictionary)
signal narration_presented(payload: Dictionary)

var printers: Dictionary = {}
var current_mode: StringName = &"adv"
var parser := RichTextParser.new()
var typewriter := TypewriterEffect.new()
var default_cps: float = 35.0

func _init() -> void:
	register_printer(&"adv", AdvPrinter.new())
	register_printer(&"nvl", NvlPrinter.new())


func register_printer(mode: StringName, printer: Variant, replace_existing: bool = true) -> void:
	if printers.has(mode) and not replace_existing:
		push_error("Printer mode '%s' is already registered." % mode)
		return
	printers[mode] = printer


func has_printer(mode: StringName) -> bool:
	return printers.has(mode)


func set_mode(mode: StringName, options: Dictionary = {}) -> bool:
	if not printers.has(mode):
		push_error("Unknown Novella printer mode '%s'." % mode)
		return false
	var previous := current_mode
	current_mode = mode
	if previous != current_mode:
		mode_changed.emit(previous, current_mode)
	if bool(options.get("clear", false)):
		clear_current()
	return true


func present_dialogue(speaker: String, text: String, options: Dictionary = {}) -> Dictionary:
	var payload := _present(speaker, text, options)
	payload["kind"] = "dialogue"
	dialogue_presented.emit(payload)
	return payload


func present_narration(text: String, options: Dictionary = {}) -> Dictionary:
	var payload := _present("", text, options)
	payload["kind"] = "narration"
	narration_presented.emit(payload)
	return payload


func clear_current() -> void:
	var printer = printers.get(current_mode)
	if printer != null and printer.has_method("clear"):
		printer.clear()


func get_current_printer() -> Variant:
	return printers.get(current_mode)


func get_state() -> Dictionary:
	var printer_states: Dictionary = {}
	for mode_name in printers:
		var printer = printers[mode_name]
		if printer != null and printer.has_method("get_state"):
			printer_states[String(mode_name)] = printer.get_state()
	return {
		"current_mode": String(current_mode),
		"default_cps": default_cps,
		"printers": printer_states,
	}


func restore_state(state: Dictionary) -> void:
	default_cps = float(state.get("default_cps", default_cps))
	var requested_mode := StringName(str(state.get("current_mode", String(current_mode))))
	if printers.has(requested_mode):
		current_mode = requested_mode
	var printer_states: Dictionary = state.get("printers", {})
	for mode_text in printer_states:
		var mode_name := StringName(str(mode_text))
		var printer = printers.get(mode_name)
		if printer != null and printer.has_method("restore_state"):
			printer.restore_state(printer_states[mode_text])


func _present(speaker: String, text: String, options: Dictionary) -> Dictionary:
	var parsed := parser.parse(text)
	var cps := float(options.get("cps", default_cps))
	typewriter.start(parsed["plain_text"], cps)
	var printer = get_current_printer()
	var payload: Dictionary = printer.present_line(speaker, parsed["bbcode"], options) if printer != null else {}
	payload["plain_text"] = parsed["plain_text"]
	payload["controls"] = parsed["controls"]
	payload["estimated_duration"] = typewriter.estimate_duration(parsed["plain_text"], cps)
	payload["mode"] = String(current_mode)
	return payload
