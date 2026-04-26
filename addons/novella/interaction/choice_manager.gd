extends RefCounted

class_name NovellaChoiceManager

const ExpressionEvaluator := preload("res://addons/novella/script/expression_evaluator.gd")
const TextInterpolator := preload("res://addons/novella/script/text_interpolator.gd")

signal choices_prepared(choices: Array, line: int)
signal choice_selected(choice: Dictionary, index: int, line: int)
signal choice_timeout(default_index: int, line: int)

var variable_manager: Variant = null
var localization_manager: Variant = null
var include_disabled_choices: bool = false
var timeout_seconds: float = 0.0
var timeout_default_index: int = -1
var last_choices: Array = []
var last_selected_index: int = -1

var _evaluator := ExpressionEvaluator.new()
var _interpolator := TextInterpolator.new()

func configure(options: Dictionary = {}) -> void:
	if options.has("include_disabled"):
		include_disabled_choices = _as_bool(options["include_disabled"])
	if options.has("timeout"):
		timeout_seconds = float(options["timeout"])
	if options.has("default"):
		timeout_default_index = int(options["default"])


func build_choices(raw_choices: Array, line: int = 0, p_variable_manager: Variant = null) -> Array:
	var source: Variant = p_variable_manager if p_variable_manager != null else variable_manager
	var result: Array = []
	for index in range(raw_choices.size()):
		var raw_choice = raw_choices[index]
		var condition := _choice_condition(raw_choice)
		var enabled := condition.is_empty() or _as_bool(_evaluator.evaluate(condition, source, false))
		if not enabled and not include_disabled_choices:
			continue
		var raw_text := _choice_text(raw_choice)
		var localized_text := _localize_text(raw_text, source)
		var text := _interpolator.interpolate(localized_text, source) if source != null else localized_text
		result.append({
			"index": index,
			"text": text,
			"raw_text": raw_text,
			"localized_text": localized_text,
			"condition": condition,
			"enabled": enabled,
			"disabled": not enabled,
			"line": _choice_line(raw_choice, line),
		})
	last_choices = result.duplicate(true)
	choices_prepared.emit(last_choices, line)
	return last_choices


func available_indices(choices: Array) -> Array:
	var result: Array = []
	for choice in choices:
		if _as_bool(choice.get("enabled", true)):
			result.append(int(choice.get("index", -1)))
	return result


func select_choice(choices: Array, requested_index: int = -1, line: int = 0) -> Dictionary:
	for choice in choices:
		if int(choice.get("index", -1)) == requested_index and _as_bool(choice.get("enabled", true)):
			last_selected_index = requested_index
			choice_selected.emit(choice, requested_index, line)
			return {"ok": true, "index": requested_index, "choice": choice}
	for choice in choices:
		if _as_bool(choice.get("enabled", true)):
			last_selected_index = int(choice.get("index", -1))
			choice_selected.emit(choice, last_selected_index, line)
			return {"ok": true, "index": last_selected_index, "choice": choice}
	return {"ok": false, "error": "No enabled choices are available."}


func select_timeout_default(choices: Array, line: int = 0) -> Dictionary:
	var preferred := timeout_default_index
	if preferred < 0 and not choices.is_empty():
		preferred = int(choices[0].get("index", -1))
	choice_timeout.emit(preferred, line)
	return select_choice(choices, preferred, line)


func get_state() -> Dictionary:
	return {
		"include_disabled_choices": include_disabled_choices,
		"timeout_seconds": timeout_seconds,
		"timeout_default_index": timeout_default_index,
		"last_choices": last_choices.duplicate(true),
		"last_selected_index": last_selected_index,
	}


func restore_state(state: Dictionary) -> void:
	include_disabled_choices = _as_bool(state.get("include_disabled_choices", include_disabled_choices))
	timeout_seconds = float(state.get("timeout_seconds", timeout_seconds))
	timeout_default_index = int(state.get("timeout_default_index", timeout_default_index))
	last_choices = state.get("last_choices", []).duplicate(true)
	last_selected_index = int(state.get("last_selected_index", last_selected_index))


func _choice_text(choice: Variant) -> String:
	if choice is Dictionary:
		return str(choice.get("text", ""))
	return str(choice.text)


func _choice_condition(choice: Variant) -> String:
	if choice is Dictionary:
		return str(choice.get("condition", ""))
	return str(choice.condition)


func _choice_line(choice: Variant, fallback: int) -> int:
	if choice is Dictionary:
		return int(choice.get("line", fallback))
	return int(choice.line)


func _localize_text(text: String, source: Variant) -> String:
	if localization_manager != null and localization_manager.has_method("localize_text"):
		return localization_manager.localize_text(text, source)
	return text


func _as_bool(value: Variant) -> bool:
	if value is bool:
		return value
	if value == null:
		return false
	var text := str(value).strip_edges().to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"
