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
signal state_restored(state: Dictionary)
signal finished(transcript: Array)

var variable_manager: Variant = VariableManager.new()
var command_registry: Variant = CommandRegistry.new()
var printer_manager: Variant = null
var choice_manager: Variant = null
var rollback_manager: Variant = null
var backlog_manager: Variant = null
var skip_manager: Variant = null
var auto_manager: Variant = null
var save_manager: Variant = null
var quick_menu_manager: Variant = null
var localization_manager: Variant = null
var gallery_manager: Variant = null
var achievement_manager: Variant = null
var state_providers: Dictionary = {}
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
		if result.has("restored_state") and result["restored_state"]:
			continue
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
		if result.has("break") or result.has("continue"):
			_emit_error("'%s' can only be used inside a while block." % ("break" if result.has("break") else "continue"), node.line)
			break
		current_index += 1
	finished.emit(transcript)
	return transcript


func _execute_node(node) -> Dictionary:
	match node.kind:
		&"label":
			return {"ok": true}
		&"dialogue":
			_push_rollback_snapshot(node)
			var localized_text := _localize_text(node.text)
			var text := interpolator.interpolate(localized_text, variable_manager)
			var presentation := _present_dialogue(node.speaker, text)
			_mark_line_read(node)
			if backlog_manager != null and backlog_manager.has_method("add_dialogue"):
				backlog_manager.add_dialogue(node.speaker, text, node.line, presentation)
			transcript.append({"type": "dialogue", "speaker": node.speaker, "text": text, "line": node.line, "presentation": presentation.duplicate(true)})
			dialogue_requested.emit(node.speaker, text, node.line)
			if not node.inline_commands.is_empty():
				var inline_dialogue_result := _execute_inline_nodes(node.inline_commands)
				if _should_propagate_result(inline_dialogue_result):
					return inline_dialogue_result
			return {"ok": true}
		&"narration":
			_push_rollback_snapshot(node)
			var localized_text := _localize_text(node.text)
			var text := interpolator.interpolate(localized_text, variable_manager)
			var presentation := _present_narration(text)
			_mark_line_read(node)
			if backlog_manager != null and backlog_manager.has_method("add_narration"):
				backlog_manager.add_narration(text, node.line, presentation)
			transcript.append({"type": "narration", "text": text, "line": node.line, "presentation": presentation.duplicate(true)})
			narration_requested.emit(text, node.line)
			if not node.inline_commands.is_empty():
				var inline_narration_result := _execute_inline_nodes(node.inline_commands)
				if _should_propagate_result(inline_narration_result):
					return inline_narration_result
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
		&"while":
			return _execute_while(node)
		&"break":
			return {"ok": true, "break": true}
		&"continue":
			return {"ok": true, "continue": true}
		_:
			_emit_error("Unsupported node kind '%s'." % node.kind, node.line)
			return {"ok": false}


func _execute_command_node(node) -> Dictionary:
	if command_registry == null:
		return {"ok": false, "error": "No command registry configured."}
	var result: Dictionary = command_registry.execute(node.command_name, node.raw_arguments, _context_for(node))
	if not bool(result.get("ok", false)):
		_emit_error(str(result.get("error", "Command failed.")), node.line)
	elif node.command_name == &"mode" and result.has("mode") and printer_manager != null and printer_manager.has_method("set_mode"):
		var changed: bool = printer_manager.set_mode(result["mode"])
		if not changed:
			return {"ok": false, "error": "Unknown printer mode '%s'." % result["mode"]}
	return result


func _execute_menu(node) -> Dictionary:
	_push_rollback_snapshot(node)
	var prepared_choices: Array = []
	var available: Array = []
	if choice_manager != null and choice_manager.has_method("build_choices"):
		prepared_choices = choice_manager.build_choices(node.choices, node.line, variable_manager)
		available = choice_manager.available_indices(prepared_choices)
	else:
		for i in range(node.choices.size()):
			var choice = node.choices[i]
			if choice.condition.is_empty() or bool(evaluator.evaluate(choice.condition, variable_manager, false)):
				available.append(i)
		for index in available:
			var choice = node.choices[index]
			prepared_choices.append({
				"index": index,
				"text": interpolator.interpolate(choice.text, variable_manager),
				"raw_text": choice.text,
				"condition": choice.condition,
				"enabled": true,
				"line": choice.line,
			})
	if available.is_empty():
		_emit_error("Menu has no available choices.", node.line)
		return {"ok": false}
	var selected_index: int = int(available[0])
	if choice_strategy.is_valid():
		var chosen: Variant = choice_strategy.call(node.choices, available)
		if chosen is int and available.has(chosen):
			selected_index = chosen
	if choice_manager != null and choice_manager.has_method("select_choice"):
		var selection: Dictionary = choice_manager.select_choice(prepared_choices, selected_index, node.line)
		if bool(selection.get("ok", false)):
			selected_index = int(selection.get("index", selected_index))
	var selected = node.choices[selected_index]
	var selected_text := interpolator.interpolate(_localize_text(selected.text), variable_manager)
	choice_requested.emit(prepared_choices, selected_index, node.line)
	if backlog_manager != null and backlog_manager.has_method("add_choice"):
		backlog_manager.add_choice(selected_text, selected.line, selected_index)
	transcript.append({"type": "choice", "text": selected_text, "index": selected_index, "line": selected.line})
	return _execute_inline_nodes(selected.actions)


func _execute_if(node) -> Dictionary:
	for branch in node.branches:
		var condition := str(branch["condition"])
		if condition.is_empty() or bool(evaluator.evaluate(condition, variable_manager, false)):
			return _execute_inline_nodes(branch["actions"])
	return {"ok": true}


func _execute_while(node) -> Dictionary:
	if node.condition.is_empty():
		_emit_error("While block is missing a condition.", node.line)
		return {"ok": false}
	var iterations := 0
	while bool(evaluator.evaluate(node.condition, variable_manager, false)):
		if iterations >= Constants.DEFAULT_MAX_LOOP_ITERATIONS:
			_emit_error("While loop exceeded %s iterations." % Constants.DEFAULT_MAX_LOOP_ITERATIONS, node.line)
			return {"ok": false}
		iterations += 1
		var result := _execute_inline_nodes(node.actions)
		if result.has("break"):
			return {"ok": true}
		if result.has("continue"):
			continue
		if _should_propagate_result(result):
			return result
	return {"ok": true}


func _execute_inline_nodes(nodes: Array) -> Dictionary:
	var index := 0
	while index < nodes.size():
		var result := _execute_node(nodes[index])
		node_completed.emit(nodes[index])
		if _should_propagate_result(result):
			return result
		index += 1
	return {"ok": true}


func _should_propagate_result(result: Dictionary) -> bool:
	if not bool(result.get("ok", true)):
		return true
	return result.has("jump") or result.has("call") or result.has("return") or result.has("finish") or result.has("break") or result.has("continue")


func _context_for(node) -> Dictionary:
	return {
		"vm": self,
		"variables": variable_manager,
		"command_registry": command_registry,
		"printer_manager": printer_manager,
		"choice_manager": choice_manager,
		"rollback_manager": rollback_manager,
		"backlog_manager": backlog_manager,
		"skip_manager": skip_manager,
		"auto_manager": auto_manager,
		"save_manager": save_manager,
		"quick_menu_manager": quick_menu_manager,
		"localization_manager": localization_manager,
		"gallery_manager": gallery_manager,
		"achievement_manager": achievement_manager,
		"node": node,
		"line": node.line,
	}


func snapshot_state() -> Dictionary:
	var provider_states: Dictionary = {}
	for provider_name in state_providers:
		var provider = state_providers[provider_name]
		if provider != null and provider.has_method("get_state"):
			provider_states[String(provider_name)] = provider.get_state()
	return {
		"current_index": current_index,
		"call_stack": call_stack.duplicate(true),
		"transcript": transcript.duplicate(true),
		"variables": variable_manager.snapshot() if variable_manager != null and variable_manager.has_method("snapshot") else {},
		"providers": provider_states,
	}


func restore_state(state: Dictionary) -> void:
	current_index = int(state.get("current_index", current_index))
	call_stack = state.get("call_stack", call_stack).duplicate(true)
	transcript = state.get("transcript", transcript).duplicate(true)
	if variable_manager != null and variable_manager.has_method("restore") and state.has("variables"):
		variable_manager.restore(state["variables"])
	var provider_states: Dictionary = state.get("providers", {})
	for provider_name in provider_states:
		var provider = state_providers.get(StringName(str(provider_name)), state_providers.get(str(provider_name)))
		if provider != null and provider.has_method("restore_state"):
			provider.restore_state(provider_states[provider_name])
	state_restored.emit(state.duplicate(true))


func _present_dialogue(speaker: String, text: String) -> Dictionary:
	if printer_manager != null and printer_manager.has_method("present_dialogue"):
		return printer_manager.present_dialogue(speaker, text)
	return {}


func _present_narration(text: String) -> Dictionary:
	if printer_manager != null and printer_manager.has_method("present_narration"):
		return printer_manager.present_narration(text)
	return {}


func _localize_text(text: String) -> String:
	if localization_manager != null and localization_manager.has_method("localize_text"):
		return localization_manager.localize_text(text, variable_manager)
	return text


func _emit_error(message: String, line: int) -> void:
	transcript.append({"type": "error", "message": message, "line": line})
	runtime_error.emit(message, line)
	push_warning("Novella runtime error at line %s: %s" % [line, message])


func _push_rollback_snapshot(node) -> void:
	if rollback_manager == null or not rollback_manager.has_method("push_snapshot"):
		return
	rollback_manager.push_snapshot(snapshot_state(), {"line": node.line, "kind": String(node.kind), "index": current_index})


func _mark_line_read(node) -> void:
	if skip_manager == null or not skip_manager.has_method("mark_read"):
		return
	skip_manager.mark_read("%s:%s" % [node.line, String(node.kind)])


func _current_line() -> int:
	if ast == null or current_index < 0 or current_index >= ast.children.size():
		return 0
	return int(ast.children[current_index].line)
