extends RefCounted

class_name NovellaBasicCommands

const Constants := preload("res://addons/novella/core/constants.gd")
const ExpressionEvaluator := preload("res://addons/novella/script/expression_evaluator.gd")

var variable_manager: Variant
var evaluator := ExpressionEvaluator.new()

func register_all(registry: Variant, p_variable_manager: Variant) -> void:
	variable_manager = p_variable_manager
	registry.register_command(&"var", Callable(self, "_command_var"))
	registry.register_command(&"set", Callable(self, "_command_set"))
	registry.register_command(&"flag", Callable(self, "_command_flag"))
	registry.register_command(&"wait", Callable(self, "_command_wait"))
	registry.register_command(&"mode", Callable(self, "_command_mode"))
	registry.register_command(&"jump", Callable(self, "_command_jump"))
	registry.register_command(&"call", Callable(self, "_command_call"))
	registry.register_command(&"return", Callable(self, "_command_return"))


func _command_var(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var parsed := _parse_scoped_assignment(raw_arguments)
	if parsed["name"] == &"":
		return {"ok": false, "error": "Invalid @var syntax. Expected '@var name = value'."}
	var value := _evaluate_value(parsed["value"])
	variable_manager.declare_variable(parsed["name"], value, parsed["scope"])
	return {"ok": true, "variable": parsed["name"], "value": value, "scope": parsed["scope"]}


func _command_set(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var statement := raw_arguments.strip_edges()
	var condition := ""
	var if_index := statement.find(" if ")
	if if_index != -1:
		condition = statement.substr(if_index + 4).strip_edges()
		statement = statement.substr(0, if_index).strip_edges()
	if not condition.is_empty() and not bool(evaluator.evaluate(condition, variable_manager, false)):
		return {"ok": true, "skipped": true, "condition": condition}
	var assignment := _parse_assignment(statement)
	if assignment["name"] == &"":
		return {"ok": false, "error": "Invalid @set syntax. Expected '@set name = expression'."}
	var current: Variant = variable_manager.get_variable(assignment["name"], 0)
	var right: Variant = _evaluate_value(assignment["value"])
	var next_value: Variant = right
	match assignment["operator"]:
		"+=":
			next_value = current + right
		"-=":
			next_value = current - right
		"*=":
			next_value = current * right
		"/=":
			next_value = current / right
		"%=":
			next_value = int(current) % int(right)
	variable_manager.set_variable(assignment["name"], next_value)
	return {"ok": true, "variable": assignment["name"], "value": next_value}


func _command_flag(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var parts := raw_arguments.split(" ", false)
	if parts.size() < 2:
		return {"ok": false, "error": "Invalid @flag syntax. Expected '@flag set|clear|toggle|check name'."}
	var action := parts[0]
	var flag_name := StringName(parts[1])
	match action:
		"set":
			variable_manager.flags.set_flag(flag_name, true)
			return {"ok": true, "flag": flag_name, "value": true}
		"clear":
			variable_manager.flags.clear_flag(flag_name)
			return {"ok": true, "flag": flag_name, "value": false}
		"toggle":
			return {"ok": true, "flag": flag_name, "value": variable_manager.flags.toggle_flag(flag_name)}
		"check":
			return {"ok": true, "flag": flag_name, "value": variable_manager.flags.check_flag(flag_name)}
	return {"ok": false, "error": "Unknown flag action '%s'." % action}


func _command_wait(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var seconds := float(_evaluate_value(raw_arguments.strip_edges()))
	return {"ok": true, "wait": seconds}


func _command_mode(raw_arguments: String, _context: Dictionary) -> Dictionary:
	var parts := raw_arguments.split(" ", false)
	if parts.is_empty():
		return {"ok": false, "error": "Invalid @mode syntax. Expected '@mode adv|nvl'."}
	return {"ok": true, "mode": StringName(parts[0]), "raw": raw_arguments}


func _command_jump(raw_arguments: String, _context: Dictionary) -> Dictionary:
	return {"ok": true, "jump": StringName(raw_arguments.strip_edges())}


func _command_call(raw_arguments: String, _context: Dictionary) -> Dictionary:
	return {"ok": true, "call": StringName(raw_arguments.strip_edges())}


func _command_return(_raw_arguments: String, _context: Dictionary) -> Dictionary:
	return {"ok": true, "return": true}


func _parse_scoped_assignment(raw_arguments: String) -> Dictionary:
	var text := raw_arguments.strip_edges()
	var scope := Constants.VariableScope.GAME
	for prefix in ["game ", "global ", "settings "]:
		if text.begins_with(prefix):
			scope = _scope_from_text(prefix.strip_edges())
			text = text.substr(prefix.length()).strip_edges()
			break
	var assignment := _parse_assignment(text)
	assignment["scope"] = scope
	return assignment


func _parse_assignment(statement: String) -> Dictionary:
	for operator in ["+=", "-=", "*=", "/=", "%=", "="]:
		var pos := statement.find(operator)
		if pos != -1:
			return {
				"name": StringName(statement.substr(0, pos).strip_edges()),
				"operator": operator,
				"value": statement.substr(pos + operator.length()).strip_edges(),
			}
	return {"name": &"", "operator": "", "value": ""}


func _scope_from_text(scope_text: String) -> int:
	match scope_text:
		"global":
			return Constants.VariableScope.GLOBAL
		"settings":
			return Constants.VariableScope.SETTINGS
		_:
			return Constants.VariableScope.GAME


func _evaluate_value(value_text: String) -> Variant:
	if value_text.is_empty():
		return null
	var result: Variant = evaluator.evaluate(value_text, variable_manager, null)
	if evaluator.errors.is_empty():
		return result
	if value_text.begins_with("\"") and value_text.ends_with("\""):
		return value_text.substr(1, value_text.length() - 2)
	if value_text == "true" or value_text == "false":
		return value_text == "true"
	if value_text.is_valid_int():
		return int(value_text)
	if value_text.is_valid_float():
		return float(value_text)
	return value_text
