extends RefCounted

class_name NovellaScriptLanguageService

const Parser := preload("res://addons/novella/script/parser.gd")
const Diagnostics := preload("res://addons/novella/editor/script_diagnostics.gd")
const AssetIndex := preload("res://addons/novella/editor/asset_index.gd")

const KEYWORDS := ["label", "jump", "call", "return", "menu", "if", "elif", "else", "endif", "while", "endwhile", "break", "continue"]
const COMMANDS := [
	"var", "set", "flag", "wait", "mode", "if", "random",
	"bg", "bg_remove", "scene", "env",
	"char", "char_remove", "char_move", "char_emotion", "char_effect",
	"play_music", "stop_music", "play_se", "play_voice", "stop_voice", "ambience",
	"camera", "camera_shake", "camera_reset",
	"shake", "flash", "fade", "effect", "nvl_clear",
	"save", "load", "quick_save", "quick_load", "auto_save", "settings", "config",
	"rollback", "prevent_rollback", "allow_rollback", "fix_rollback",
	"skip", "prevent_skip", "allow_skip",
	"auto", "prevent_auto", "allow_auto",
	"backlog_clear", "choice_timeout", "quick_menu", "input",
	"locale", "language", "translation", "tr_var",
	"gallery", "replay", "achievement", "achieve", "meta_check",
]

var parser := Parser.new()
var diagnostics := Diagnostics.new()
var asset_index := AssetIndex.new()

func analyze(source: String, file_path: String = "", known_commands: Array = [], project_index: Dictionary = {}) -> Dictionary:
	var ast = parser.parse(source, file_path)
	var command_list := known_commands if not known_commands.is_empty() else COMMANDS
	var diagnostic_report := diagnostics.analyze(ast, parser.errors, command_list)
	var symbols := collect_symbols(source, file_path)
	return {
		"ok": not bool(diagnostic_report.get("has_errors", false)),
		"file_path": file_path,
		"syntax_tokens": syntax_tokens(source),
		"diagnostics": diagnostic_report,
		"symbols": symbols,
		"completion_preview": complete_at(source, 1, 1, {"commands": command_list, "asset_index": project_index}),
		"references": references_for_symbols(source, symbols),
	}


func syntax_tokens(source: String) -> Array:
	var tokens: Array = []
	var lines := _source_lines(source)
	for line_index in range(lines.size()):
		var line_number := line_index + 1
		var line_text := str(lines[line_index])
		var trimmed := line_text.strip_edges()
		if trimmed.is_empty():
			continue
		var column := line_text.find(trimmed) + 1
		if trimmed.begins_with("#"):
			tokens.append(_token("comment", trimmed, line_number, column))
			continue
		if trimmed.begins_with("@"):
			var command_text := trimmed.substr(1).split(" ", false)[0]
			tokens.append(_token("command", command_text, line_number, column + 1))
			_append_argument_tokens(trimmed, line_number, column, tokens)
			continue
		for keyword in KEYWORDS:
			if trimmed == keyword or trimmed.begins_with("%s " % keyword) or trimmed.begins_with("%s:" % keyword):
				tokens.append(_token("keyword", keyword, line_number, column))
				break
		if trimmed.begins_with("\""):
			var end_quote := trimmed.find("\"", 1)
			if end_quote > 0:
				tokens.append(_token("string", trimmed.substr(1, end_quote - 1), line_number, column + 1))
		var colon := trimmed.find(":")
		if colon > 0 and not trimmed.begins_with("label ") and not trimmed.begins_with("if ") and not trimmed.begins_with("while "):
			tokens.append(_token("speaker", trimmed.substr(0, colon), line_number, column))
		for key in _translation_keys_in(trimmed):
			tokens.append(_token("translation_key", key, line_number, max(1, line_text.find(key) + 1)))
	return tokens


func collect_symbols(source: String, file_path: String = "") -> Dictionary:
	var ast = parser.parse(source, file_path)
	var symbols := {
		"labels": [],
		"variables": [],
		"commands": [],
		"speakers": [],
		"translation_keys": [],
	}
	if ast != null:
		_collect_symbols_from_nodes(ast.children, symbols)
	_apply_source_line_overrides(source, symbols)
	_sort_symbol_lists(symbols)
	return symbols


func complete_at(source: String, line: int, column: int, context: Dictionary = {}) -> Array:
	var lines := _source_lines(source)
	var line_text := _line_at(lines, line)
	var prefix := line_text.substr(0, clampi(column - 1, 0, line_text.length()))
	var symbols := collect_symbols(source, str(context.get("file_path", "")))
	var result: Array = []
	var command_list: Array = context.get("commands", COMMANDS)
	if prefix.strip_edges().begins_with("@"):
		var command_prefix := prefix.strip_edges().substr(1).to_lower()
		for command in command_list:
			var text := String(command).trim_prefix("@")
			if text.to_lower().begins_with(command_prefix):
				result.append(_completion("command", "@%s" % text, "Command"))
		return result
	if _looks_like_flow_target(prefix):
		for label in symbols["labels"]:
			result.append(_completion("label", str(label.get("name", "")), "Label"))
		return result
	if prefix.contains("$"):
		var key_prefix := prefix.substr(prefix.rfind("$") + 1).to_lower()
		for key in symbols["translation_keys"]:
			var key_text := str(key.get("name", ""))
			if key_text.to_lower().begins_with(key_prefix):
				result.append(_completion("translation_key", "$%s" % key_text, "Translation"))
		return result
	var command_name := _command_name_for_line(line_text)
	if not command_name.is_empty() and context.has("asset_index"):
		for item in asset_index.suggest_for_command(context["asset_index"], StringName(command_name)):
			result.append(_completion("asset", str(item.get("id", "")), str(item.get("path", ""))))
	for variable in symbols["variables"]:
		result.append(_completion("variable", str(variable.get("name", "")), "Variable"))
	return result


func definition_at(source: String, line: int, column: int, file_path: String = "") -> Dictionary:
	var word := _word_at(source, line, column)
	if word.is_empty():
		return {}
	var symbols := collect_symbols(source, file_path)
	for label in symbols["labels"]:
		if label.get("name", "") == word:
			return label.duplicate(true)
	for variable in symbols["variables"]:
		if variable.get("name", "") == word:
			return variable.duplicate(true)
	for key in symbols["translation_keys"]:
		if key.get("name", "") == word:
			return key.duplicate(true)
	return {}


func references_for_symbols(source: String, symbols: Dictionary) -> Dictionary:
	var references: Dictionary = {}
	for group_name in ["labels", "variables", "translation_keys"]:
		for symbol in symbols.get(group_name, []):
			var name := str(symbol.get("name", ""))
			if name.is_empty():
				continue
			references[name] = find_references(source, name)
	return references


func find_references(source: String, symbol_name: String) -> Array:
	var result: Array = []
	var lines := _source_lines(source)
	for line_index in range(lines.size()):
		var line_text := str(lines[line_index])
		var start := 0
		while start < line_text.length():
			var index := line_text.find(symbol_name, start)
			if index < 0:
				break
			if _is_symbol_boundary(line_text, index, symbol_name.length()):
				result.append({"line": line_index + 1, "column": index + 1, "name": symbol_name, "text": line_text.strip_edges()})
			start = index + max(symbol_name.length(), 1)
	return result


func _collect_symbols_from_nodes(nodes: Array, symbols: Dictionary) -> void:
	for node in nodes:
		match node.kind:
			&"label":
				_add_symbol(symbols["labels"], String(node.label_name), "label", node.line)
			&"dialogue":
				_add_symbol(symbols["speakers"], node.speaker, "speaker", node.line)
				_collect_translation_text(node.text, node.line, symbols)
			&"narration":
				_collect_translation_text(node.text, node.line, symbols)
			&"command":
				_add_symbol(symbols["commands"], String(node.command_name), "command", node.line)
				_collect_command_symbols(node, symbols)
			&"menu":
				for choice in node.choices:
					_collect_translation_text(choice.text, choice.line, symbols)
					_collect_symbols_from_nodes(choice.actions, symbols)
			&"if":
				for branch in node.branches:
					_collect_variables_from_expression(str(branch.get("condition", "")), int(branch.get("line", node.line)), symbols)
					_collect_symbols_from_nodes(branch.get("actions", []), symbols)
			&"while":
				_collect_variables_from_expression(node.condition, node.line, symbols)
				_collect_symbols_from_nodes(node.actions, symbols)


func _collect_command_symbols(node: Variant, symbols: Dictionary) -> void:
	var command := String(node.command_name)
	var raw := str(node.raw_arguments)
	if command == "var":
		var name := _variable_name_from_assignment(raw)
		if not name.is_empty():
			_add_symbol(symbols["variables"], name, "variable", node.line)
	elif command == "set":
		var name := _variable_name_from_assignment(raw)
		if not name.is_empty():
			_add_symbol(symbols["variables"], name, "variable", node.line)
	elif command == "translation":
		var parts := raw.split(" ", false)
		if parts.size() >= 2:
			_add_symbol(symbols["translation_keys"], parts[1], "translation_key", node.line)
	_collect_variables_from_expression(raw, node.line, symbols)


func _collect_translation_text(text: String, line: int, symbols: Dictionary) -> void:
	for key in _translation_keys_in(text):
		_add_symbol(symbols["translation_keys"], key.trim_prefix("$").trim_prefix("tr:"), "translation_key", line)


func _collect_variables_from_expression(text: String, line: int, symbols: Dictionary) -> void:
	for word in _identifier_words(text):
		if KEYWORDS.has(word) or COMMANDS.has(word) or ["true", "false", "and", "or", "not", "then"].has(word):
			continue
		if word.is_valid_identifier() and not word[0].is_valid_int():
			_add_symbol(symbols["variables"], word, "variable", line)


func _add_symbol(list: Array, name: String, kind: String, line: int) -> void:
	var cleaned := name.strip_edges().trim_prefix("$").trim_prefix("tr:")
	if cleaned.is_empty():
		return
	for item in list:
		if item.get("name", "") == cleaned:
			item["references"] = int(item.get("references", 1)) + 1
			return
	list.append({"name": cleaned, "kind": kind, "line": line, "references": 1})


func _sort_symbol_lists(symbols: Dictionary) -> void:
	for key in symbols:
		symbols[key].sort_custom(func(a, b): return str(a.get("name", "")) < str(b.get("name", "")))


func _append_argument_tokens(trimmed: String, line_number: int, base_column: int, tokens: Array) -> void:
	for part in trimmed.split(" ", false):
		var colon := part.find(":")
		if colon > 0:
			tokens.append(_token("named_argument", part.substr(0, colon), line_number, base_column + trimmed.find(part) + 1))


func _translation_keys_in(text: String) -> Array:
	var keys: Array = []
	for raw_word in text.replace("\"", " ").replace(",", " ").replace(":", " ").split(" ", false):
		var word := str(raw_word).strip_edges()
		if word.begins_with("$"):
			keys.append(word.substr(1))
		elif word.begins_with("tr:"):
			keys.append(word.substr(3))
	return keys


func _identifier_words(text: String) -> Array:
	var words: Array = []
	var current := ""
	for i in range(text.length()):
		var ch := text[i]
		if ch == "_" or ch == "." or (ch >= "0" and ch <= "9") or (ch >= "A" and ch <= "Z") or (ch >= "a" and ch <= "z"):
			current += ch
		elif not current.is_empty():
			words.append(current)
			current = ""
	if not current.is_empty():
		words.append(current)
	return words


func _word_at(source: String, line: int, column: int) -> String:
	var lines := _source_lines(source)
	var line_text := _line_at(lines, line)
	if line_text.is_empty():
		return ""
	var index := clampi(column - 1, 0, max(0, line_text.length() - 1))
	var start := index
	var end := index
	while start > 0 and _is_word_char(line_text[start - 1]):
		start -= 1
	while end < line_text.length() and _is_word_char(line_text[end]):
		end += 1
	return line_text.substr(start, end - start).trim_prefix("$")


func _variable_name_from_assignment(raw: String) -> String:
	var cleaned := raw.strip_edges()
	for operator in ["+=", "-=", "*=", "/=", "="]:
		var split_at := cleaned.find(operator)
		if split_at > 0:
			return cleaned.substr(0, split_at).strip_edges()
	return cleaned.split(" ", false)[0] if not cleaned.is_empty() else ""


func _command_name_for_line(line_text: String) -> String:
	var trimmed := line_text.strip_edges()
	if not trimmed.begins_with("@"):
		return ""
	return trimmed.substr(1).split(" ", false)[0]


func _looks_like_flow_target(prefix: String) -> bool:
	var trimmed := prefix.strip_edges()
	return trimmed == "jump" or trimmed == "call" or trimmed.begins_with("jump ") or trimmed.begins_with("call ")


func _apply_source_line_overrides(source: String, symbols: Dictionary) -> void:
	var lines := _source_lines(source)
	for line_index in range(lines.size()):
		var trimmed := str(lines[line_index]).strip_edges()
		if trimmed.begins_with("label ") and trimmed.ends_with(":"):
			_update_symbol_line(symbols["labels"], trimmed.substr(6, trimmed.length() - 7).strip_edges(), line_index + 1)
		elif trimmed.begins_with("@var "):
			_update_symbol_line(symbols["variables"], _variable_name_from_assignment(trimmed.substr(5)), line_index + 1)
		elif trimmed.begins_with("@translation "):
			var parts := trimmed.substr(13).split(" ", false)
			if parts.size() >= 2:
				_update_symbol_line(symbols["translation_keys"], parts[1], line_index + 1)


func _update_symbol_line(list: Array, name: String, line: int) -> void:
	for item in list:
		if item.get("name", "") == name:
			item["line"] = line
			return


func _completion(kind: String, insert_text: String, detail: String = "") -> Dictionary:
	return {"kind": kind, "insert_text": insert_text, "label": insert_text, "detail": detail}


func _token(kind: String, text: String, line: int, column: int) -> Dictionary:
	return {"kind": kind, "text": text, "line": line, "column": column, "length": text.length()}


func _source_lines(source: String) -> Array:
	return source.replace("\r\n", "\n").replace("\r", "\n").split("\n", true)


func _line_at(lines: Array, line: int) -> String:
	if line <= 0 or line > lines.size():
		return ""
	return str(lines[line - 1])


func _is_word_char(ch: String) -> bool:
	return ch == "_" or ch == "." or ch == "$" or (ch >= "0" and ch <= "9") or (ch >= "A" and ch <= "Z") or (ch >= "a" and ch <= "z")


func _is_symbol_boundary(line_text: String, index: int, length: int) -> bool:
	var before_ok := index == 0 or not _is_word_char(line_text[index - 1])
	var after_index := index + length
	var after_ok := after_index >= line_text.length() or not _is_word_char(line_text[after_index])
	return before_ok and after_ok
