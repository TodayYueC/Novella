extends RefCounted

class_name NovellaParser

const Ast := preload("res://addons/novella/script/ast_nodes.gd")

var errors: Array[String] = []
var _lines: Array = []
var _index: int = 0

func parse(source: String, file_path: String = ""):
	errors.clear()
	_lines = _collect_lines(source)
	_index = 0
	var script := Ast.ScriptNode.new(file_path)
	script.children = _parse_block(0)
	script.labels = _collect_labels(script.children)
	return script


func _collect_lines(source: String) -> Array:
	var result: Array = []
	var raw_lines := source.replace("\r\n", "\n").replace("\r", "\n").split("\n", false)
	for i in range(raw_lines.size()):
		var raw := raw_lines[i]
		var cleaned := _strip_comment(raw).rstrip(" \t")
		if cleaned.strip_edges().is_empty():
			continue
		result.append({
			"text": cleaned.strip_edges(),
			"indent": _count_indent(cleaned),
			"line": i + 1,
		})
	return result


func _parse_block(min_indent: int) -> Array:
	var nodes: Array = []
	while _index < _lines.size():
		var line: Dictionary = _lines[_index]
		if int(line["indent"]) < min_indent:
			break
		var text := str(line["text"])
		if _is_block_terminator(text):
			break
		var node = _parse_statement()
		if node != null:
			nodes.append(node)
	return nodes


func _parse_statement():
	var line: Dictionary = _lines[_index]
	var text := str(line["text"])
	var line_number := int(line["line"])
	if text == "menu:":
		return _parse_menu(int(line["indent"]), line_number)
	if text.begins_with("if ") and text.ends_with(":"):
		return _parse_if(int(line["indent"]), line_number)
	if text.begins_with("@"):
		_index += 1
		return _parse_command(text, line_number)
	if text.begins_with("label ") and text.ends_with(":"):
		_index += 1
		var label_name := text.substr(6, text.length() - 7).strip_edges()
		return Ast.LabelNode.new(StringName(label_name), line_number)
	if text.begins_with("jump "):
		_index += 1
		return Ast.JumpNode.new(StringName(text.substr(5).strip_edges()), line_number)
	if text.begins_with("call "):
		_index += 1
		return _parse_call(text, line_number)
	if text == "return":
		_index += 1
		return Ast.ReturnNode.new(line_number)
	var colon := text.find(":")
	if colon > 0:
		var speaker := text.substr(0, colon).strip_edges()
		var body := text.substr(colon + 1).strip_edges()
		_index += 1
		return Ast.DialogueNode.new(speaker, body, line_number)
	_index += 1
	return Ast.NarrationNode.new(text, line_number)


func _parse_menu(menu_indent: int, line_number: int):
	_index += 1
	var choices: Array = []
	while _index < _lines.size():
		var line: Dictionary = _lines[_index]
		if int(line["indent"]) <= menu_indent:
			break
		var header := _parse_choice_header(str(line["text"]), int(line["line"]))
		if header.is_empty():
			_error("Expected menu choice at line %s." % line["line"])
			_index += 1
			continue
		_index += 1
		var actions := _parse_block(int(line["indent"]) + 1)
		choices.append(Ast.ChoiceNode.new(header["text"], header["condition"], actions, int(line["line"])))
	return Ast.MenuNode.new(choices, line_number)


func _parse_if(if_indent: int, line_number: int):
	var if_node := Ast.IfNode.new(line_number)
	var first_line: Dictionary = _lines[_index]
	var condition := _strip_trailing_colon(str(first_line["text"]).substr(3).strip_edges())
	_index += 1
	if_node.add_branch(condition, _parse_block(if_indent + 1), int(first_line["line"]))
	while _index < _lines.size():
		var line: Dictionary = _lines[_index]
		if int(line["indent"]) != if_indent:
			break
		var text := str(line["text"])
		if text.begins_with("elif ") and text.ends_with(":"):
			var elif_condition := _strip_trailing_colon(text.substr(5).strip_edges())
			_index += 1
			if_node.add_branch(elif_condition, _parse_block(if_indent + 1), int(line["line"]))
		elif text == "else:":
			_index += 1
			if_node.add_branch("", _parse_block(if_indent + 1), int(line["line"]))
		elif text == "endif":
			_index += 1
			break
		else:
			break
	return if_node


func _parse_command(text: String, line_number: int):
	var without_at := text.substr(1)
	var split_at := without_at.find(" ")
	if split_at == -1:
		return Ast.CommandNode.new(StringName(without_at.strip_edges()), "", line_number)
	return Ast.CommandNode.new(StringName(without_at.substr(0, split_at).strip_edges()), without_at.substr(split_at + 1).strip_edges(), line_number)


func _parse_call(text: String, line_number: int):
	var call_body := text.substr(5).strip_edges()
	var paren := call_body.find("(")
	if paren == -1:
		return Ast.CallNode.new(StringName(call_body), {}, line_number)
	var label_name := call_body.substr(0, paren).strip_edges()
	var args_text := call_body.substr(paren + 1).trim_suffix(")").strip_edges()
	return Ast.CallNode.new(StringName(label_name), _parse_call_arguments(args_text), line_number)


func _parse_call_arguments(args_text: String) -> Dictionary:
	var args: Dictionary = {}
	if args_text.is_empty():
		return args
	for part in args_text.split(",", false):
		var eq := part.find("=")
		if eq == -1:
			continue
		args[part.substr(0, eq).strip_edges()] = part.substr(eq + 1).strip_edges()
	return args


func _parse_choice_header(text: String, line_number: int) -> Dictionary:
	var start := text.find("\"")
	if start == -1:
		return {}
	var end := text.find("\"", start + 1)
	if end == -1:
		_error("Unterminated choice string at line %s." % line_number)
		return {}
	var choice_text := text.substr(start + 1, end - start - 1)
	var suffix := _strip_trailing_colon(text.substr(end + 1).strip_edges())
	var condition := ""
	if suffix.begins_with("if "):
		condition = suffix.substr(3).strip_edges()
	elif not suffix.is_empty():
		_error("Unexpected choice suffix '%s' at line %s." % [suffix, line_number])
	return {"text": choice_text, "condition": condition}


func _collect_labels(nodes: Array) -> Dictionary:
	var labels: Dictionary = {}
	for i in range(nodes.size()):
		var node = nodes[i]
		if node.kind == &"label":
			labels[node.label_name] = i
	return labels


func _strip_comment(line: String) -> String:
	var in_string := false
	var escaped := false
	for i in range(line.length()):
		var ch := line[i]
		if escaped:
			escaped = false
			continue
		if ch == "\\":
			escaped = true
			continue
		if ch == "\"":
			in_string = not in_string
			continue
		if ch == "#" and not in_string:
			return line.substr(0, i)
	return line


func _count_indent(line: String) -> int:
	var count := 0
	for i in range(line.length()):
		var ch := line[i]
		if ch == " ":
			count += 1
		elif ch == "\t":
			count += 4
		else:
			break
	return count


func _strip_trailing_colon(text: String) -> String:
	return text.trim_suffix(":").strip_edges()


func _is_block_terminator(text: String) -> bool:
	return text == "endif" or text == "else:" or (text.begins_with("elif ") and text.ends_with(":")) or text == "endwhile"


func _error(message: String) -> void:
	errors.append(message)
