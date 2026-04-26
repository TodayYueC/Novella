extends RefCounted

class_name NovellaVM

const Constants := preload("res://addons/novella/core/constants.gd")
const VariableManager := preload("res://addons/novella/script/variable_manager.gd")
const CommandRegistry := preload("res://addons/novella/script/command_registry.gd")
const ExpressionEvaluator := preload("res://addons/novella/script/expression_evaluator.gd")
const TextInterpolator := preload("res://addons/novella/script/text_interpolator.gd")
const LabelManager := preload("res://addons/novella/script/label_manager.gd")

signal dialogue_requested(speaker: String, text: String, line: int)
signal narration_requested(text: String, line: int)
signal choice_requested(choices: Array, selected_index: int, line: int)
signal node_completed(node: Variant)
signal runtime_error(message: String, line: int)
signal finished(transcript: Array)

var variable_manager: Variant = VariableManager.new()
var command_registry: Variant = CommandRegistry.new()
var printer_manager: Variant = null
var choice_strategy: Callable = Callable()

var ast = null
var current_index: int = 0
var call_stack: Array[int] = []
var transcript: Array = []
var label_manager := LabelManager.new()
var evaluator := ExpressionEvaluator.new()
var interpolator := TextInterpolator.new()

func load_script(p_ast) -> void:
	ast = p_ast
	current_index = 0
	call_stack.clear()
	transcript.clear()
	if ast != null:
		label_manager.rebuild(ast.children)


func run(max_steps: int = 10000) -> Array:
	if ast == null:
		_emit_error("No script loaded.", 0)
		return transcript
	transcript.clear()
	var steps := 0
	while current_index < ast.children.size():
		if steps >= max_steps:
			_emit_error("Execution stopped after %s steps to prevent an infinite loop." % max_steps, _current_line())
			break
		steps += 1
		var node = ast.children[current_index]
		var result := _execute_node(node)
		node_completed.emit(node)
		if result.has("finish") and result["finish"]:
			break
		if result.has("jump"):
			var jump_index := label_manager.get_index(result["jump"])
			if jump_index < 0:
				_emit_error("Unknown label '%s'." % result["jump"], node.line)
				break
			current_index = jump_index
			continue
		if result.has("call"):
			if call_stack.size() >= Constants.DEFAULT_MAX_CALL_DEPTH:
				_emit_error("Call stack exceeded %s frames." % Constants.DEFAULT_MAX_CALL_DEPTH, node.line)
				break
			var call_index := label_manager.get_index(result["call"])
			if call_index < 0:
				_emit_error("Unknown label '%s'." % result["call"], node.line)
				break
			call_stack.append(current_index + 1)
			current_index = call_index
			continue
		if result.has("return") and result["return"]:
			if call_stack.is_empty():
				break
			current_index = call_stack.pop_back()
			continue
		current_index += 1
	finished.emit(transcript)
	return transcript


func _execute_node(node) -> Dictionary:
	match node.kind:
		&"label":
			return {"ok": true}
		&"dialogue":
			var text := interpolator.interpolate(node.text, variable_manager)
			var presentation := _present_dialogue(node.speaker, text)
			transcript.append({"type": "dialogue", "speaker": node.speaker, "text": text, "line": node.line, "presentation": presentation.duplicate(true)})
			dialogue_requested.emit(node.speaker, text, node.line)
			return {"ok": true}
		&"narration":
			var text := interpolator.interpolate(node.text, variable_manager)
			var presentation := _present_narration(text)
			transcript.append({"type": "narration", "text": text, "line": node.line, "presentation": presentation.duplicate(true)})
			narration_requested.emit(text, node.line)
			return {"ok": true}
		&"command":
			return _execute_command_node(node)
		&"jump":
			return {"ok": true, "jump": node.target_label}
		&"call":
			return {"ok": true, "call": node.target_label}
		&"return":
			return {"ok": true, "return": true}
		&"menu":
			return _execute_menu(node)
		&"if":
			return _execute_if(node)
		_:
			_emit_error("Unsupported node kind '%s'." % node.kind, node.line)
			return {"ok": false}


func _execute_command_node(node) -> Dictionary:
	if command_registry == null:
		return {"ok": false, "error": "No command registry configured."}
	var result: Dictionary = command_registry.execute(node.command_name, node.raw_arguments, _context_for(node))
	if not bool(result.get("ok", false)):
		_emit_error(str(result.get("error", "Command failed.")), node.line)
	elif result.has("mode") and printer_manager != null and printer_manager.has_method("set_mode"):
		var changed: bool = printer_manager.set_mode(result["mode"])
		if not changed:
			return {"ok": false, "error": "Unknown printer mode '%s'." % result["mode"]}
	return result


func _execute_menu(node) -> Dictionary:
	var available: Array = []
	for i in range(node.choices.size()):
		var choice = node.choices[i]
		if choice.condition.is_empty() or bool(evaluator.evaluate(choice.condition, variable_manager, false)):
			available.append(i)
	if available.is_empty():
		_emit_error("Menu has no available choices.", node.line)
		return {"ok": false}
	var selected_index: int = int(available[0])
	if choice_strategy.is_valid():
		var chosen: Variant = choice_strategy.call(node.choices, available)
		if chosen is int and available.has(chosen):
			selected_index = chosen
	var selected = node.choices[selected_index]
	choice_requested.emit(node.choices, selected_index, node.line)
	transcript.append({"type": "choice", "text": selected.text, "index": selected_index, "line": selected.line})
	return _execute_inline_nodes(selected.actions)


func _execute_if(node) -> Dictionary:
	for branch in node.branches:
		var condition := str(branch["condition"])
		if condition.is_empty() or bool(evaluator.evaluate(condition, variable_manager, false)):
			return _execute_inline_nodes(branch["actions"])
	return {"ok": true}


func _execute_inline_nodes(nodes: Array) -> Dictionary:
	var index := 0
	while index < nodes.size():
		var result := _execute_node(nodes[index])
		node_completed.emit(nodes[index])
		if result.has("jump") or result.has("call") or result.has("return") or result.has("finish"):
			return result
		index += 1
	return {"ok": true}


func _context_for(node) -> Dictionary:
	return {
		"vm": self,
		"variables": variable_manager,
		"printer_manager": printer_manager,
		"node": node,
		"line": node.line,
	}


func _present_dialogue(speaker: String, text: String) -> Dictionary:
	if printer_manager != null and printer_manager.has_method("present_dialogue"):
		return printer_manager.present_dialogue(speaker, text)
	return {}


func _present_narration(text: String) -> Dictionary:
	if printer_manager != null and printer_manager.has_method("present_narration"):
		return printer_manager.present_narration(text)
	return {}


func _emit_error(message: String, line: int) -> void:
	transcript.append({"type": "error", "message": message, "line": line})
	runtime_error.emit(message, line)
	push_warning("Novella runtime error at line %s: %s" % [line, message])


func _current_line() -> int:
	if ast == null or current_index < 0 or current_index >= ast.children.size():
		return 0
	return int(ast.children[current_index].line)
